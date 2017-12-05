#!/usr/bin/python -tt
import sys
import cgi
import mysql.connector
from mysql.connector import errorcode
import time

#Custom libs import
sys.path.append('../lib/')
import confighelper
helper = confighelper.confighelper()
datafile = helper.ConfigSectionMap('global')['data_repo']
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
    loglocf = form['loc']
    logloc = loglocf.value
    fd = open(datafile + "/" + logloc, 'r')
    content = fd.readlines()
    for line in content:
        print line.replace(r'&#xD;', '\n') 
print "Content-type: text/plain\n\n"
main()

