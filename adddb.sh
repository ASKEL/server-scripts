#!/bin/bash
 
# default settings
MYSQLPASS=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12`
##############

echo "Enter MySql root pass:"
read ROOTPASS
 
echo "Enter username for site and database:"
read USERNAME
 
#############
 
echo "Creating database"
 
Q1="CREATE DATABASE IF NOT EXISTS $USERNAME DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;;"
Q2="GRANT ALTER,DELETE,DROP,CREATE,INDEX,INSERT,SELECT,UPDATE,CREATE TEMPORARY TABLES,LOCK TABLES ON $USERNAME.* TO '$USERNAME'@'localhost' IDENTIFIED BY '$MYSQLPASS';"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"
 
mysql -uroot --password=$ROOTPASS -e "$SQL"
 
##############
 
echo "#!/bin/bash
 
echo "Done!
MySql user: $USERNAME
MySql database: $USERNAME
MySql password: $MYSQLPASS" > /var/www/$USERNAME/pass-db.txt
 
cat /var/www/$USERNAME/pass-db.txt