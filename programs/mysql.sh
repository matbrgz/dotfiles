#!/bin/bash
PREVIOUS_PWD="$1"
MYSQL_SRV_VERSION="$(jq -r '.MYSQL_SRV_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	set +e
else
	set -e
fi
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	sudo apt -y purge mysql-server mysql-client
fi
echo "mysql-server-${MYSQL_SRV_VERSION} mysql-server/root_password password root" | sudo debconf-set-selections
echo "mysql-server-${MYSQL_SRV_VERSION} mysql-server/root_password_again password root" | sudo debconf-set-selections
#RUN DEBIAN_FRONTEND=noninteractive
sudo apt -y install mysql-server-"${MYSQL_SRV_VERSION}" mysql-client
sudo usermod -d /var/lib/mysql/ mysql
#echo -e "root\nn\nY\nY\nY\nY\n" | mysql_secure_installation
mysql_secure_installation

sed -i 's/127\.0\.0\.1/0\.0\.0\.0/g' /etc/mysql/my.cnf
mysql -uroot -p -e "USE mysql; UPDATE `user` SET `Host`=\"%\" WHERE `User`=\"root\" AND `Host`=\"localhost\"; DELETE FROM `user` WHERE `Host` != \"%\" AND `User`=\"root\"; FLUSH PRIVILEGES;"

sudo /etc/init.d/mysql restart || sudo /etc/init.d/mysql start

dpkg --get-selections | grep mysql
