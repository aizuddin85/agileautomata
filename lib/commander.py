#!/usr/bin/python
# Author: Muhammad Aizuddin Bin Zali <muhammad.zali@t-systems.com>
# Date: 29th November 2017
# Library to connect, send, execute, and readback the script.
import confighelper
import paramiko
import re
import logging
import yaml
import os
import time
import os.path
import urllib3
import subprocess
import StringIO
import socket

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# read configuration and set the variable for it.
confhelper = confighelper.ConfigHelper()
globalconf = confhelper.config_section_map('global')
debug_flag = globalconf['debug']
log_file = globalconf['log_location']
data_temp = globalconf['data_repo']
script_repo = globalconf['script_repo']

# define logging mechanism.
logging.basicConfig(filename=log_file, level=logging.DEBUG, format='%(asctime)s %(process)s %(levelname)s %(message)s ')
logging.getLogger("paramiko").setLevel(logging.WARN)

# paramiko specific configuration.
paramikoconf = confhelper.config_section_map('paramiko')
timer = paramikoconf['timeout']
private_key = paramikoconf['private_key']

# script specific configuration.
script_conf = confhelper.config_section_map('script')['main']

# whitespace regex.
e = re.compile(r"\s+")


class CommanderRun:
    # read an YAML conf file for each REGEX and its respective script to run. Use paramiko to connect, put, run and then
    # read the stdout and send it back to the caller.
    def __init__(self):
        self.bufsize = 1024
        # create paramiko SSH client.
        self.ssh = paramiko.SSHClient()
        # Auto add missing host key.
        self.ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        self.main_config = []
        # read script_conf yaml file and put is as main_config for later processing.
        for config_path in [script_conf]:
            try:
                self.config_config = yaml.safe_load(open(os.path.expanduser(config_path), 'r').read())
                for config in self.config_config:
                    self.main_config.append(config)
            except yaml.YAMLError as err:
                logging.debug(str(err))

    def sanitize_addr(self, addr):
        if len(addr) != 0:
            hostaddr = addr.replace(" ", "")
            return hostaddr

    def get_namespace(self, smag):
        for main in self.main_config:
            if re.search(main, smag, re.IGNORECASE):
                self.namespace = main
                return self.namespace

    def get_regex(self, smregex, mainconf):
        self.regexdict = {}
        for self.key in self.config_config[mainconf]:
            self.regex = self.key['regexinfo']
            if re.search(self.regex, smregex, re.IGNORECASE):
                logging.debug('Found match regex, %s..!' % self.regex)
                self.localconn = self.key['localconn']
                self.scriptname = self.key['scriptname']
                self.regexdict['local'] = self.localconn
                self.regexdict['script'] = self.scriptname
                return self.regexdict

    def get_exec(self, scriptname):
        self.script = script_repo + scriptname
        if os.path.isfile(self.script):
            self.cmd = '%s' % self.script
            logging.debug('Constructed script to be executed: %s...' % self.cmd)
            return self.cmd

    def sftp_exec_script(self, addr, source, target, user, keyfile, timer):
        try:
            self.ssh.connect(addr, username=user, key_filename=keyfile, timeout=int(timer))
            self.sftp = self.ssh.open_sftp()
            if os.path.isfile(source):
                try:
                    self.sftp.put(source, target)
                except (socket.timeout, paramiko.SSHException) as err:
                    logging.debug(str(err))
                    self.msg = '\n[OUTPUT]\n' \
                               'Unable to transfer script to remote site: %s\n' \
                               'Exception: %s\n' \
                               '[RESULT]\n' \
                               'CODE:FAIL\n' % (addr, str(err))
                    return self.msg
                try:
                    self.ssh.connect(addr, username=user, key_filename=keyfile, timeout=int(timer))
                    self.channel = self.ssh.get_transport().open_session()
                    self.channel.settimeout(int(timer))
                    self.exec_cmd = 'chmod +x {0}; {0}; rm -f {0}'.format(target)
                    self.channel.exec_command(self.exec_cmd)
                    self.response = StringIO.StringIO()
                    self.error = StringIO.StringIO()
                    while not self.channel.exit_status_ready():
                        if self.channel.recv_ready():
                            self.data = self.channel.recv(self.bufsize)
                            while self.data:
                                self.response.write(self.data)
                                self.data = self.channel.recv(self.bufsize)
                        if self.channel.recv_stderr_ready():
                            self.error_buffer = self.channel.recv_stderr(self.bufsize)
                            while self.error_buffer:
                                self.error.write(self.error_buffer)
                                self.error_buffer = self.channel.recv_stderr(self.bufsize)
                    self.exit_rc = self.channel.recv_exit_status()
                    logging.debug('Exit RC from channel: %s' % str(self.exit_rc))
                    if not self.response:
                        return self.error.getvalue()
                    else:
                        return self.response.getvalue()
                except (socket.timeout, paramiko.SSHException) as err:
                    logging.debug(str(err))
                    self.msg = '\n[OUTPUT]\n' \
                               'Timed out after %s secs ran script on remote site: %s\n' \
                               'Exception: %s\n' \
                               '[RESULT]\n' \
                               'CODE:FAIL\n' % (str(timer), addr, str(err))
                    return self.msg
                finally:
                    # self.ssh.close()
                    # self.response.close()
                    # self.error.close()
                    logging.debug('Closed all socket and file descriptor...')
        except Exception as err:
            self.msg = '\n[OUTPUT]\n' \
                       'SSH timed out to %s waiting for command output after %s seconds.\n' \
                       'Exception: %s\n' \
                       'Script target name: %s\n' \
                       'Script source name: %s\n\n' \
                       '[RESULT]' \
                       '\nCODE:FAIL\n' % (str(addr), str(timer), str(err), target, source)
            logging.debug(self.msg)
            return self.msg

    def local_exec(self, cmd, addr):
        try:
            self.p = subprocess.Popen([cmd, addr], stdout=subprocess.PIPE,
                                      stderr=subprocess.PIPE)
            self.stdout, self.stderr = self.p.communicate()
            if self.stdout:
                return self.stdout
            if self.stderr:
                return self.stderr
        except OSError as err:
            self.errmsg = '\n[OUTPUT]\n' \
                          'Exception while running local command!\n' \
                          'Error: %s\n' \
                          'Errno: %s\n' \
                          'File: %s\n' \
                          '[RESULT]\n' \
                          'CODE:FAIL' % (err.strerror, err.errno, err.filename)
            logging.debug(self.errmsg)
            return self.errmsg


    def execute_routine(self, addr, smid, sminfo, smag):
        initme = CommanderRun()
        self.myaddr = initme.sanitize_addr(addr)
        if self.myaddr:
            self.mainconfig = initme.get_namespace(smag)
            if self.mainconfig:
                logging.debug('Found configured namespace for AG: %s' % smag)
                self.regexinfo = initme.get_regex(sminfo, self.mainconfig)
                if self.regexinfo:
                    logging.debug('Found configured regex for: %s' % sminfo)
                    if self.regexinfo['local']:
                        logging.debug('Local execution selected, executing locally...')
                        self.mycmd = initme.get_exec(self.regexinfo['script'])
                        if self.mycmd:
                            logging.debug('Executing local script of : %s %s' % (self.mycmd, self.myaddr))
                            self.localout = initme.local_exec(self.mycmd, self.myaddr)
                            return self.localout
                        else:
                            self.errmsg = 'Unable to get which script to be executed for %s!' % smid
                            logging.debug(self.errmsg)
                            self.msg = '[RESULT]\n' + self.errmsg + '\nCODE:FAIL\n'
                            return self.msg
                    else:
                        logging.debug('Not local, attempting SSH execution to %s...' % self.myaddr)
                        self.script_src = initme.get_exec(self.regexinfo['script'])
                        self.script_tgt = '/tmp/' + self.regexinfo['script'] + '_dev' + str(int(time.time()))
                        try:
                            logging.debug('Executing on %s, please wait...' % self.myaddr)
                            self.exec_object = initme.sftp_exec_script(self.myaddr, self.script_src, self.script_tgt,
                                                                       'root', private_key, timer)
                            return self.exec_object
                        except Exception as err:
                            self.errmsg = '\n[OUTPUT]\n' \
                                          'General commander execution library: %s!\n' \
                                          '[RESULT]\n' \
                                          'CODE:FAIL' % str(err)
                            return self.errmsg
                else:
                    self.errmsg = 'Unable to find matched %s regex...' % smid
                    logging.debug(self.errmsg)
                    self.msg = '[RESULT]\n' + self.errmsg + '\nCODE:FAIL\n'
                    return self.msg
            else:
                self.errmsg = 'Unable to find configured AG namespace: %s....' % smag
                logging.debug(self.errmsg)
                self.msg = '\n[RESULT]\n' + self.errmsg + '\nCODE:FAIL\n'
                return self.msg
        else:
            self.errmsg = '\n[RESULT]\n' \
                          'Empty host information for %s. Fatal Error!' \
                          '\nCODE:FAIL\n' % smid
            logging.debug(self.errmsg)
            return self.errmsg
