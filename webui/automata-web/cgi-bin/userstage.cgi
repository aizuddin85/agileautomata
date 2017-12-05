#!/usr/bin/python -tt


import sys
import mysql.connector
import cgi
import smtplib
import ConfigParser
from hashlib import md5
sys.path.append('../lib')
import automatastatic
import confighelper
print 'Content-Type: text/html\n'

helper = confighelper.confighelper()
html = automatastatic.automatahtml()
form = cgi.FieldStorage()

dbuser = helper.ConfigSectionMap("database")['dbuser']
dbpass = helper.ConfigSectionMap("database")['dbpassword']
dbname = helper.ConfigSectionMap("database")['dbname']
dbhost = helper.ConfigSectionMap("database")['dbhost']

usernamef = form['username']
usernameid = usernamef.value

passwordf = form['password']
passwordid = passwordf.value

emailidf = form['email']
emailid = emailidf.value

ht5 = lambda x: md5(':'.join(x)).hexdigest()
htpwd = ':'.join((usernameid, 'RestrictedZone',
                ht5((usernameid, 'RestrictedZone', passwordid))))
                
fd = open('.userstaging', 'a')
fd.write(htpwd + " "  + emailid + "\n")
fd.close

cnx =  mysql.connector.connect(user=dbuser, password=dbpass,
                                   host=dbhost, database=dbname)
cur = cnx.cursor()
insert = ("INSERT INTO auth "
         "(username, email)"
         " VALUES ('%s', '%s')" % (usernameid, emailid))

cur.execute(insert,)
cnx.commit()

print '<script>'
print 'alert("%s request submitted, pending approval from admin")' % usernameid
print '</script>'



sender = 'sga-agile-automata@example.com'
receivers = ['muhammad.zali@example.com']
message = """
From: SGA Agile Automata <sga-agile-automata@example.com>
To: Zali, Muhammad Aizuddin <muhammad.zali@example.com>
Subject: New automata user request

%s submitted request
mailto:%s
""" % (usernameid,emailid)


try:
    smtpObj = smtplib.SMTP('localhost')
    smtpObj.sendmail(sender, receivers, message)
    print("Succesfully, email sent to the administrator!")
except SMTPException:
    print("Error: Mailing system failing...")

