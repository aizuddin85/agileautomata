#!/usr/bin/python -tt

import confighelper
import mysql.connector

helper = confighelper.confighelper()
dbuser = helper.ConfigSectionMap("database")['dbuser']
dbpass = helper.ConfigSectionMap("database")['dbpass']
dbname = helper.ConfigSectionMap("database")['dbname']
dbhost = helper.ConfigSectionMap("database")['dbhost']

class connect:
    def dbcon(self):
        try:
            self.cnx = mysql.connector.connect(user=dbuser, password=dbpass, host=dbhost, database=dbname)
            return self.cnx
        except mysql.connector.Error as err:
            print err
