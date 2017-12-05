#!/usr/bin/python -tt

import mysql.connector
from mysql.connector import errorcode

class AUTOMATADBAPI:
    def __init__(self, **kwargs ):
        try:
            self.cnx = mysql.connector.connect(**kwargs)
            
        except mysql.connector.Error as e:
            print "Database error: %s" % e.errno
            print "SQLState: %s" % e.sqlstate
            print "Message: %s" % e.msg


    def selectTask(self, status):
        self.cur = self.cnx.cursor(buffered=True)
        query = ("SELECT id, sm9id, hostname, loglocation, jobtime, timestamp FROM queue WHERE status='%s'" % status)
        self.cur.execute(query,)
        res = self.cur.fetchall()
        return res
