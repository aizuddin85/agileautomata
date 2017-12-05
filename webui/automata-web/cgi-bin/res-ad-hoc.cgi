#!/usr/bin/python -tt
import os
import sys
import cgi
import mysql.connector
import ConfigParser

#Custom libs import
sys.path.append('../lib/')
import automatastatic
import automatajs
import automatatable
import confighelper

js = automatajs.automatajs()
html = automatastatic.automatahtml()
table = automatatable.automatatable()
helper = confighelper.confighelper()
dbuser = helper.ConfigSectionMap("database")['dbuser']
dbpass = helper.ConfigSectionMap("database")['dbpass']
dbname = helper.ConfigSectionMap("database")['dbname']
dbhost = helper.ConfigSectionMap("database")['dbhost']
user = os.environ['REMOTE_USER']

def main():
    cnx = mysql.connector.connect(user=dbuser, password=dbpass,
                                   host=dbhost, database=dbname)
    cur = cnx.cursor()
    query = ("SELECT taskid, submitdate, loglocation, status, owner FROM adhoc_taskid ORDER BY taskid DESC  ")
    cur.execute(query,)
    print table.tableHeadadhoc()
    for (taskid, submitdate, loglocation, status, owner)in cur:
      print table.tableBodyadhoc(taskid, owner, submitdate, loglocation)
      print table.tableStatus(status)
      print table.tableResubmitadhoc(taskid)
      print table.tableDeleteadhoc(taskid)
    print table.tableClose()
    cnx.close()

def header():
    print "Content-type: text/html\n\n"
    print html.header()
    print js.clockjs()
    print html.topnav(os.environ['REMOTE_USER'])

def footer():
    print html.backbtn()
    print html.legendClose()

header()
main()
footer()
