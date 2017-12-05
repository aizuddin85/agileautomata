#!/usr/bin/python -tt
import sys
import os

#Custom libs import
sys.path.append('../lib/')
import automatalanding
import automatajs

html = automatalanding.automatahtml()
js = automatajs.automatajs()

def landingpage():
    print html.headerHome()
    print js.clockjs()
    print html.topnav(os.environ['REMOTE_USER'])
    print html.landingHome()
    print html.footerHome()

landingpage()
