#!/usr/bin/python -tt
    
class automatatable:
    def tableHead(self):
        tableHead = """
            <table border='1'>
            <tr>
                <th scope='col'>Task ID</th>
                <th scope='col'>SM9 Incident ID</th>
                <th scope='col'>SM9 Title</th>
                <th scope='col'>SM9 AG</th>
                <th scope='col'>CI Name</th>
                <th scope='col'>Submitted By</th>
                <th scope='col'>Logs</th>
                <th scope='col'>Status</th>
                <th scope='col'>Last Update Time</th>
                <th scope='col'>Last Update By</th>
                <th scope='col'>Resubmit</th>
                <th scope='col'>Delete</th>
            </tr>
        """
        return tableHead
    def tableHeadadhoc(self):
        tableHeadadhoc = """
            <table border='1'>
            <tr>
                <th scope='col'>Task ID</th>
                <th scope='col'>Submitted By</th>
                <th scope='col'>Submitted On</th>
                <th scope='col'>Logs</th>
                <th scope='col'>Status</th>
                <th scope='col'>Resubmit</th>
                <th scope='col'>Delete</th>
            </tr>
        """
        return tableHeadadhoc


    def tableBody(self, id, sm9id, sm9info, sm9ag, hostname, loglocation, submitby):
        tableBody = """
            <tr>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td><a  target=_blank href=output.cgi?loc=%s>Logs</a></td>
            """ % (id, sm9id, sm9info, sm9ag, hostname, submitby, loglocation)
        return tableBody

    def tableBodyadhoc(self, id, submitby, submitdate, loglocation):
        tableBody = """
            <tr>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td><a  target=_blank href=out-ad-hoc.cgi?loc=%s>Logs</a></td>
            """ % (id, submitby, submitdate, loglocation)
        return tableBody



    def tableStatus(self, status):
        if "0" in str(status):
            status="<img src='../images/clocks.svg' alt='' height='20px' witdh='20px'>"
        elif "1" in str(status):
            status="<img src='../images/run.png' alt='' height='20px' witdh='20px'>"
        elif "2" in str(status):
            status="<img src='../images/Retina-Ready.png' alt='' height='20px' witdh='20px'>"
        elif "3" in str(status):
            status="<img src='../images/icon-error.png' alt='' height='20px' witdh='20px'>"
        elif "4" in str(status):
            status="<img src='../images/Unknown_toxicity_icon.svg' alt='' height='20px' witdh='20px'>"
        tableStatus = """
            <td>%s</td>
            """ % status
        return tableStatus

    def tableTime(self, timestamp):
        tableTime = """
                <td>%s GMT+8</td>
                """ % timestamp
        return tableTime

    def tableUser(self, username):
        tableUser = """
            <td>%s</td>
            """ % username
        return tableUser
          

    def tableResubmit(self, id, sm9id, hostname):
        tableResubmit = """
            <td>
            <form action='requeue.cgi' method='post'>
            <input type='hidden' name=id value='%s'>
            <input type='hidden' name=sm9id value='%s'>
            <input type='hidden' name=hostname value='%s'>
            <input type='submit' value='Resubmit'>
            </form>
            </td>
        """ % (id, sm9id, hostname)
        return tableResubmit
 
    def tableResubmitadhoc(self, id):
        tableResubmitadhoc = """
            <td>
            <form action='requeue-ad-hoc.cgi' method='post'>
            <input type='hidden' name=id value='%s'>
            <input type='submit' value='Resubmit'>
            </form>
            </td>
        """ % (id)
        return tableResubmitadhoc



    def tableDelete(self, id, sm9id, hostname):
        tableDelete = """
        <td>
        <form action='delete.cgi' method='post'>
        <input type='hidden' name=id value='%s'>
        <input type='hidden' name=sm9id value='%s'>
        <input type='hidden' name=hostname value='%s'>
        <input type='submit' value='Delete'>
        </form>
        </td>
        """ % (id, sm9id, hostname)
        return tableDelete


    def tableDeleteadhoc(self, id):
        tableDeleteadhoc = """
        <td>
        <form action='del-ad-hoc.cgi' method='post'>
        <input type='hidden' name=id value='%s'>
        <input type='submit' value='Delete'>
        </form>
        </td>
        """ % (id)
        return tableDeleteadhoc




    def tableClose(self):
        tableClose = """
            </tr>
            </table>
            <br>
        """
        return tableClose

