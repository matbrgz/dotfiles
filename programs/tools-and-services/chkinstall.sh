#!/bin/bash
lj --file /usr/local/var/log/chkinstall.log --level critical
dpkg -s $1 &> /dev/null
if [ $? -eq 0 ]; then
    lt "Package $1 is installed"
else
    lj critical "Package $1 was NOT installed!"
fi