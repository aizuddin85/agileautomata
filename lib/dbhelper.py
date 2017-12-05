#!/usr/bin/python
# Author: Muhammad Aizuddin Bin Zali <muhammad.zali@t-systems.com>
# Date: 12th September 2017
# Automata helper to interact with underlying database.
import confighelper
import mysql.connector
import time
import logging

# get the configuration items.
confhelper = confighelper.ConfigHelper()
dbconf = confhelper.config_section_map("database")
log_file = confhelper.config_section_map('global')['log_location']
debug_flag = confhelper.config_section_map('global')['debug']
# set the logging mechanism
logging.basicConfig(filename=log_file, level=logging.DEBUG, format='%(asctime)s %(levelname)s %(message)s')

dbuser = dbconf["dbuser"]
dbpass = dbconf["dbpass"]
dbname = dbconf["dbname"]
dbport = dbconf["dbport"]
dbhost = dbconf["dbhost"]

# This db run code determined the status icon on the HTML page and engine.
run_dbcode = '1'
pass_dbcode = '2'
fail_dbcode = '3'
err_dbcode = '4'
unkw_dbcode = '5'


# Implementing standard class of calling MariaDB SQL statement of INSERT, DELETE, UPDATE and COMMIT.
class DbApi:
    def __init__(self):
        # instantiate list_newjob list.
        self.list_newjob = []
        # create and connect to the mysql database.
        try:
            cnx = mysql.connector.connect(user=dbuser, password=dbpass,
                                          host=dbhost, database=dbname,
                                          port=dbport)
        except mysql.connector.Error as err:
            logging.debug(err)
            raise err
        # make the connection isolated to each caller.
        self.connection = cnx

    # add new job SQL routine.
    def add_new_job(self, sm9id, sm9info, sm9ag, smhost):
        try:
            logpath = smhost + '.' + str(int(time.time()))
            cur = self.connection.cursor(buffered=True)
            logging.debug(cur)
            stmt = "INSERT INTO queue (sm9id, sm9info, sm9ag, hostname, " \
                   "loglocation, status, jobtime, user, submitby ) " \
                   "VALUES ('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s') " % (
                       sm9id, sm9info, sm9ag, smhost, logpath, "0", "READY", "SYSTEM", "SYSTEM")
            logging.debug(stmt)
            cur.execute(stmt, )
            self.connection.commit()
            return True
        except mysql.connector.Error as err:
            logging.debug(err)
            return err

    # get now job SQL routine.
    def get_new_jobid(self):
        cur = self.connection.cursor(buffered=True)
        stmt = "SELECT id,status from queue WHERE status = 0"
        logging.debug(stmt)
        cur.execute(stmt, )
        if cur.rowcount > 0:
            res = cur.fetchall()
            for (jobid, status) in res:
                self.list_newjob.append(jobid)
            return self.list_newjob
        else:
            return None

    # get item detail SQL routine.
    def get_jobid_details(self, jobid=None):
        cur = self.connection.cursor(buffered=True)
        stmt = ("SELECT sm9info, sm9id, hostname, loglocation, sm9ag, status FROM queue WHERE id ={}".format(jobid))
        logging.debug(stmt)
        cur.execute(stmt, )
        if cur.rowcount > 0:
            res = cur.fetchall()
            res_dict = {}
            for (sm9info, sm9id, hostname, loglocation, sm9ag, status) in res:
                res_dict['sm9info'] = sm9info
                res_dict['sm9id'] = sm9id
                res_dict['hostname'] = hostname
                res_dict['loglocation'] = loglocation
                res_dict['sm9ag'] = sm9ag
                res_dict['status'] = status
            return res_dict
        else:
            return None

    # update run SQL routine.
    def update_run(self, jobid=None):
        try:
            cur = self.connection.cursor(buffered=True)
            now = str(time.strftime('%Y-%m-%d %H:%M:%S'))
            stmt = ("UPDATE queue SET status='{}', jobtime='{}' WHERE sm9id='{}'".format(run_dbcode, now, jobid))
            logging.debug(stmt)
            cur.execute(stmt, )
            self.connection.commit()
            return True
        except mysql.connector.Error as err:
            logging.debug(err)
            return err

    # update fail run SQL routine.
    def update_fail(self, jobid=None):
        try:
            cur = self.connection.cursor(buffered=True)
            stmt = ("UPDATE queue SET status='{}' WHERE sm9id='{}'".format(fail_dbcode, jobid))
            logging.debug(stmt)
            cur.execute(stmt, )
            self.connection.commit()
            return True
        except mysql.connector.Error as err:
            logging.debug(err)
            return err

    # update job OK SQL routine.
    def update_pass(self, jobid=None):
        try:
            cur = self.connection.cursor(buffered=True)
            stmt = ("UPDATE queue SET status='{}' WHERE sm9id='{}'".format(pass_dbcode, jobid))
            logging.debug(stmt)
            cur.execute(stmt, )
            self.connection.commit()
            return True
        except mysql.connector.Error as err:
            logging.debug(err)
            return err
