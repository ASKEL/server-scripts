#!/bin/bash
 
# default settings
TIMEZONE='Europe/Moscow'
MYSQLPASS=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12`
SFTPPASS=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12`
PASSWORD=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12`
##############

echo "Enter MySql root pass:"
read ROOTPASS
 
echo "Enter username for site and database:"
read USERNAME
 
echo "Enter domain"
read DOMAIN
 
##############
 
echo "Creating user and home directory..."
useradd $USERNAME -m -G sftp -s "/bin/false" -d "/var/www/$USERNAME"
if [ "$?" -ne 0 ]; then
	echo "Can't add user"
	exit 1
fi
echo $SFTPPASS > ./tmp
echo $SFTPPASS >> ./tmp
cat ./tmp | passwd $USERNAME
rm ./tmp
 
##############
 
mkdir /var/www/$USERNAME/www
mkdir /var/www/$USERNAME/tmp
mkdir /var/www/$USERNAME/log
chmod -R 755 /var/www/$USERNAME/
chown -R $USERNAME:$USERNAME /var/www/$USERNAME/
chown root:root /var/www/$USERNAME
 
echo "Creating vhost file"
echo "upstream backend-$USERNAME {server unix:/var/run/php5-$USERNAME.sock;}
 
server {
	listen				80;
	server_name			$DOMAIN www.$DOMAIN;
	root				/var/www/$USERNAME/www;
	access_log			/var/www/$USERNAME/log/access.log;
	error_log			/var/www/$USERNAME/log/error.log;
	index				index.php index.html;
	rewrite_log			on;
	if (\$host != '$DOMAIN' ) {
		rewrite			^/(.*)$  http://$DOMAIN/\$1  permanent;
	}
	location ~* ^/core/ {
		deny			all;
	}
	location / {
		try_files		\$uri \$uri/ @rewrite;
	}
	location /index.html {
		rewrite			/ / permanent;
	}
 
	location ~ ^/(.*?)/index\.html$ {
		rewrite			^/(.*?)/ /$1/ permanent;
	}
	location @rewrite {
		rewrite			^/(.*)$ /index.php?q=\$1;
	}
	location ~ \.php$ {
		include			fastcgi_params;
		fastcgi_param	SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
		fastcgi_pass	backend-$USERNAME;
	}
	location ~* ^.+\.(jpg|jpeg|gif|css|png|js|ico|bmp)$ {
	   access_log		off;
	   expires			10d;
	   break;
	}
	location ~ /\.ht {
		deny			all;
	}
}
" > /etc/nginx/sites-available/$USERNAME.conf
ln -s /etc/nginx/sites-available/$USERNAME.conf /etc/nginx/sites-enabled/$USERNAME.conf
 
##############
echo "Creating php5-fpm config"
 
echo "[$USERNAME]
 
listen = /var/run/php5-$USERNAME.sock
listen.mode = 0666
user = $USERNAME
group = $USERNAME
chdir = /var/www/$USERNAME
 
php_admin_value[upload_tmp_dir] = /var/www/$USERNAME/tmp
php_admin_value[soap.wsdl_cache_dir] = /var/www/$USERNAME/tmp
php_admin_value[upload_max_filesize] = 100M
php_admin_value[post_max_size] = 100M
php_admin_value[open_basedir] = /var/www/$USERNAME/
php_admin_value[disable_functions] = exec,passthru,shell_exec,system,proc_open,popen,curl_multi_exec,parse_ini_file,show_source,stream_socket_client,stream_set_write_buffer,stream_socket_sendto,highlight_file,com_load_typelib
php_admin_value[cgi.fix_pathinfo] = 0
php_admin_value[date.timezone] = $TIMEZONE
php_admin_value[session.gc_probability] = 1
php_admin_value[session.gc_divisor] = 100
 
 
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 2
pm.max_spare_servers = 4
" > /etc/php5/fpm/pool.d/$USERNAME.conf
 
#############
 
echo "Reloading nginx"
service nginx reload
echo "Reloading php5-fpm"
service php5-fpm reload
 
##############
 
echo "Creating database"
 
Q1="CREATE DATABASE IF NOT EXISTS $USERNAME DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;;"
Q2="GRANT ALTER,DELETE,DROP,CREATE,INDEX,INSERT,SELECT,UPDATE,CREATE TEMPORARY TABLES,LOCK TABLES ON $USERNAME.* TO '$USERNAME'@'localhost' IDENTIFIED BY '$MYSQLPASS';"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"
 
mysql -uroot --password=$ROOTPASS -e "$SQL"
 
##############
 
echo "#!/bin/bash
 
echo \"Set permissions for /var/www/$USERNAME/www...\";
echo \"CHOWN files...\";
chown -R $USERNAME:$USERNAME \"/var/www/$USERNAME/www\";
echo \"CHMOD directories...\";
find \"/var/www/$USERNAME/www\" -type d -exec chmod 0755 '{}' \;
echo \"CHMOD files...\";
find \"/var/www/$USERNAME/www\" -type f -exec chmod 0644 '{}' \;
" > /var/www/$USERNAME/chmod
chmod +x /var/www/$USERNAME/chmod
 
echo "Done!
Manager user: $USERNAME
Manager password: $PASSWORD
SFTP password: $SFTPPASS
MySql user: $USERNAME
MySql database: $USERNAME
MySql password: $MYSQLPASS" > /var/www/$USERNAME/pass.txt
 
cat /var/www/$USERNAME/pass.txt