#!/usr/bin/python
"""
Author: Muhammad Aizuddin Bin Zali <muhammad.zali@t-systems.com>
Date: 12th September 2017
An middleware that talks to SM9 via WebMethod email exchange. Run the pre-configured script based on the
data feed from SM9.
"""
import re
import sys
import logging
import time
import requests
import syslog
# Disabling urrllib3 warning.
from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
# Importing custom library
sys.path.append('/opt/automata/lib/')
import confighelper
import dbhelper
import helper
import commander
import pinger

# Only two outcomes from the supplied script. PASS/FAIL.
pass_re = re.compile('^CODE:PASS', re.I)
fail_re = re.compile('^CODE:FAIL', re.I)
# Sets No IP Regex
noip_re = r'\bThe message flow is broken\b'

# Instantiation of needed classes and function.
confhelper = confighelper.ConfigHelper()
log_file = confhelper.config_section_map('global')['log_location']
debug_flag = confhelper.config_section_map('global')['debug']
host_data = confhelper.config_section_map('global')['data_repo']
logging.basicConfig(filename=log_file, level=logging.DEBUG)
logging.debug(80*'#' + ' HERE WE GO: STARTS' + 80*'#')
logging.debug(' >>> Run start at : %s' % time.strftime('%X %x %Z'))
# Due to logging constaint dataprocessor custom library imported here.
import dataprocessor
dbapi = dbhelper.DbApi()
command = commander.CommanderRun()
job_list = []
# Sets sleep time after email reading to avoid race condition with database UPDATE and later SELECT.
sleeptime = 3

# Are we on DEBUG True environment?
if 'True' in debug_flag:
    DEBUG = True
else:
    DEBUG = False

if DEBUG:
    logging.debug('Starting to quering database for new job...')
if DEBUG:
    logging.debug('Reading inbox for any new job sent by WebMethod...')

# Now read the mailbox and add new job into the database.
try:
    if DEBUG:
        logging.debug('Reading mailbox...')
    dataprocessor.readinbox()
    logging.debug('Sleeping for %s' % sleeptime)
    time.sleep(3)
except RuntimeError as err:
    logging.debug(err)
    raise err

# Checkf for new job (status == 0),if job is found, create a list for processing. Exit if no job.
job_id = dbapi.get_new_jobid()
logging.debug(job_id)
if job_id:
    for ident in job_id:
        logging.debug('Found job id: {}'.format(str(ident)))
        if DEBUG:
            logging.debug('Found job with id: {}'.format(str(ident)))
        job_list.append(ident)
else:
    logging.debug('No job found!')
    sys.exit(0)
# Start to process the job if found.
for job in job_id:
    # Get the info from database for each new job found.
    jobmetadata = dbapi.get_jobid_details(jobid=job)
    jobmetalogs = host_data + '/' + jobmetadata['loglocation']
    jobmetaname = str(jobmetadata['hostname'].lower().replace(" ",""))
    jobmetasmid = str(jobmetadata['sm9id'])
    jobmetainfo = str(jobmetadata['sm9info'])
    jobmetaag = str(jobmetadata['sm9ag'])
    if DEBUG:
        logging.debug('JobID:{}'.format(job))
        logging.debug('Host:{}\nLogs:{}\nSM9ID:{}\nSM9INFO:{}\n'.format(jobmetaname, jobmetalogs,
                                                                        jobmetasmid, jobmetainfo))
    # Check if the host is reachable or not before continuing. Write to log if fail and update the db for status. If OK
    # continue to run.
    if not helper.reach(jobmetaname):
        if DEBUG:
            logging.debug('Host: %s not reachable!' % jobmetaname)
        logging.debug('Host: {}  not reachable.'.format(jobmetaname))
        fd = open(jobmetalogs, 'w')
        fd.write('Host:{} not reachable {}!\nCODE:FAILED\n'.format(jobmetaname, time.strftime('%X %x %Z')))
        fd.close()
        try:
            if DEBUG:
                logging.debug('Job flagged as failed: %s' % jobmetasmid)
            dbapi.update_fail(jobid=jobmetasmid)
            try:
                fd = open(jobmetalogs, 'r')
                fd_content = fd.readlines()
                myresp = dataprocessor.response_constructor(jobmetasmid, fd_content, jobmetaag, result=False)
                dataprocessor.sendresult(myresp, jobmetasmid)
                fd.close()
            except IOError as err:
                print err
                pass
        except RuntimeError as err:
            logging.debug('Unable to update database, check library exception!')
            raise err
        fd.close()
    else:
        # From the jobmetainfo(sm9info) call hepler to get which routine we should run.
        fd = open(jobmetalogs, 'w')
        # No IP always goes here instead of being send to the commander function to run. Other jobs will be send to
        # commander to run.
        if re.search(noip_re, jobmetainfo):
            logging.debug('No IP routine detected for %s for %s.' % (jobmetaname, jobmetasmid))
            dbapi.update_run(jobid=jobmetasmid)
            # Now ping the host with 5 seconds timeout and 64 bytes of ICMP packet size.
            out = pinger.do_one(jobmetaname, 5, 64)
            if isinstance(out, float):
                # If the response is more than 1 seconds then failed as high latency.
                if out > 1.0:
                    logging.debug('Latency too high for %s: %s more than 1 sec.' % (jobmetaname, str(out)))
                    fd.write('Latency is high:{} \t\t {}\n'.format(out, time.strftime('%X %x %Z')))
                    fd.write('CODE:FAIL\n')
                    fd.close()
                    dbapi.update_fail(jobid=jobmetasmid)
                    fd = open(jobmetalogs, 'r')
                    fd_content = fd.readlines()
                    fd.close()
                    if DEBUG:
                        logging.debug('Construction response...')
                    myresp = dataprocessor.response_constructor(jobmetasmid, fd_content, jobmetaag, result=False)
                    if DEBUG:
                        logging.debug('Sending response...')
                    dataprocessor.sendresult(myresp, jobmetasmid)
                else:
                    logging.debug('Latency is OK for %s: %s not more than 1 sec.' % (jobmetaname, str(out)))
                    fd.write('Latency is normal:{} \t\t {}\n'.format(out, time.strftime('%X %x %Z')))
                    fd.write('CODE:PASS\n')
                    fd.close()
                    dbapi.update_pass(jobid=jobmetasmid)
                    fd = open(jobmetalogs, 'r')
                    fd_content = fd.readlines()
                    fd.close()
                    if DEBUG:
                        logging.debug('Construction response...')
                    myresp = dataprocessor.response_constructor(jobmetasmid, fd_content, jobmetaag, result=True)
                    if DEBUG:
                        logging.debug('Sending response...')
                    dataprocessor.sendresult(myresp, jobmetasmid)
            else:
                if DEBUG:
                    logging.debug('Oppss, we think that ICMP returned a garble response, not understood.')
                fd.write('ICMP Library returned unknown format!')
                fd.write('CODE:FAIL\n')
                fd.close()
                dbapi.update_fail(jobid=jobmetasmid)
                fd = open(jobmetalogs, 'r')
                fd_content = fd.readlines()
                fd.close()
                myresp = dataprocessor.response_constructor(jobmetasmid, fd_content, result=False)
                dataprocessor.sendresult(myresp, jobmetasmid)
        else:
            # Except for NoIP, send the job to the executor library and get back the result.
            if DEBUG:
                logging.debug('Routine started...')
            dbapi.update_run(jobid=jobmetasmid)
            out = command.execute_routine(jobmetaname, jobmetalogs, jobmetasmid, jobmetainfo)
            if out:
                for line in out:
                    fd.write(line)
                    if DEBUG:
                        print line
            else:
                fd.write('No output received from paramiko stdout!')
                if DEBUG:
                    print('No output received from paramiko stdout!')
            fd.close()
            fd = open(jobmetalogs, 'r')
            content = fd.readlines()
            # Job always set to Failed unless proven not.
            failed_job = True
            for line in content:
                if pass_re.match(line):
                    if DEBUG:
                        print 'CODE:PASS matched!'
                    failed_job = False
            if not failed_job:
                dbapi.update_pass(jobid=jobmetasmid)
                fd = open(jobmetalogs, 'r')
                fd_content = fd.readlines()
                fd.close()
                if DEBUG:
                    logging.debug('Construction response...')
                myresp = dataprocessor.response_constructor(jobmetasmid, fd_content, jobmetaag, result=True)
                if DEBUG:
                    logging.debug('Sending response...')
                dataprocessor.sendresult(myresp, jobmetasmid)
            else:
                if DEBUG:
                    logging.debug('The routine execution failed: %s.' % jobmetasmid)
                dbapi.update_fail(jobid=jobmetasmid)
                fd = open(jobmetalogs, 'r')
                fd_content = fd.readlines()
                fd.close()
                if DEBUG:
                    logging.debug('Construction response...')
                myresp = dataprocessor.response_constructor(jobmetasmid, fd_content, jobmetaag, result=False)
                if DEBUG:
                    logging.debug('Sending response...')
                dataprocessor.sendresult(myresp, jobmetasmid)
            fd.close()
