#!/usr/bin/python
# Author: Muhammad Aizuddin Bin Zali <muhammad.zali@t-systems.com>
# Date: 12th September 2017
# Library to check for TCP 22 reachable.
import socket
import signal


def ignore_signal(signo, frame):
    pass


# function to return boolean for connection check.
# If socket conn attempt reach time out python will thrown: [Errno 4] Interrupted system call due to SIG_DFL
def reach(hostname):
    # set addr for target and port.
    hostname = hostname.strip()
    addr = (hostname, 22)
    # create socket as TCP stream.
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        # set the signal handler SIGALRM, do nothing when signal received and a 5 second alarm.
        signal.signal(signal.SIGALRM, ignore_signal)
        signal.alarm(5)
        try:
            # attempt to connect and return False if failed.
            s.connect(addr)
        except socket.error as err:
            print err
            return False
    finally:
        # set the signal back to kernel default hanlder and disable the alarm timer.
        signal.signal(signal.SIGALRM, signal.SIG_DFL)
        signal.alarm(0)
    s.close()
    return True
