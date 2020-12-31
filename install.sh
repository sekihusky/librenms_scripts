#install Librenms on Ubuntu20.04

#get ip
sudo apt install -y net-tools git
ip=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.2.0.1'`
#install packages
apt install software-properties-common -y
add-apt-repository universe -y
apt update -y
apt install -y acl curl composer fping git graphviz imagemagick mariadb-client mariadb-server mtr-tiny nginx-full nmap php7.4-cli php7.4-curl php7.4-fpm php7.4-gd php7.4-json php7.4-mbstring php7.4-mysql php7.4-snmp php7.4-xml php7.4-zip rrdtool snmp snmpd whois unzip python3-pymysql python3-dotenv python3-redis python3-setuptools
 
#adduser 
useradd librenms -d /opt/librenms -M -r
usermod -a -G librenms www-data

#download LibreNMS
cd /opt
git clone https://github.com/librenms/librenms.git librenms

#DataBase(default password My_password)
systemctl restart mysql
mysql -uroot <<EOF
	CREATE DATABASE librenms CHARACTER SET utf8 COLLATE utf8_unicode_ci;
	CREATE USER 'librenms'@'localhost' IDENTIFIED BY 'My_password';
	GRANT ALL PRIVILEGES ON librenms.* TO 'librenms'@'localhost';
	FLUSH PRIVILEGES;
	exit
EOF

> /etc/mysql/mariadb.conf.d/50-server.cnf
echo [server] >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo [mysqld] >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo innodb_file_per_table=1 >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo sql-mode=\"\" >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo lower_case_table_names=0 >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo user            = mysql >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo pid-file        = /var/run/mysqld/mysqld.pid >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo socket          = /var/run/mysqld/mysqld.sock >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo port            = 3306 >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo basedir         = /usr >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo datadir         = /var/lib/mysql >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo tmpdir          = /tmp >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo lc-messages-dir = /usr/share/mysql >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo skip-external-locking >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo bind-address            = 127.2.0.1 >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo key_buffer_size         = 16M >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo max_allowed_packet      = 16M >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo thread_stack            = 192K >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo thread_cache_size       = 8 >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo myisam-recover         = BACKUP >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo query_cache_limit       = 1M >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo query_cache_size        = 16M >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo log_error = /var/log/mysql/error.log >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo expire_logs_days        = 10 >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo max_binlog_size   = 100M >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo character-set-server  = utf8mb4 >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo collation-server      = utf8mb4_general_ci >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo [embedded] >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo [mariadb] >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo [mariadb-10.0] >> /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl enable mysql
systemctl restart mysql


#Timezone and PHP
timedatectl set-timezone "Asia/Taipei"
echo date.timezone = \"Asia/Taipei\" >> /etc/php/7.4/fpm/php.ini
echo date.timezone = \"Asia/Taipei\" >> /etc/php/7.4/cli/php.ini

systemctl restart php7.4-fpm
systemctl enable php7.4-fpm

#NGINX
echo		server {	 >> /etc/nginx/conf.d/librenms.conf
echo		 listen      80\;	 >> /etc/nginx/conf.d/librenms.conf
echo		 server_name $ip\; 	 >> /etc/nginx/conf.d/librenms.conf
echo		 root        \/opt\/librenms\/html\;	 >> /etc/nginx/conf.d/librenms.conf
echo		 index       index.php\;	 >> /etc/nginx/conf.d/librenms.conf
echo			 >> /etc/nginx/conf.d/librenms.conf
echo		 charset utf-8\;	 >> /etc/nginx/conf.d/librenms.conf
echo		 gzip on\;	 >> /etc/nginx/conf.d/librenms.conf
echo		 gzip_types text\/css application\/javascript text\/javascript application\/x-javascript image\/svg+xml text\/plain text\/xsd text\/xsl text\/xml image\/x-icon\;	 >> /etc/nginx/conf.d/librenms.conf
echo		 location \/ {	 >> /etc/nginx/conf.d/librenms.conf
echo		  try_files \$uri \$uri\/ \/index.php?\$query_string\;	 >> /etc/nginx/conf.d/librenms.conf
echo		 }	 >> /etc/nginx/conf.d/librenms.conf
echo		 location \/api\/v0 {	 >> /etc/nginx/conf.d/librenms.conf
echo		  try_files \$uri \$uri\/ \/api_v0.php?\$query_string\;	 >> /etc/nginx/conf.d/librenms.conf
echo		 }	 >> /etc/nginx/conf.d/librenms.conf
echo		 location \~ \\.php {	 >> /etc/nginx/conf.d/librenms.conf
echo		  include fastcgi.conf\;	 >> /etc/nginx/conf.d/librenms.conf
echo		  fastcgi_split_path_info \^\(.+\\.php\)\(\/.+\)\$\;	 >> /etc/nginx/conf.d/librenms.conf
echo		  fastcgi_pass unix:\/var\/run\/php\/php7.4-fpm.sock\;	 >> /etc/nginx/conf.d/librenms.conf
echo		 }	 >> /etc/nginx/conf.d/librenms.conf
echo		 location \~ \/\\.ht {	 >> /etc/nginx/conf.d/librenms.conf
echo		  deny all\;	 >> /etc/nginx/conf.d/librenms.conf
echo		 }	 >> /etc/nginx/conf.d/librenms.conf
echo		}	 >> /etc/nginx/conf.d/librenms.conf
rm /etc/nginx/sites-enabled/default
systemctl restart nginx
systemctl enable nginx

#setup snmpd
cp /opt/librenms/snmpd.conf.example /etc/snmp/snmpd.conf
sed -e 's/RANDOMSTRINGGOESHERE/public/' -i /etc/snmp/snmpd.conf
curl -o /usr/bin/distro https://raw.githubusercontent.com/librenms/librenms-agent/master/snmp/distro
chmod +x /usr/bin/distro
systemctl restart snmpd
#cron
cp /opt/librenms/librenms.nonroot.cron /etc/cron.d/librenms
#logrotate logs
cp /opt/librenms/misc/librenms.logrotate /etc/logrotate.d/librenms

#LibreNMS setups
chown -R librenms:librenms /opt/librenms
setfacl -d -m g::rwx /opt/librenms/rrd /opt/librenms/logs /opt/librenms/bootstrap/cache/ /opt/librenms/storage/
setfacl -R -m g::rwx /opt/librenms/rrd /opt/librenms/logs /opt/librenms/bootstrap/cache/ /opt/librenms/storage/
cd /opt/librenms
su - librenms <<EOF
./scripts/composer_wrapper.php install --no-dev
exit;
EOF
chown -R librenms:librenms /opt/librenms
setfacl -d -m g::rwx /opt/librenms/rrd /opt/librenms/logs /opt/librenms/bootstrap/cache/ /opt/librenms/storage/
setfacl -R -m g::rwx /opt/librenms/rrd /opt/librenms/logs /opt/librenms/bootstrap/cache/ /opt/librenms/storage/


#clear
echo "all done ! defatul DB password is My_password, start install from here: http://"$ip