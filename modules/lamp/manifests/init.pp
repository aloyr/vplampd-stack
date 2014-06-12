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
					 'php55u-pecl-apc',
					 'php55u-pecl-imagick',
					 'php55u-pecl-memcache',
					 'php55u-pecl-redis',
					 'php55u-pecl-xdebug',
					 'php55u-process',
					 'php55u-xml',
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

		$webservicesreq = defined('$webrootparsed') ? {
			true => [ 'selinux-off-2', 'reset_webroot' ],
			false => 'selinux-off-2',
		}
		service { 'httpd':
			ensure => running,
			enable => true,
			require => [ Exec [ $webservicesreq ], Package [ $web ] ],
		}

		service { $dbservice:
			ensure => running,
			enable => true,
			require => [ Exec [ 'selinux-off-2' ], Package [ $database ] ],
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
