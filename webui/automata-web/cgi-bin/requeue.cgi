#!/usr/bin/python -tt
import os
import sys
import cgi
import mysql.connector
from mysql.connector import errorcode
import time
import logging

#Custom libs import
sys.path.append('../lib')
import automatastatic
import automatadb
import confighelper
helper = confighelper.confighelper()
dbhelper =  automatadb.connect()


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

    idf = form['id']
    taskid = idf.value

    sm9idf = form['sm9id']
    sm9id = sm9idf.value

    hostnameidf = form['hostname']
    hostnameid = hostnameidf.value

    cnx = dbhelper.dbcon()
    cur = cnx.cursor()

    requeue_id = ("UPDATE queue SET status='0',user='%s'  WHERE id=%s" % (os.environ['REMOTE_USER'], taskid))
    try:
        cur.execute(requeue_id,)
        cnx.commit()
        cnx.close()
        logging.info("%s: automata REQUEUE: %s requeue %s for %s  " % (time.strftime('%X %x %Z'), os.environ['REMOTE_USER'], sm9id, hostnameid))
        print "<script>"
        print "alert('TaskID:%s resubmitted!')" % taskid
        print "</script>"
        redirect("list.cgi")
    except mysql.connector.Error as e:
        print str(e.errno) + " " + e.sqlstate + " " + e.msg

print "Content-type: text/html\n\n"
main()


