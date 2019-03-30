#!/bin/bash -e
printf " [ START ] Apache \n"
starttime=$(date +%s)
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
APACHE_VERSION="$(jq -r '.APACHE_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
if [ "$(jq -r '.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
	sudo apt -y purge apache"${APACHE_VERSION}"*
fi
sudo apt -y install apache"${APACHE_VERSION}"
dpkg --get-selections | grep apache
printf " [ START ] Apache Default Configuration \n"
#Config for Dev folder
starttime=$(date +%s)
echo " [ DOING ] Apache: Default Dev folder as initial directory on localhost"
defaultfolder="$(jq -r '.defaultfolder' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
sudo rm -f /etc/apache"${APACHE_VERSION}"/sites-available/000-default.conf
sudo echo "<VirtualHost *:80>
     ServerAdmin webmaster@localhost
     DocumentRoot ${defaultfolder}

     <Directory ${defaultfolder}>
           Options Indexes FollowSymLinks MultiViews
           AllowOverride All
           Require all granted
     </Directory>

     #LogLevel info ssl:warn
     ErrorLog ${APACHE_LOG_DIR}/error.log
     CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>" | sudo tee -a /etc/apache"${APACHE_VERSION}"/sites-available/000-default.conf
sudo /etc/init.d/apache"${APACHE_VERSION}" stop
echo " [ DOING ] Apache: Allowing mod rewrite rules"
sudo a2enmod rewrite
sudo /etc/init.d/apache"${APACHE_VERSION}" start
echo " [ DOING ] Apache: Allow autoindex for editing apache directory listing"
sudo a2enmod autoindex
endtime=$(date +%s)
printf " [ DONE ] Apache Default Configuration ... %s seconds \n" "$((endtime-starttime))"
endtime=$(date +%s)
printf " [ DONE ] Apache ... %s seconds \n" "$((endtime-starttime))"
