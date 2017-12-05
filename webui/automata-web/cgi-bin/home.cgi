#!/usr/bin/python -tt

import sys
import cgi
import os
sys.path.append('../lib/')
import automatastatic
import automatajs

html = automatastatic.automatahtml()
js = automatajs.automatajs()

print html.headerHome()
print js.clockjs()
print html.topnav(os.environ['REMOTE_USER'])
print html.processorHome(os.environ['REMOTE_USER'])
print html.footerHome()
