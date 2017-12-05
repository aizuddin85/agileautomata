#!/usr/bin/python -tt
import os
import sys
import cgi
import mysql.connector
from mysql.connector import errorcode
import logging

#Custom libs import
sys.path.append('../lib')
import automatadb
import confighelper
helper = confighelper.confighelper()
dbhelper = automatadb.connect()
LOG_FILE = helper.ConfigSectionMap("global")['loglocation']
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

    idf = form['id']
    taskid = idf.value

    cnx = dbhelper.dbcon()
    cur = cnx.cursor()


    delete_id = ("DELETE FROM adhoc_taskid WHERE taskid=%s" % taskid)
    delete_meta = ("DELETE FROM adhoc_metainfo WHERE taskid=%s" % taskid)
    try:
        cur.execute(delete_id,)
        cur.execute(delete_meta,)
        cnx.commit()
        cnx.close()
        print "<script>"
        print "alert('TaskID:%s deleted!')" % taskid
        print "</script>"
        redirect("res-ad-hoc.cgi")
    except mysql.connector.Error as e:
        print str(e.errno) + " " + e.sqlstate + " " + e.msg

print "Content-type: text/html\n\n"
main()

