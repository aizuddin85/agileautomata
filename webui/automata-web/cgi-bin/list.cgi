#!/usr/bin/python -tt
import os
import sys
import mysql.connector


# Custom library import
sys.path.append('../lib/')
import automatastatic
import automatajs
import automatatable
import confighelper

helper = confighelper.confighelper()
js = automatajs.automatajs()
html = automatastatic.automatahtml()
table = automatatable.automatatable()
loglocation = helper.ConfigSectionMap("global")['data_repo']
dbuser = helper.ConfigSectionMap("database")['dbuser']
dbpass = helper.ConfigSectionMap("database")['dbpass']
dbname = helper.ConfigSectionMap("database")['dbname']
dbhost = helper.ConfigSectionMap("database")['dbhost']
user =  os.environ['REMOTE_USER']

def main():
    cnx = mysql.connector.connect(user=dbuser, password=dbpass,
                                   host=dbhost, database=dbname)
    cur = cnx.cursor()
    query = ("SELECT id, sm9id, sm9info, sm9ag, hostname, loglocation, status, jobtime, timestamp, user, submitby FROM queue ORDER BY id DESC ")
    cur.execute(query,)
    
    print table.tableHead()
    for (id, sm9id, sm9info, sm9ag, hostname, loglocation, status, jobtime, timestamp, user, submitby) in cur:
      print table.tableBody(id, sm9id, sm9info, sm9ag, hostname, loglocation, submitby)
      print table.tableStatus(status)
      print table.tableTime(timestamp)
      print table.tableUser(user)
      print table.tableResubmit(id, sm9id, hostname)
      print table.tableDelete(id, sm9id, hostname)
    print table.tableClose()
    cnx.close()

def head():
    print "Content-type: text/html\n\n"
    print html.header()
    print js.clockjs()
    print html.topnav(os.environ['REMOTE_USER'])

def footer():
    print html.backbtn()
    print html.legendClose()


head()
main()
footer()
