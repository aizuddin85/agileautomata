#!/usr/bin/python -tt

import os
import sys
import cgi
import mysql.connector
from mysql.connector import errorcode
import time
import logging

#Custom libs import
sys.path.append('../lib/')
import automatadb
import confighelper
helper = confighelper.confighelper()
LOG_FILE = helper.ConfigSectionMap("global")['log_location']
logging.basicConfig(filename=LOG_FILE, level=logging.INFO)
dbhelper = automatadb.connect()



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
    try:
        hostnameidf = form['hostname']
        hostnameid = hostnameidf.value
    except:
        hostnameid = 'None'
    
    cnx = dbhelper.dbcon()
    cur = cnx.cursor()


    delete_id = ("DELETE FROM queue WHERE id=%s" % taskid)
    try:
        cur.execute(delete_id,)
        cnx.commit()
        cnx.close()
        logging.info("%s: automata DELETE: %s deleted %s for %s  " % (time.strftime('%X %x %Z'), os.environ['REMOTE_USER'], sm9id, hostnameid))
        print "<script>"
        print "alert('TaskID:%s deleted!')" % taskid
        print "</script>"
        redirect("list.cgi")
    except mysql.connector.Error as e:
        print str(e.errno) + " " + e.sqlstate + " " + e.msg

print "Content-type: text/html\n\n"
main()

