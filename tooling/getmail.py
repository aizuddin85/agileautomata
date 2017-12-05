#!/usr/bin/python

import tempfile
import ConfigParser
from exchangelib import DELEGATE, IMPERSONATION, Account, Credentials, NTLM, Configuration
from xml.dom import expatbuilder
import re
import os
import sys
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

newmail = re.compile('^new', re.I)
oldmail = re.compile('^old', re.I)

if len(sys.argv[0:]) != 2:
    print 'Usage:\n'
    print '%s old|new' % sys.argv[0]
    sys.exit(1)

mailtype = sys.argv[1]

if oldmail.match(mailtype):
    isread = True
    print('Getting old email that has is_read=True...')
elif newmail.match(mailtype):
    isread = False
    print('Getting new email that has is_read=False...')
else:
    print('Usage:\n')
    print('%s old|new' % sys.argv[0])
    sys.exit(1)

CONF_FILE = '/opt/automata/config/automataprod.conf'
conflist = {}

try:
    Config = ConfigParser.ConfigParser()
    Config.read(CONF_FILE)
except IOError as e:
    print('Unable to open config file {}.'.format(CONF_FILE))
    raise e
options = Config.options('email')
for option in options:
    try:
        conflist[option] = Config.get('email', option)
        if conflist[option] == -1:
            print('Skip: {}'.format(option))
    except AttributeError:
        print('Exception occured on {}'.format(option))
        conflist = None
        raise AttributeError

user = conflist['user']
secret = conflist['secret']
mailaddress = conflist['mailaddress']
exchange = conflist['exchange']

credentials = Credentials(
    username=user,
    password=secret
)

config = Configuration(server=exchange, credentials=credentials, verify_ssl=False)
account = Account(
    primary_smtp_address=mailaddress,
    config=config,
    autodiscover=False,
    access_type=DELEGATE
)

mailcount = len(account.inbox.filter(is_read=isread))
mailno = 1
for item in account.inbox.filter(is_read=isread):
    print('Mail No: %s' % mailno)
    print('Received timestamp: %s' % item.datetime_received)
    print('Receiving from: %s' % item.sender.email_address)
    print(item.body)
    print(160 * '-')
    mailno += 1

print('\n\n')
print('COMPLETE!')
if mailcount == 0 and 'new' in mailtype:
    print('No new mail!')
elif 'old' in mailtype:
    print('Listing old email!')
print('Email Count: %s' % mailcount)
