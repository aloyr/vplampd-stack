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
			command => "sed -i \\
						    -e 's/^\\(allow_url_fopen\\) = Off/\\1 = On/g' \\
						    -e 's/^; \\(date.timezone\\) =.*/\\1 = America\\/Chicago/g' \\
						    -e 's/^\\(display.*_errors\\) = Off/\\1 = On/g' \\
						    -e 's/^\\(error_reporting\\) = .*/\\1 = E_ALL | E_STRICT/g' \\
						    -e 's/^\\(html_errors\\) = Off/\\1 = On/g' \\
						    -e 's/^\\(log_errors\\) = Off/\\1 = On/g' \\
						    -e 's/^\\(memory_limit\\) = [0-9]+M/\\1 = 2048M/g' \\
						    -e 's/^\\(post_max_size\\) = [0-9]\\+M/\\1 = 80M/g' \\
						    -e 's/^\\(track_errors\\) = Off/\\1 = On/g' \\
						    -e 's/^\\(upload_max_filesize\\) = [0-9]\\+M/\\1 = 20M/g' \\
						    /etc/php.ini",
			unless => 'grep "allow_url_fopen = On" /etc/php.ini',
			require => Package [ $web ],
		}

		exec { 'apc_ini':
			command => "sed -i \\
						    -e 's/^;\\(apc.enabled\\)=.*/\\1=1/g' \\
						    -e 's/^;\\(apc.shm_size\\)=.*/\\1=256M/g' \\
						    /etc/php.d/apc.ini",
			unless => 'grep "^apc.enabled=1" /etc/php.d/apc.ini',
			require => Package [ $web ],
		}

		commontools::yumgroup { '"Development Tools"':
			ensure => installed,
			require => Exec [ 'selinux-off-2' ],
		} ~>
		exec { 'xhprof_setup':
			command => 'pecl install xhprof-beta ; echo "extension=xhprof.so" > /etc/php.d/xhprof.ini',
			creates => '/etc/php.d/xhprof.ini',
		}

		exec { 'xdebug_setup': 
			command => 'echo "xdebug.remote_enable=1" >> /etc/php.d/xdebug.ini ; \
						echo "xdebug.remote_connect_back=1" >> /etc/php.d/xdebug.ini ; \
						echo "xdebug.remote_port=9000" >> /etc/php.d/xdebug.ini ; \
						echo "xdebug.remote_autostart=1" >> /etc/php.d/xdebug.ini',
			unless => 'grep "remote_enable" /etc/php.d/xdebug.ini',
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
			require => [ Exec [ $webservicesreq, php_ini, apc_ini ], Package [ $web ] ],
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
						exec { 'setup_languages':
							command => insertlanguages(),
							creates => '/vagrant/data/insertlanguages.sql',
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
		
	}

}
