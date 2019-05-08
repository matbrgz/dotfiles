#!/bin/bash
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
      set +e
else
      set -e
fi
APACHE_VERSION="$(jq -r '.APACHE_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
      sudo apt -y purge apache"${APACHE_VERSION}"*
fi
echo " [ DOING ] Apache: Default Dev folder as initial directory on localhost"
port="$(jq -r '.programs[] | select(.program=="apache").port' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
defaultfolder="$(jq -r '.personal.defaultfolder' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
sudo rm -f /etc/apache"${APACHE_VERSION}"/sites-available/000-default.conf
sudo echo "<VirtualHost *:${port}>
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