#!/usr/bin/python
import argparse
import smtplib
from email.mime.text import MIMEText

parser = argparse.ArgumentParser()
parser.add_argument("--enable", help="True|False")
parser.add_argument("--env", help="Dev|Prod")
args = parser.parse_args()


def ctrlmsg(**kwargs):
    try:
        s = smtplib.SMTP('postoffice.europe.shell.com')
        # set response as MIMEText format
        msg = MIMEText('  ')
        # add subject, WebMethod anticipated that the subject must started with UC023.
        if not kwargs['enable']:
            msg_from = 'AGL-AUTOS00062-S@SHELL.com'
            msg['Subject'] = 'UC023 suspend scheduler schedule=readInm'
            msg['From'] = msg_from
            if 'Dev' in kwargs['environ']:
                print('Disabling Dev environment...')
                msg_to = 'fmb.fmb-dtq-customer-incident-response@t-systems.com'
                # msg_to = 'muhammad.zali@t-systems.com'
                msg['To'] = msg_to
            if 'Prod' in kwargs['environ']:
                print('Disabling Prod environment...')
                msg_to = 'fmb.fmb-prod-customer-incident-response@t-systems.com'
                # msg_to = 'muhammad.zali@t-systems.com'
                msg['To'] = msg_to
            s.sendmail(msg_from, msg_to, msg.as_string())
            print('Control message sent to WebMethod, see DL 3LP email for WebMethod response..')

        elif kwargs['enable']:
            msg_from = 'AGL-AUTOS00062-S@SHELL.com'
            msg['Subject'] = 'UC023 enable scheduler schedule=readInm'
            msg['From'] = msg_from
            if 'Dev' in kwargs['environ']:
                print('Enabling Dev environment...')
                msg_to = 'fmb.fmb-dtq-customer-incident-response@t-systems.com'
                # msg_to = 'muhammad.zali@t-systems.com'
                msg['To'] = msg_to
            if 'Prod' in kwargs['environ']:
                print('Enabling Prod environment...')
                msg_to = 'fmb.fmb-prod-customer-incident-response@t-systems.com'
                # msg_to = 'muhammad.zali@t-systems.com'
                msg['To'] = msg_to
            s.sendmail(msg_from, msg_to, msg.as_string())
            print('Control message sent to WebMethod, see DL 3LP email for WebMethod response..')
    except smtplib.SMTPException as err:
        raise err

    finally:
        s.quit()


try:
    if 'True' in args.enable:
        switchbool = True
    else:
        switchbool = False
    if 'Dev' in args.env:
        ctrlmsg(environ=args.env, enable=switchbool)
    if 'Prod' in args.env:
        ctrlmsg(environ=args.env, enable=switchbool)
except ValueError as err:
    print('Execute help to get help!')
    raise err
