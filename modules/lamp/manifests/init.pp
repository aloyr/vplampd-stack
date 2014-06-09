class lamp {

	define yumgroup($ensure = "present", $optional = false) {
	   case $ensure {
	      present,installed: {
	         $pkg_types_arg = $optional ? {
	            true => "--setopt=group_package_types=optional,default,mandatory",
	            default => ""
	         }
	         exec { "Installing $name yum group":
	            command => "yum -y groupinstall $pkg_types_arg $name",
	            # unless => "yum -y groupinstall $pkg_types_arg $name --downloadonly",
	            onlyif => "echo '! yum grouplist $name | grep -E \"^Installed\" > /dev/null' |bash",
	            timeout => 600,
	         }
	      }
	   }
	}

	file { 'adjust_timezone':
		replace => yes,
		source => "/usr/share/zoneinfo/$zonefile",
		path => "/etc/localtime",
	}

	package { 'epel-release-5-4':
		source => "http://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm",
		ensure => installed,
		provider => rpm,
		require => Exec[ 'selinux-off-2' ],
	}

	package { 'remi-release-5.10-1.el5.remi':
		source => "http://rpms.famillecollet.com/enterprise/remi-release-5.rpm",
		ensure => installed,
		provider => rpm,
		require => Package[ 'epel-release-5-4' ],
	}

	package { 'ius-release-1.0-11.ius.centos5':
		source => "http://dl.iuscommunity.org/pub/ius/stable/CentOS/5/x86_64/ius-release-1.0-11.ius.centos5.noarch.rpm",
		ensure => installed,
		provider => rpm,
		require => Package[ 'epel-release-5-4' ],
	}

	$commonTools = [ 'screen', 'vim-enhanced', 'git' ]
	package { $commonTools:
		ensure => installed,
		require => Package[ 'ius-release-1.0-11.ius.centos5' ],
	}

	$web = [ 'httpd',
			 'php53u',
			 'php53u-mysql',
			 'php53u-pdo',
			 'php53u-pear',
			 'php53u-pecl-apc',
			 'php53u-pecl-imagick',
			 'php53u-pecl-memcache',
			 'php53u-pecl-redis',
			 'php53u-pecl-xdebug',
			 'php53u-process',
		   ]
	package { $web:
		ensure => installed,
		require => Package[ 'ius-release-1.0-11.ius.centos5' ],
	}

	exec { 'php_ini':
		command => "sed -i 's/allow_url_fopen = Off/allow_url_fopen = On/g' /etc/php.ini",
		unless => 'grep "allow_url_fopen = On" /etc/php.ini',
		require => Package [ $web ],
	}

	$database = [ 'mysql51-mysql-server', 'mysql51-mysql' ]
	package { $database:
		ensure => installed,
		require => Package[ $web ],
	}

	exec { 'selinux-off-1': 
		command => "sed -i 's/^SELINUX=.*$/SELINUX=disabled/g' /etc/selinux/config",
		onlyif => "echo '! grep -E \"^SELINUX=disabled$\" < /etc/selinux/config > /dev/null' | bash",
	}

	exec { 'selinux-off-2': 
		command => "setenforce 0",
		onlyif => "sestatus |grep -E \"enforcing\" > /dev/null",
	}

	service { 'httpd':
		ensure => running,
		enable => true,
		require => [ Exec [ 'selinux-off-2', 'reset_webroot' ], Package [ $web ] ],
	}

	service { 'mysql51-mysqld':
		ensure => running,
		enable => true,
		require => [ Exec [ 'selinux-off-2' ], Package [ $database ] ],
	}

	$firewall = [ 'iptables', 'ip6tables' ]
	service { $firewall:
		ensure => stopped,
		enable => false,
	}

	exec { 'reset_webroot':
		command => "sed -i 's/\\/var\\/www\\/html/$webrootparsed/g' /etc/httpd/conf/httpd.conf",
		onlyif => "grep '/var/www/html'  /etc/httpd/conf/httpd.conf",
		require => Package [ 'httpd' ],
	}

	# yumgroup { '"Development Tools"':
	# 	ensure => installed,
	# 	require => Exec [ 'selinux-off-2' ],
	# }

}