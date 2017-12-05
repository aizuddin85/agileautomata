#!/usr/bin/python
# Author: Muhammad Aizuddin Bin Zali <muhammad.zali@t-systems.com>
# Date: 12th September 2017
# Library to read email inbox, check the sender, parse the XML body, update the database.
import re
import os
import tempfile
import ConfigParser
import dbhelper
import smtplib
import logging
from email.mime.text import MIMEText
from xml.dom import expatbuilder
from xml.parsers.expat import ExpatError
from exchangelib import DELEGATE, Account, Credentials, Configuration
import confighelper

# read config file and sets approriate variable to it.
confhelper = confighelper.ConfigHelper()
log_file = confhelper.config_section_map('global')['log_location']
debug_flag = confhelper.config_section_map('global')['debug']
DEBUG = debug_flag

# set logging mechanism
logging.basicConfig(filename=log_file, level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')
logging.getLogger('exchangelib').setLevel(logging.WARN)

dbapi = dbhelper.DbApi()

confhelper = confighelper.ConfigHelper()
emailconf = confhelper.config_section_map('email')
user = emailconf['user']
secret = emailconf['secret']
mailaddress = emailconf['mailaddress']
exchange = emailconf['exchange']
emailrelay = emailconf['emailrelay']
recv_from = emailconf['receive_from']
send_to = emailconf['send_to']
admin_to = emailconf['admin_email']

xmlheader = re.compile('^<\?xml version*?', re.I)
xmlmessg = re.compile(r'<message>Success</message>', re.I)
xmlreturn = re.compile(r'<returnCode>0</returnCode>', re.I)
recvfrom = re.compile(recv_from, re.I)
admin_list = []
for i in admin_to.split(','):
    admin_list.append(i)

# instantiate exchangelib credentials class that will be used to by account class connect to Exchange.
credentials = Credentials(
    username=user,
    password=secret
)

# instantiate configuration class that will be used to by account class connect to Exchange.
config = Configuration(server=exchange, credentials=credentials, verify_ssl=False)

# instantiate account class for connection to Exchange.
account = Account(
    primary_smtp_address=mailaddress,
    config=config,
    autodiscover=False,
    access_type=DELEGATE
)


# sending alert if automata encountered error!
def sendalert(alert):
    try:
        # set response as MIMEText format
        msg = MIMEText(alert)
        # add subject, WebMethod anticipated that the subject must started with UC023.
        msg['Subject'] = 'UC023: Error encountered from automata - {}!'.format(__file__)
        msg['From'] = mailaddress
        msg['To'] = admin_to
        # use localhost postfix to send the email to linux mail proxy.
        s = smtplib.SMTP(emailrelay)
        logging.debug(
            'Sending alert to %s interface via %s email server' % (str(admin_list), emailrelay))
        # send email now
        s.sendmail(mailaddress, admin_list, msg.as_string())
        s.quit()
    except smtplib.SMTPException as err:
        logging.debug(str(err))
        pass


# Read inbox, validate XML body, parse the XML body and then insert into DB.
def readinbox():
    if DEBUG:
        logging.debug('Debugging is TRUE!')
    logging.debug('Starting to read mailbox interface for incoming message...')
    # read the mailbox only for unread email.
    for item in account.inbox.filter(is_read=False):
        logging.debug(80 * '#')
        logging.debug('Receiving from: %s' % item.sender.email_address)
        # now check who is the sender, unknown sender will be rejected.
        if recvfrom.match(item.sender.email_address):
            try:
                # read the mailbody
                mybody = item.body.encode('utf-8').strip()
            except UnicodeDecodeError as err:
                logging.debug(err)
                logging.debug('Unicode error...')
                # if mailbody is garbled and in unknown format, delete the email. consider rogue email.
                sendalert(str(err) + 'Unknown or format error of the mailbody!')
                item.is_read = True
                item.save()
                pass
            fd, path = tempfile.mkstemp()
            if mybody:
                # now the body is validated, write into a file.
                with os.fdopen(fd, 'w') as tmp:
                    # xml.dom requires xml to be perfectly formatted. Hence need the root entry point.
                    tmp.write('<root>\n')
                    for line in mybody.split('\n'):
                        if not xmlheader.match(line) and not xmlmessg.match(line) and not xmlreturn.match(line):
                            if DEBUG:
                                logging.debug(line)
                            tmp.write(line)
                    # close the root entry point of the XML body.
                    tmp.write('</root>\n')
                try:
                    # now parse the XML file.
                    xmldoc = expatbuilder.parse(path, False)
                except ExpatError as err:
                    logging.debug(str(err))
                    errmsg = 'Marking email as read with no further action due to XML parsing error...'
                    logging.debug(errmsg)
                    # if parsing error, send alert.
                    sendalert(str(err) + errmsg)
                    item.is_read = True
                    item.save()
                    pass

                try:
                    name_ag = 'None'
                    name_info = 'None'
                    name_host = 'None'
                    # now get all the element in the XML for processing info.
                    node_id = xmldoc.getElementsByTagName("ns1:IncidentID")
                    for i in node_id:
                        name_id = i.firstChild.nodeValue
                    node_ag = xmldoc.getElementsByTagName("ns1:AssignmentGroup")
                    for j in node_ag:
                        name_ag = j.firstChild.nodeValue
                    node_info = xmldoc.getElementsByTagName("ns1:Title")
                    for k in node_info:
                        name_info = k.firstChild.nodeValue
                    node_host = xmldoc.getElementsByTagName("ns1:CIListName")
                    for l in node_host:
                        name_host = l.firstChild.nodeValue
                    if DEBUG:
                        logging.debug(name_ag)
                        logging.debug(name_id)
                        logging.debug(node_info)
                        logging.debug(name_host)
                    logging.debug('Adding new job %s' % name_id)
                except AttributeError as err:
                    logging.debug('Error to read child value of the XML: %s' % str(err))
                    pass
                try:
                    logging.debug('Adding new job : %s ' % name_id)
                    # based on the XML element insert item into database.
                    dbapi.add_new_job(name_id, name_info, name_ag, name_host.lower().replace(" ", ""))
                except RuntimeError as err:
                    logging.debug('Unable to add new job : %s ' % name_id)
                    logging.debug(str(err))
                    sendalert(str(err) + 'Unable to add new job, check engine.log!')
                    item.is_read = True
                    item.save()
            # marked the processed email as read.
            item.is_read = True
            item.save()
            os.remove(path)
        else:
            # dont to anything if unknown sender. Shared mailbox with DEV system.
            logging.debug('Unknown sender: %s, ignoring...' % item.sender.email_address)


# return constructed response body for sending back to email interface.
def response_constructor(sm9id, msg, aginfo, result=False):
    # check for result, and set next action based on the result
    if result:
        logging.debug('Setting up the next action as ticket closure for %s' % sm9id)
        next_action = 'Ticket_Closure'
    else:
        logging.debug('Setting up the next action as L2 escalation for %s' % sm9id)
        next_action = 'L2_escalation'
    # construct the response and return to the caller.
    msg = "<IncidentID>{}</IncidentID>" \
          "<WorkLog>{}</WorkLog>" \
          "<AssignmentGroup>{}</AssignmentGroup>" \
          "<Action>{}</Action>".format(sm9id, msg, aginfo, next_action)
    return msg


# Sending back the response to the email interface.
def sendresult(response, sm9id):
    try:
        # set response as MIMEText format
        msg = MIMEText(response)
        # add subject, WebMethod anticipated that the subject must started with UC023.
        msg['Subject'] = 'UC023: {}'.format(sm9id)
        msg['From'] = mailaddress
        msg['To'] = send_to
        # use localhost postfix to send the email to linux mail proxy.
        # use localhost postfix to send the email to linux mail proxy.
        s = smtplib.SMTP(emailrelay)
        logging.debug('Sending result to %s interface via %s email server' % (send_to, emailrelay))
        # send email now
        s.sendmail(mailaddress, send_to, msg.as_string())
        s.quit()
    except smtplib.SMTPException as err:
        logging.debug(err)
        sendalert(str(err) + 'Unable to send email out!')
        pass
