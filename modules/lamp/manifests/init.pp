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
					 'php53u-devel',
					 'php53u-gd',
					 'php53u-mbstring',
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
				$dbcnf = '/opt/rh/mysql51/root/etc/my.cnf'
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
						    -e 's/^\\(memory_limit\\) = [0-9]\\+M/\\1 = 2048M/g' \\
						    -e 's/^\\(post_max_size\\) = [0-9]\\+M/\\1 = 80M/g' \\
						    -e 's/^\\(track_errors\\) = Off/\\1 = On/g' \\
						    -e 's/^\\(upload_max_filesize\\) = [0-9]\\+M/\\1 = 20M/g' \\
						    /etc/php.ini",
			unless => 'grep "^memory_limit = 2048M" /etc/php.ini',
			require => Package [ $web ],
		}

		exec { 'apc_ini_realpath':
			command => "echo 'apc.realpath_cache_size=256k' >> /etc/php.d/apc.ini; \\
			            echo 'apc.realpath_cache_ttl=86400' >> /etc/php.d/apc.ini;",
			unless => 'grep "realpath_cache" /etc/php.d/apc.ini',
			require => Exec [ 'apc_ini' ],
		}

		exec { 'apc_ini':
			command => "sed -i \\
						    -e 's/^;\\(apc.enabled\\)=.*/\\1=1/g' \\
						    -e 's/^;\\(apc.shm_size\\)=.*/\\1=256M/g' \\
						    /etc/php.d/apc.ini",
			unless => 'grep "^apc.enabled=1" /etc/php.d/apc.ini',
			require => [ Package [ $web ], Exec [ 'php_ini' ] ],
		}

		commontools::yumgroup { '"Development Tools"':
			ensure => installed,
			require => Exec [ 'selinux-off-2' ],
		} ~>
		exec { 'xhprof_setup':
			command => 'pecl install xhprof-beta ; echo "extension=xhprof.so" > /etc/php.d/xhprof.ini',
			creates => '/etc/php.d/xhprof.ini',
			require => Package [ $web ],
		}

		exec { 'xdebug_setup': 
			command => 'echo "xdebug.remote_enable=1" >> /etc/php.d/xdebug.ini ; \
						echo "xdebug.remote_connect_back=1" >> /etc/php.d/xdebug.ini ; \
						echo "xdebug.remote_port=9000" >> /etc/php.d/xdebug.ini ; \
						echo "xdebug.remote_autostart=1" >> /etc/php.d/xdebug.ini',
			unless => 'grep "remote_enable" /etc/php.d/xdebug.ini',
			require => Package [ $web ],
		}
		exec { 'uploadprogress_setup':
			command => 'pecl install uploadprogress ; echo "extension=uploadprogress.so" > /etc/php.d/uploadprogress.ini',
			creates => '/etc/php.d/uploadprogress.ini',
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

		file { 'mysql_folder':
			path => '/etc/mysql',
			ensure => directory,
			require => Package [ $database ],
		}
		file { 'mysql_optimizations':
			path => '/etc/mysql/mysql_optimizations.cnf',
			ensure => file,
			content => template('lamp/mysql_optimizations.erb'),
			require => File [ 'mysql_folder' ],
		} 
		exec { 'mysql_include':
			command => "echo '!includedir /etc/mysql' >> $dbcnf",
			unless => "grep 'includedir'  $dbcnf",
			require => File [ 'mysql_optimizations' ]
		}

		file { 'http_site':
			ensure => file,
			path => sprintf("/etc/httpd/conf.d/%s.conf", $webhost),
			content => template('lamp/apache_site.erb'),
			require => Package [ $web ],
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
			require => [ Exec [ 'selinux-off-2', 'mysql_include' ], Package [ $database ] ],
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
				exec { 'setup_dbuser_external': 
					command => "echo \"grant all on $dbname.* to $dbuser@\\`%\\` identified by '$dbpass'\"| mysql",
					unless => "echo \"select user from mysql.user where host = '%' and user = 'hid'\"| \
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
							require => Exec [ 'setup_dbfile' ],
						}
						file { 'lang_file': 
							path => '/vagrant/data/insertlanguages.sql',
							content => insertlanguages(),
							ensure => file,
							require => Exec [ 'setup_languages' ],
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

		drush::filehttp { 'tuning-primer.sh':
			ensure => present,
			source => 'https://launchpadlibrarian.net/78745738/tuning-primer.sh',
			name => '/usr/local/bin/tuning-primer.sh',	
			mode => 0755,
		}
		
	}

}
