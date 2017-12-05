#!/usr/bin/python
import argparse
import smtplib
from email.mime.text import MIMEText

parser = argparse.ArgumentParser()
parser.add_argument("--env", help="Dev|Prod")
parser.add_argument("--check", help="True|False")
args = parser.parse_args()

def chkmsg(**kwargs):
    try:
        s = smtplib.SMTP('postoffice.europe.shell.com')
        msg = MIMEText('  ')
        if 'Dev' in kwargs['environ']:
            msg_from = 'AGL-AUTOS00062-S@SHELL.com'
            msg_to = 'fmb.fmb-dtq-customer-incident-response@t-systems.com'
            msg['Subject'] = 'UC023 check scheduler schedule=readInm'
            msg['From'] = msg_from
            msg['To'] = msg_to
            print('Sending WebMethod scheduler check request to Dev...')
            s.sendmail(msg_from, msg_to, msg.as_string())
            print('Request has been sent, check DL 3LP for response...')
        if 'Prod' in kwargs['environ']:
            msg_from = 'AGL-AUTOS00062-S@SHELL.com'
            msg_to = 'fmb.fmb-prod-customer-incident-response@t-systems.com'
            msg['Subject'] = 'UC023 check scheduler schedule=readInm'
            msg['From'] = msg_from
            msg['To'] = msg_to
            print('Sending WebMethod scheduler check request to Prod...')
            s.sendmail(msg_from, msg_to, msg.as_string())
            print('Request has been sent, check DL 3LP for response...')
    except smtplib.SMTPException as err:
            raise err
    finally:
        s.quit()

if 'True' in args.check:
    chkmsg(environ=args.env)
   
