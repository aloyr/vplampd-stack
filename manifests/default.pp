Exec {
	path => '/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin',
}

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

define filehttp($ensure = "present", $mode = 0755, $source = "/dev/null") {
	case $ensure {
		present,installed: {
			exec { "Downloading $name":
				command => "wget --no-check-certificate -O $name -q $source",
				creates => $name,
				timeout => 600,
			}
			if $source != "/dev/null" {
				file { $name:
					mode => $mode,
					require => Exec [ "Downloading $name" ],
				}
			}
		}
	}
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
	require => [ Exec [ 'selinux-off-2' ], Package [ $web ] ],
}

service { 'mysql51-mysqld':
	ensure => running,
	enable => true,
	require => [ Exec [ 'selinux-off-2' ], Package [ $database ] ],
}

yumgroup { '"Development Tools"':
	ensure => installed,
	require => Exec [ 'selinux-off-2' ],
}

file { '/opt/local':
	ensure => 'directory',
}

exec { 'composer':
	command => 'curl -sS https://getcomposer.org/installer \
			   | sudo php -d allow_url_fopen=On -- --filename=composer --install-dir=/usr/local/bin',
	creates => '/usr/local/bin/composer',
	require => [ Exec [ 'php_ini' ], Package [ $web ], ],
}

exec { 'pear_Console_Table':
	command => 'pear install Console_Table',
	unless => 'pear list | grep Console_Table > /dev/null',
	require => [ Exec [ 'php_ini' ], Package [ $web ], ],
}

exec { 'drush':
	command => 'git clone -b 5.x https://github.com/drush-ops/drush.git /opt/local/drush',
	creates => '/opt/local/drush',
	require => [ Exec [ 'composer', 'pear_Console_Table' ], Package [ $commonTools ], ],
}

file { '/usr/local/bin/drush':
	ensure => link,
	target => '/opt/local/drush/drush',
	require => Exec [ 'drush' ],
}