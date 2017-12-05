#!/usr/bin/python
# Author: Muhammad Aizuddin Bin Zali <muhammad.zali@t-systems.com>
# Library to read configuration file and return dict.
import sys
import os
import ConfigParser

# set which config file need to be read.
CONF_FILE = '/opt/automata/config/automataprod.conf'

Config = ConfigParser.ConfigParser()
Config.read(CONF_FILE)


# implementing standard class of confighelper.
class ConfigHelper:
    def __init__(self):
        # initialize a dictionary of conflist
        self.conflist = {}

    def config_section_map(self, section):
        # return dictionary of configured key value.
        options = Config.options(section)
        for option in options:
            try:
                self.conflist[option] = Config.get(section, option)
                if self.conflist[option] == -1:
                    print("Skip: %s" % option)
            except AttributeError:
                print("Exception occured on %s" % option)
                self.conflist[option] = None
                sys.exit(1)
        # return conflist dictionary to the caller.
        return self.conflist
