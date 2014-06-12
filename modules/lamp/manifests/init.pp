class lamp {

	if $operatingsystem == 'CentOS' {
		case $operatingsystemmajversion {
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
					 'phpc55u',
					 'phpc55u-cli',
					 'phpc55u-gd',
					 'phpc55u-odbc',
					 'phpc55u-pdo',
					 'phpc55u-pear',
					 'phpc55u-pecl-apc',
					 'phpc55u-pecl-imagick',
					 'phpc55u-pecl-memcache',
					 'phpc55u-pecl-redis',
					 'phpc55u-pecl-xdebug',
					 'phpc55u-process',
					 'phpc55u-xml',
					 'redis',
					 'varnish',
				   ]
				$database = [ 'MariaDB-server', 'MariaDB-client' ]
				$dbservice = 'mysqld'
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

		package { $database:
			ensure => installed,
			require => Package[ $web ],
		}

		service { 'httpd':
			ensure => running,
			enable => true,
			require => [ Exec [ 'selinux-off-2', 'reset_webroot' ], Package [ $web ] ],
		}

		service { $dbservice:
			ensure => running,
			enable => true,
			require => [ Exec [ 'selinux-off-2' ], Package [ $database ] ],
		}

		if defined($webrootparsed) {
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
