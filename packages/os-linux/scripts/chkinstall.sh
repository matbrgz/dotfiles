#!/bin/bash
dpkg -s $1 &> /dev/null
if [ $? -eq 0 ]; then
    printf "\n Package $1 is installed"
else
    printf "\n Package $1 was NOT installed!"
fi