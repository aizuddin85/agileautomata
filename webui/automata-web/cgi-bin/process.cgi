#!/usr/bin/python -tt
import logging
import sys
import cgi
import mysql.connector
from mysql.connector import errorcode
import time
import re
import os

#Custom libs import
sys.path.append('../lib/')
import automatajs
import automatastatic
import automatatable
import automatadb
import confighelper
helper = confighelper.confighelper()
dbhelper = automatadb.connect()
js = automatajs.automatajs()
html = automatastatic.automatahtml()
table = automatatable.automatatable()
cnx = dbhelper.dbcon()
LOG_FILE = helper.ConfigSectionMap('global')['log_location']
logging.basicConfig(filename=LOG_FILE, level=logging.INFO)

def redirect(url):
    redirectURL = url
    print 'Content-Type: text/html'
    print 'Location: %s' % redirectURL
    print # HTTP says you have to have a blank line between headers and content
    print '<html>'
    print '  <head>'
    print '    <meta http-equiv="refresh" content="0;url=%s" />' % redirectURL
    print '    <title>You are going to be redirected</title>'
    print '  </head>'
    print '  <body>'
    print '    Redirecting... <a href="%s">Click here if you are not redirected</a>' % redirectURL
    print '  </body>'
    print '</html>'

def main():
    form = cgi.FieldStorage()
    hostnamef = form['hostname']
    hostname = hostnamef.value
    incidentidf = form['sm9id']
    incidentid = incidentidf.value
    if re.match(r"^IM\d{10}$", incidentid):
        pass
    else:
        print "<script>"
        print "alert('Invalid SM9 ticket no: %s')" % incidentid
        print "</script>"
        redirect("http://automata.europe.example.com/automata")
        sys.exit(1)
    incidenttitf = form['sm9info']
    incidenttit = incidenttitf.value
    usernameidf = form['userid']
    userid = usernameidf.value
    sm9agidf = form['sm9ag']
    sm9agid = sm9agidf.value
    cur = cnx.cursor()
    add_job = ("INSERT INTO queue "
                 "(sm9id, sm9info, sm9ag, hostname, loglocation, status, jobtime, user, middlewarestat, submitby)"
                 " VALUES ('%s', '%s', '%s', '%s', '%s', '%s', '%s','%s', '%s', '%s')" %  \
                 (incidentid, incidenttit, sm9agid, hostname, hostname + "." + str(time.time()), "0", "READY", userid, "0", userid))
    try:
        cur.execute(add_job,)
        cnx.commit()
        cnx.close()
        logging.info("%s: automata PROCESSOR: %s submitted %s for %s" % (time.strftime('%X %x %Z'), os.environ['REMOTE_USER'], incidentid, hostname))
        print "<script>"
        print "alert('%s submitted')" % incidentid
        print "</script>"
        print "%s submitted, redirecting..." % incidentid
        redirect("list.cgi")
    except mysql.connector.Error as e:
        print str(e.errno) + " " + e.sqlstate + " " + e.msg

print "Content-type: text/html\n\n"
main()

