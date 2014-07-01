class lamp {

	if $operatingsystem == 'CentOS' {
		$pear = $operatingsystemmajrelease ? {
			'5' => 'php53u-pear',
			'6' => 'php55u-pear',
		}
		case $operatingsystemmajrelease {
			5: {
				$web = [ 'httpd',
					 'memcached',
					 'php53u',
					 'php53u-cli',
					 'php53u-gd',
					 'php53u-mysql',
					 'php53u-odbc',
					 'php53u-pdo',
					 'php53u-pear',
					 'php53u-pecl-apc',
					 'php53u-pecl-imagick',
					 'php53u-pecl-memcache',
					 'php53u-pecl-redis',
					 'php53u-pecl-xdebug',
					 'php53u-process',
					 'php53u-xml',
					 'redis',
					 'varnish',
				   ]
				$database = [ 'mysql51-mysql-server', 'mysql51-mysql' ]
				$dbservice = 'mysql51-mysqld'
			}
			6: {
				$web = [ 'httpd',
					 'memcached',
					 'php55u',
					 'php55u-cli',
					 'php55u-gd',
					 'php55u-odbc',
					 'php55u-pdo',
					 'php55u-pear',
					 'php55u-pecl-apcu',
					 'php55u-pecl-imagick',
					 'php55u-pecl-jsonc',
					 'php55u-pecl-memcache',
					 'php55u-pecl-xdebug',
					 'php55u-process',
					 'php55u-xml',
					 'redis',
					 'varnish',
				   ]
				$database = [ 'MariaDB-server', 'MariaDB-client' ]
				$dbservice = 'mysql'
			}
		}
		package { $web:
			ensure => installed,
			require => Package[ $commontools::ius_package ],
		}

		exec { 'php_ini':
			command => "sed -i 's/allow_url_fopen = Off/allow_url_fopen = On/g' /etc/php.ini",
			unless => 'grep "allow_url_fopen = On" /etc/php.ini',
			require => Package [ $web ],
		}

		if $operatingsystemmajrelease == 6 {
			exec { 'install_redis_pecl':
				command => 'pecl install redis',
				creates => '/usr/lib64/php/modules/',
				require => Package [ $web ],
			} 
			exec { 'create_redis_ini':
				command => 'echo "extension=redis.so" > /etc/php.d/redis.ini',
				creates => '/etc/php.d/redis.ini',
				require => Exec [ 'install_redis_pecl' ],
			} 
		}

		package { $database:
			ensure => installed,
			require => Package[ $web ],
		}

		$webservicesreq = defined('$webrootparsed') ? {
			true => [ 'selinux-off-2', 'reset_webroot' ],
			false => 'selinux-off-2',
		}
		service { 'httpd':
			ensure => running,
			enable => true,
			require => [ Exec [ $webservicesreq ], Package [ $web ] ],
		}

		exec { 'memcached_config':
			command => "sed -i 's/CACHESIZE=\".*\"/CACHESIZE=\"512\"/g' /etc/sysconfig/memcached",
			unless => 'grep "CACHESIZE=\"512\"" /etc/sysconfig/memcached &> /dev/null',
			require => Service [ 'httpd' ],
	  }

		service { 'memcached':
			ensure => running,
			enable => true,
			require => Exec [ 'memcached_config' ],
		}

		service { $dbservice:
			ensure => running,
			enable => true,
			require => [ Exec [ 'selinux-off-2' ], Package [ $database ] ],
		}

		if defined('$dbname') {
			exec { 'setup_db':
				command => "echo 'create database $dbname' | mysql", 
				unless => 'echo "use hid"|mysql -BN 2> /dev/null',
				require => Service [ $dbservice ],
			}
			if defined('$dbuser') {
				exec { 'setup_dbuser': 
					command => "echo \"grant all on $dbname.* to $dbuser@localhost identified by '$dbpass'\"| mysql",
					unless => "echo \"select user from mysql.user where host = 'localhost' and user = 'hid'\"| \
					           mysql -BN -uroot| grep hid &> /dev/null ",
					require => Exec [ 'setup_db' ],
				}	
				if defined('$dbfile') {
					exec { 'setup_dbfile':
						command => "mysql $dbname < /vagrant/data/$dbfile",
						unless => "echo 'select name from users' | mysql hid &> /dev/null",
						require => Exec [ 'setup_dbuser' ],
					}
					if defined('$languages') {
						$cmd = insertlanguages()
						exec { 'setup_languages':
							command => "$cmd > /tmp/test.txt",
							# unless => "",
							require => Exec [ 'setup_dbfile' ],
						}
					}
				}
			}
		}

		if defined('$webrootparsed') {
			exec { 'reset_webroot':
				command => "sed -i 's/\\/var\\/www\\/html/$webrootparsed/g' /etc/httpd/conf/httpd.conf",
				onlyif => "grep '/var/www/html'  /etc/httpd/conf/httpd.conf",
				require => Package [ 'httpd' ],
			}
		}

		drush::filehttp { 'memcached-init':
			ensure => present,
			source => 'https://gist.github.com/lboynton/3775818/raw/09e8eb92fa837dcbca4ec658742788f8dba83364/memcached-init.sh',
			name => '/etc/init.d/memcached-init',	
			mode => 0755,
		}
		# yumgroup { '"Development Tools"':
		# 	ensure => installed,
		# 	require => Exec [ 'selinux-off-2' ],
		# }
		
	}

}
