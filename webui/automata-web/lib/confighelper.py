#!/usr/bin/python -tt

import ConfigParser
import sys


CONF_FILE = "/opt/automata/config/automataprod.conf"

Config = ConfigParser.ConfigParser()
Config.read(CONF_FILE)

class confighelper:
    def ConfigSectionMap(self, section):
        conflist = {}
        options = Config.options(section)
        for option in options:
            try:
                conflist[option] = Config.get(section, option)
                if conflist[option] == -1:
                    print("Skip: %s" % option)
            except:
                print("Exception occured on %s" % option)
                conflist[option] = None
                sys.exit(1)
        return conflist
