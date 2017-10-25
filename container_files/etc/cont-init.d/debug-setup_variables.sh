#!/usr/bin/with-contenv /bin/sh
echo "Debug Variables Setup File"

# cd /tmp
# if [ -d /var/www/html/wordpress/wp-content ]; then
# 	echo "wp-content directory found, not overwriting";
# else
# 	echo "wp-content directory not found, downloading";
# 	wget https://wordpress.org/latest.tar.gz; tar -xzf latest.tar.gz; cp -r wordpress/w-content/ /var/www/html/wordpress/wp-content; rm -r wordpress; rm latest.tar.gz;
# fi

# Make sure that apache has write permissions
# echo "Variables not yet set"

# if [ -z "$MYSQL_ROOT_PASSWORD_ENV" ]; then
#     echo "MYSQL_ROOT_PASSWORD_ENV not set, defaulting"
#     MYSQL_ROOT_PASSWORD_ENV='root'
# else
#     echo "MYSQL_ROOT_PASSWORD_ENV set ignoring"
#     MYSQL_ROOT_PASSWORD_ENV=${FSTYPE}
# fi
#  # MYSQL_ROOT_PASSWORD_ENV=${MYSQL_ROOT_PASSWORD_ENV:=root}
#  MYSQL_DATABASE_ENV=${MYSQL_DATABASE_ENV:=wordpress}
#  MYSQL_USER_ENV=${MYSQL_USER_ENV:=froot}
#  MYSQL_PASSWORD_ENV=${MYSQL_PASSWORD_ENV:=froot}
#  DATABASE_PREFIX_ENV=${DATABASE_PREFIX_ENV:=wp_}

#  echo $MYSQL_DATABASE_ENV