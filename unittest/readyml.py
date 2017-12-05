#!/usr/bin/python
import os
import yaml

config_file = 'script.yml'

for config_path in [config_file]:
    try:
        config_config = yaml.safe_load(open(os.path.expanduser(config_path), 'r').read())
        for config in config_config:
            print config
    except:
        pass
