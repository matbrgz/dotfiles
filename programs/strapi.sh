printf " [ START ] Node Version Management \n"
starttime=$(date +%s)
npm install strapi@alpha -g
endtime=$(date +%s)
printf " [ DONE ] Node Version Management ... %s seconds \n" "$((endtime-starttime))"