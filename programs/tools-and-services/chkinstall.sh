#!/bin/bash
lj --file /usr/local/var/log/chkinstall.log --level critical
dpkg -s $1 &> /dev/null
if [ $? -eq 0 ]; then
    lt "Package  is installed"
else
    lj critical "Package  was NOT installed!"
fi