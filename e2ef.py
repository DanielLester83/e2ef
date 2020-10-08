#!/usr/bin/env python
# -*- coding: utf-8 -*-

import re
import sys
import os
from datetime import datetime
import time
import gc
from datetime import date
import fcntl, sys

try:
    from configparser import SafeConfigParser # Python 3
except ImportError:
    from ConfigParser import SafeConfigParser  # Python 2

# Boiler plate to avoid dependency on six
# BBB: Python 2.7 support
PY3K = sys.version_info > (3, 0)

class FreeMemLinux(object):
    """
    Non-cross platform way to get free memory on Linux. Note that this code uses
    the `with ... as`, which is conditionally Python 2.5 compatible! If for some reason you still have Python 2.5 on your
    system add in the head of your code, before all imports: from __future__ import with_statement
    """
    def __init__(self, unit='kB'):

        with open('/proc/meminfo', 'r') as mem:
            lines = mem.readlines()

        self._tot = int(lines[0].split()[1])
        self._free = int(lines[1].split()[1])
        self._buff = int(lines[2].split()[1])
        self._cached = int(lines[3].split()[1])
        self._shared = int(lines[20].split()[1])
        self._swapt = int(lines[14].split()[1])
        self._swapf = int(lines[15].split()[1])
        self._swapu = self._swapt - self._swapf

        self.unit = unit
        self._convert = self._factor()
    def _factor(self):
        """determine the convertion factor"""
        if self.unit == 'kB':
            return 1
        if self.unit == 'k':
            return 1024.0
        if self.unit == 'MB':
            return 1/1024.0
        if self.unit == 'GB':
            return 1/1024.0/1024.0
        if self.unit == '%':
            return 1.0/self._tot
        else:
            raise Exception("Unit not understood")

    @property
    def total(self):
       return self._convert * self._tot

    @property
    def used(self):
        return self._convert * (self._tot - self._free)

    @property
    def used_real(self):
        """memory used which is not cache or buffers"""
        return self._convert * (self._tot - self._free - self._buff - self._cached)

    @property
    def shared(self):
        return self._convert * (self._tot - self._free)

    @property
    def buffers(self):
        return self._convert * (self._buff)

    @property
    def cached(self):
        return self._convert * self._cached

    @property
    def user_free(self):
        """This is the free memory available for the user"""
        return self._convert *(self._free + self._buff + self._cached)

    @property
    def swap(self):
        return self._convert * self._swapt

    @property
    def swap_free(self):
        return self._convert * self._swapf

    @property
    def swap_used(self):
        return self._convert * self._swapu

#if __name__ == '__main__':
if True:
    pid_file = '/home/e2ef/.gnupg/e2ef.pid'
    go = 0
    while go == 0:
        try:
            fp = open(pid_file, 'w')
            fcntl.lockf(fp, fcntl.LOCK_EX | fcntl.LOCK_NB)
            go = 1
        except IOError:
            time.sleep(10)

    # BBB: Python 2.7 support
    binary_stdin = sys.stdin.buffer if PY3K else sys.stdin
    now = datetime.now()
    pid = str(os.getpid())
    message = binary_stdin.read()
    if message == "":
	message = "Subject: (Empty Subject)\n\n(Empty Message) " + now.strftime("%m/%d/%Y, %H:%M:%S")
    text = message
    posa = text.find("Subject: ")
    if posa == -1:
	text = "Subject: (Empty Subject)\n" + text
	posa = 0
    subject = text[posa:].partition("\n\n")[0]
    subject = subject.split("\n")[0]
    memory = FreeMemLinux()
    splitlen = memory.user_free/1024 - 1024
    tails = [0]
    body = text.partition("\n\n")[2]
    posa = 0
    while len( body[posa:] ) >= splitlen or tails[-1] == 0:
        f = open("/home/e2ef/.gnupg/" + str(pid) + str(tails[-1]) + ".enc", "w")
        f.write( body[posa:posa+splitlen] )
        f.close()
        posa = posa + splitlen
        tails.append( tails[-1] + 1 )
    increment = ""
    for i in tails[:-1]:
        gc.collect()
        result = os.popen("gpg --homedir /home/e2ef/.gnupg --batch --yes --passphrase=##PASSPHRASE## --pinentry-mode loopback --always-trust -ea --sign -u \"##SEMAIL##\" -r \"##SEMAIL##\" -o - /home/e2ef/.gnupg/" + str(pid) + str(tails[i]) + ".enc > /home/e2ef/.gnupg/" + str(pid) + str(tails[i]) + "b.enc")
        time.sleep(3)
        f = open("/home/e2ef/.gnupg/" + str(pid) + str(tails[i]) + "b.enc", "r")
        text = f.read()
        body = str(text.partition("-----")[2])
        f.close()
        if len(tails[:-1]) >= 2:
		increment = " (PART " + str(i+1) + " of " + str(len(tails[:-1])) + ")"
        os.popen("echo \"" + subject[0:] + " ##TAIL##" + increment + "\n\n-----" + body + "\" | curl --retry 5 --url ##SMPT## --mail-from ##SEMAIL## --mail-rcpt ##REMAIL## --user ##SEMAIL##:##SPASS## --ssl-reqd --silent --ciphers ECDHE-RSA-AES128-GCM-SHA256 -T -")
    try:
         os.remove(pid_file)
    except:
         pass
