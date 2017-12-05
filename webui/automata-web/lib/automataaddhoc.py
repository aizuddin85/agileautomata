#!/usr/bin/python -tt
import confighelper
helper = confighelper.confighelper()
PAGE_TITLE = helper.ConfigSectionMap('web')['title']
VERSION = helper.ConfigSectionMap('web')['version']


class automatahtml:
    def redirect(self, url):
        redirectUrl = """
            Location: %s
            <html>
                <head>
                    <meta http-equiv='refresh' content='0,url=' />
                    <title>Redirecting ...</title>
                </head>
                <body>
                    Redirecting..<a href='%s'>Click here if you still stuck here!</a>
                </body>
             </html>
            """ % (url, url)

        return redirectUrl

    def header(self):
        header = """
            <html>
                <head>
                    <meta charset='UTF-8'>
                    <title>%s</title>
                    <link rel='stylesheet' href='../css/adhoc.css' type='text/css'>
                </head>
                <body class='list'>
        """  % PAGE_TITLE
        return header
    def headerHome(self):
        headerHome = """
            <html>
                <head>
                    <meta charset='UTF-8'>
                    <title>%s</title>
                    <link rel='stylesheet' href='../css/adhoc.css' type='text/css'>
                </head>
                <body class='home'>
        """ % PAGE_TITLE
        return headerHome

    def landingHome(self):

        self.processor = """
            <form class='home' action='proc-ad-hoc.cgi' method='post' id='formadhoc'>
                <h2> ADD-HOC JOB SUBMISSION </h2>
                <font>Task(s) multi select:</font><br>
                <input type='checkbox' name='script' value='cpuload'>CPU Load<br>
                <input type='checkbox' name='script' value='rootfs'>Check Root FS<br>
                <input type='checkbox' name='script' value='swapspace'>Swap Space<br>
                <input type='checkbox' name='script' value='checkuptm'>Check Uptime<br><br>
                <input type='hidden' name='userid' value='%s'>
                <font>Hostname(s), comma-separated:</font><br>
                <textarea rows='6' cols='35' name='host' form='formadhoc'<br></textarea><br><br>
                <input type='submit' value='Submit'>
            </form>
            """
        return self.processor

    def footerHome(self):
        footer = """
            </body>
            </div>
            </div>
            </html>
            """ % VERSION
        return footer

    def topnav(self, username):
        topnav = """
            <div class='topnavi'>
            <img src='../images/example.png' alt='examplelogo'>
            <img src='../images/tlogo.svg' alt='tlogo'>
            <a href='landing.cgi'>Home</a>
                <font>%s </font>
                <div id='clockbox' style='font:14pt Arial; color: white;'></div>
                <h2> Welcome, %s! </h2>
            </div>
	    <br><br>
            """ % (PAGE_TITLE, username)
        return topnav

    def backbtn(self):
        backbtn = """
            <form class='back'><input Type='button' VALUE='Back' onClick='history.go(-1);return true;'></form>
            """
        return backbtn

    def legendClose(self):
        legendClose = """
            <p class='legend'>
            STATUS: <br>
            <img src='../images/clocks.svg' alt='' height='20px' witdh='20px'> = ready for daemon to pickup and run the routine<br>
            <img src='../images/run.png' alt='' height='20px' witdh='20px'> = job picked and currently is running<br>
            <img src='../images/Retina-Ready.png' alt='' height='20px' witdh='20px'>  = job finished and the routine returns no issue<br>
            <img src='../images/icon-error.png' alt='' height='20px' witdh='20px'>    = job finished and the routine returns issue persist<br>
            <img src='../images/Unknown_toxicity_icon.svg' alt='' height='20px' witdh='20px'> = daemon has no idea how to proceed<br>
            </p>
            </body>
            </html>
            """
        return legendClose
    def landing(self):
        landing = """
                <div class='landing'>
                <a href='#'>Link</a>
                </div>
                </body>
                </html>
               """
        return landing

