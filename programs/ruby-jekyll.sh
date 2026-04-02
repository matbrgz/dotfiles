#!/bin/bash -e
printf " [ START ] Jekyll  \n"
starttime=$(date +%s)
gem install jekyll bundler
echo "alias jstart=\"bundle exec jekyll serve --watch\"" >> "${HOME}"/.bash_aliases
endtime=$(date +%s)
printf " [ DONE ] Jekyll ... %s seconds \n" "$((endtime-starttime))"
