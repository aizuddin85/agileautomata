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
print "  <h1 style='text-align: center; color: white;'>New User Application</h1> \
        <div align=center> \
        <form action='userstage.cgi' method='post'> \
                <h2 style='text-align: center; color: white;'>Enter your GID:</h2><br> \
                <input  style='text-align:center; width: 100px' type='text' name='username' value='mzali'><br> \
                <h2 style='text-align: center; color: white;'>Enter your password:</h2><br> \
                <input style='text-align:center' type='text' name='password' value='xxxxxx123'><br> \
                <h2 style='text-align: center; color: white;'>Enter your email:</h2><br> \
                <input style= 'width: 300px; text-align:center;'type='text' name='email' value='john.doe@example.com'><br> \
                <br> \
                <input type='submit' value='Submit'> \
        </form> \
        </div> \
"
print "</body>"
print "</html>"
#print html.footerHome()
