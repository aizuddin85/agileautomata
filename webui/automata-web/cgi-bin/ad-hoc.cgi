#!/usr/bin/python -tt
import sys
import os

#Custom libs import
sys.path.append('../lib/')
import automataaddhoc
import automatajs

html = automataaddhoc.automatahtml()
js = automatajs.automatajs()

def adhocpage():
    print html.headerHome()
    print js.clockjs()
    print html.topnav(os.environ['REMOTE_USER'])
    print html.landingHome()
    print html.footerHome()

adhocpage()
