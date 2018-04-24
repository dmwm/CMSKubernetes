#! /usr/bin/env python

"""
Read and rewrite a config/INI file doing environment replacements. The replacement happens as each element is read

This is useful because init removes all environment variables from the child processes
"""


import os
from ConfigParser import SafeConfigParser

FILENAME = '/opt/rucio/etc/rucio.cfg'

REPLACE = [('database', 'default')]

config = SafeConfigParser(os.environ)
config.read(FILENAME)

for section, option in REPLACE:
    value = config.get(section, option)
    config.set(section, option, value)

with open(FILENAME, 'wb') as configfile:
    config.write(configfile)
