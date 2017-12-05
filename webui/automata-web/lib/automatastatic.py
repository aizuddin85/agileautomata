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
                    <link rel='stylesheet' href='../css/home.css' type='text/css'>
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
                    <link rel='stylesheet' href='../css/home.css' type='text/css'>
                </head>
                <body class='home'>
        """ % PAGE_TITLE
        return headerHome
    
    def processorHome(self, username):
        processor = """
               <form class='home'  action='process.cgi' method='post'>
                    <font>SM9 Incident ID:<a target=_blank href='#' title='Please enter current SM9 ticket no, e.g IM1234567890'><img src='../images/question.png' height='13px' widht='13px'></a></font><br>
                    <input type='text' name='sm9id' value=''><br><br>
                    <font>SM9 Title:<a target=_blank href='#' title='Please enter current SM9 ticket title: e.g CPU Utilization exceeds configured threshold'><img src='../images/question.png' height='13px' widht='13px'></a></font><br>
                    <input type='text' name='sm9info' value=''><br><br>
                    <font>CI Name:<a target=_blank href='#' title='Please enter current SM9 Configuration Item name (FQDN), e.g amsdc1-n-s00070.europe.example.com'><img src='../images/question.png' height='13px' widht='13px'></a></font><br>
                    <input type='text' name='hostname' value=''><br><br>
                    <font>SM9 AG:<a target=_blank href='#' title='Plesae enter SM9 AG, e.g C.SH.MY.LUX.EVT.'><img src='../images/question.png' height='13px' widht='13px'></a></font><br>
                    <input type='text' name='sm9ag' value=''><br><br>
                    <input type='hidden' name='userid' value='%s'>
                    <input type='submit' value='Submit'>
                </form>
            """ % username
        return processor
   
    def landingHome(self):

        self.processor = """
               <form class='home'>
                </form>
            """ 
        return self.processor
 
    def footerHome(self):
        footer = """
            <div class="footer">
                Ver:%s - 1st Feb 2017<br>
                example Sdn Bhd<br>
                &copy Author: Zali, Muhammad Aizuddin(mzali)
                
            </div>
            </div>
            </body>
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
