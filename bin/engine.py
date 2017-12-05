#!/usr/bin/python
"""
Author: Muhammad Aizuddin Bin Zali <muhammad.zali@t-systems.com>
Date: 12th September 2017
An middleware that talks to SM9 via WebMethod email exchange. Run the pre-configured script based on the
data feed from SM9.
"""
import re
import sys
import requests
import logging
import os
# Disabling urrllib3 warning.
from requests.packages.urllib3.exceptions import InsecureRequestWarning

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

# importing custom automata library
sys.path.append('../lib/')

# result processing will look into this line for determining next action.
pass_re = re.compile('CODE:PASS', re.I)
fail_re = re.compile('CODE:FAIL', re.I)

# process configuration
import confighelper

confhelper = confighelper.ConfigHelper()
globalconf = confhelper.config_section_map('global')
log_file = globalconf['log_location']
host_data = globalconf['data_repo']

# create DB class instance to live.
import dbhelper

dbapi = dbhelper.DbApi()

# will take job into list to process.
job_list = []

# check if the log file exists and in correct permission. The log file shared with CGI script.
if not os.path.exists(log_file):
    os.popen('touch {0}; chown root.apache {0}; chmod 664 {0}'.format(log_file))
else:
    os.popen('chown root.apache {0}; chmod 664 {0}'.format(log_file))


# central logmaster
def logmaster(logstring):
    logging.basicConfig(filename=log_file, level=logging.DEBUG, format='%(asctime)s '
                                                                       '%(process)s %(levelname)s %(message)s')
    logging.debug('PPID:%s, %s, %s' % (os.getppid(), __file__, logstring))


logmaster('-' * 30 + ' %s executing ' % __file__ + '-' * 30)

# import need to be here, some logging start too early. quick win.
import commander

command = commander.CommanderRun()
import dataprocessor


# simple string constructor for code. eliminated DRY.
def returncode(code):
    if 'FAIL' in code:
        code = 'CODE:FAILED'
    elif 'PASS' in code:
        code = 'CODE:PASSED'
    else:
        code = 'CODE:UNKNOWN'
    return code


# read the mailbox, validate the XML body and parse the XML body.
def readmailbox():
    try:
        logmaster('Reading mailbox interface...')
        dataprocessor.readinbox()
        logmaster('Completed mailbox routine...')
    except RuntimeError as err:
        logmaster('Error reading mailbox interface: %s...' % str(err))
        logmaster('Completed mailbox routine...')
        dataprocessor.sendalert(str(err))


# lookup into database that has status == 0. and append it into job_list list pointer.
def findjob():
    try:
        logmaster('Querying database for new job (status == 0)...')
        job_id = dbapi.get_new_jobid()
        if job_id:
            for ident in job_id:
                logmaster('Found new job for execution with database id: %s... ' % ident)
                job_list.append(ident)
        else:
            logmaster('No new job found, exit(0)...')
            logmaster('Completed mailbox routine...')
    except RuntimeError as err:
        logmaster('Exception during reading database for new job: %s...' % str(err))
        dataprocessor.sendalert(str(err) + ' :Unable to read database!')


# main routine starts here.
def main():
    logmaster('Executing mailbox routine...')
    # read mailbox and load into database.
    readmailbox()
    logmaster('Starting database routine...')
    # find new job that has been loaded into database. this function returned job_list list.
    findjob()
    # starts to read each item in the list for processing.
    for job in job_list:
        logmaster('Job execution routine started...')
        # Get the event details and make a variable for each info.
        jobmetadata = dbapi.get_jobid_details(jobid=job)
        job_log = host_data + '/' + jobmetadata['loglocation']
        job_hostname = str(jobmetadata['hostname'].lower().replace(" ", ""))
        job_sm9id = str(jobmetadata['sm9id'])
        job_info = str(jobmetadata['sm9info'])
        job_ag = str(jobmetadata['sm9ag'])
        job_stat = int(jobmetadata['status'])
        if not job_stat == 0:
            logging.debug('Job %s already picked up by another running script, skipping...' % job_sm9id)
        else:
            try:
                fd = open(job_log, 'w')
            except RuntimeError as err:
                logmaster('Unable to open log: %s : %s...' % (job_log, str(err)))
                dataprocessor.sendalert(str(err) + ': Failed to open log file:%s' % job_log)
            # tell database that job picked up and running.
            try:
                logmaster('Updating database with running status for %s...' % job_sm9id)
                dbapi.update_run(jobid=job_sm9id)
                logmaster('Database updated!')
            except RuntimeError as err:
                logmaster('Unable to update database: %s...' % str(err))
                dataprocessor.sendalert(str(err) + ': Unable to update database!')
            # passed the event info to execution library for processing and execute.
            out = command.execute_routine(job_hostname, job_sm9id, job_info, job_ag)
            # now read response from execution library and write the log file.
            if out:
                for line in out:
                    fd.write(line.replace('\n', r'&#xD;'))
            # if no response from execution library, log the information.
            else:
                resp = 'Error! No output received?'
                logmaster(resp)
                fd.write(resp)
            fd.close()

            # start to processing execution response. open log file for read.
            fd = open(job_log, 'r')
            fd_content = fd.readlines()
            # Job always set to Failed unless proven not.
            failed_job = True
            # read the content and look for pass REGEX. If REGEX matched, set failed_job to False.
            for line in fd_content:
                if pass_re.search(line.replace(r'&#xD;', '\n')):
                    logmaster('Routine returned CODE:PASS : %s... ' % job_sm9id)
                    failed_job = False
            # pass REGEX matched, tell database event is now OK. sending resolved response back to WebMethod.
            if not failed_job:
                logmaster('Updating database with alarm OFF for :%s...' % job_sm9id)
                dbapi.update_pass(jobid=job_sm9id)
                logmaster('Constructing response for mailbox interface...')
                response = dataprocessor.response_constructor(job_sm9id, fd_content, job_ag, result=True)
                logmaster('Sending response back to mailbox interface...')
                dataprocessor.sendresult(response, job_sm9id)
            # no pass REGEX matched, hence job stayed at failed state, tell database a failed job, and send
            # L2 escalation to WebMethod.
            else:
                logmaster('Updating database with alarm ON for :%s...' % job_sm9id)
                dbapi.update_fail(jobid=job_sm9id)
                logmaster('Constructing response for mailbox interface...')
                response = dataprocessor.response_constructor(job_sm9id, fd_content, job_ag, result=False)
                logmaster('Sending response back to mailbox interface...')
                dataprocessor.sendresult(response, job_sm9id)
            fd.close()


# call script to run.
if __name__ == '__main__':
    main()

logmaster('-' * 30 + ' %s completed ' % __file__ + '-' * 30)
