#!/usr/bin/python -tt
    
class table:
    def tableHead(self):
        self.tableHead = """
            <table border='1'>
            <tr>
                <th scope='col'>Task ID</th>
                <th scope='col'>Owner</th>
                <th scope='col'>Time</th>
                <th scope='col'>Logs</th>
                <th scope='col'>Status</th>
                <th scope='col'>Resubmit</th>
                <th scope='col'>Delete</th>
            </tr>
        """
        return self.tableHead

    def tableBody(self, taskid, owner, date, loglocation):
        self.tableBody = """
            <tr>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td><a  target=_blank href=out-ad-hoc.cgi?loc=%s>Logs</a></td>
            """ % (taskid, owner, date, loglocation)
        return self.tableBody

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
          

    def tableResubmit(self, id):
        self.tableResubmit = """
            <td>
            <form action='requeue-ad-hoc.cgi' method='post'>
            <input type='hidden' name=id value='%s'>
            <input type='submit' value='Resubmit'>
            </form>
            </td>
        """ % (id)
        return self.tableResubmit

    def tableDelete(self, id):
        self.tableDelete = """
        <td>
        <form action='del-ad-hoc.cgi' method='post'>
        <input type='hidden' name=id value='%s'>
        <input type='submit' value='Delete'>
        </form>
        </td>
        """ % (id)
        return self.tableDelete

    def tableClose(self):
        tableClose = """
            </tr>
            </table>
            <br>
        """
        return tableClose

