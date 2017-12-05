#!/usr/bin/python -tt
import cgi
def main():
    form = cgi.FieldStorage()
    loglocf = form['loc']
    logloc = loglocf.value
    fd = open(logloc)
    content = fd.readlines()
    for line in content:
        print line 
    fd.close()

print "Content-type: text/plain\n\n"
main()
