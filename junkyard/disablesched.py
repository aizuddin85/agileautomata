#!/usr/bin/python
import smtplib
from email.mime.text import MIMEText

try:
    # set response as MIMEText format
    msg = MIMEText('  ')
    # add subject, WebMethod anticipated that the subject must started with UC023.
    msg['Subject'] = 'UC023 suspend scheduler'
    msg['From'] = 'AGL-AUTOS00062-S@SHELL.com'
    msg['To'] = 'fmb.fmb-dtq-customer-incident-response@t-systems.com'
    # use localhost postfix to send the email to linux mail proxy.
    # use localhost postfix to send the email to linux mail proxy.
    s = smtplib.SMTP('localhost')
    # send email now
    s.sendmail('AGL-AUTOS00062-S@SHELL.com', 'fmb.fmb-dtq-customer-incident-response@t-systems.com', msg.as_string())
    s.quit()
except smtplib.SMTPException as err:
    raise err

