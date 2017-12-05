#!/usr/bin/python -tt
import logging
import sys
import cgi
import mysql.connector
from mysql.connector import errorcode
import time
import re
import os
import ConfigParser

lines_dash = "-" * 80
lines_hash = "#" * 80

#Custom libs import
sys.path.append('../lib/')
import automatajs
import automatastatic
import automatadb
import confighelper
helper = confighelper.confighelper()
LOG_FILE = helper.ConfigSectionMap("global")['loglocation']
DAT_REPO = helper.ConfigSectionMap("global")['datarepo']

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


print "Content-type: text/html\n\n"
dbhelper = automatadb.connect()
js = automatajs.automatajs()
html = automatastatic.automatahtml()
cnx = dbhelper.dbcon()
logging.basicConfig(filename=LOG_FILE, level=logging.INFO)

loadcheck = 'cpuload'
rootcheck = 'rootfs'
swapcheck = 'swapspace'
checkload_jobid = 1
checkrootfs_jobid = 2
checkswap_jobid = 3

form = cgi.FieldStorage()
scriptf = form.getlist('script')
hostf = form.getlist('host')
if len(scriptf) == 0:
    print "<script>"
    print "alert('Error! No script selected.')"
    print "</script>"
    redirect('ad-hoc.cgi')
elif len(hostf) == 0:
    print "<script>"
    print "alert('Error! No host defined.')"
    print "</script>"
    redirect('ad-hoc.cgi')
user = os.environ['REMOTE_USER']
cur = cnx.cursor()
query_taskid = ("SELECT taskid FROM adhoc_metainfo ORDER BY taskid DESC ")
cur.execute(query_taskid,)
taskid_list = []
for taskid in cur:
    taskid_list.append(taskid[0])
    taskid = taskid_list[0] + 1
if len(taskid_list) == 0:
    taskid = 1
hostlist = []
hostnames = []
for hosts in hostf:
    for k in hosts.split('\r\n'):
         hostlist.append(k)
scripts = []
for script in scriptf:
    scripts.append(script)
hosts = [ e for e in hostlist if e ]
loglocation = DAT_REPO + "/" + str(taskid) + "." + str(time.time())
add_taskno = ("INSERT INTO adhoc_taskid "
       "(taskid,status,owner,loglocation) "
       "VALUES ('%s','%s','%s','%s')" % (taskid,0,user,loglocation))
cur.execute(add_taskno,)
for host in hosts:
    for scriptid in scripts:
        add_metainfo = ("INSERT INTO adhoc_metainfo "
                "(taskid, hostname, script) "
                "VALUES ('%s', '%s', '%s') " % (taskid, host, scriptid))
        cur.execute(add_metainfo,)
cnx.commit()
fh = open(loglocation, 'w')
fh.write("Time Created: " + time.strftime('%c')+ "\n\n") 
fh.write(lines_dash + '\n')
fh.write("Hosts:\n")
for host in hosts:
    fh.write(host + "\n")
fh.write(lines_dash + '\n')
fh.write("Jobs:\n")
for script in scripts:
    fh.write(script + "\n")
fh.close()
redirect('res-ad-hoc.cgi')
