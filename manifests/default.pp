Exec {
	path => '/usr/bin:/usr/sbin:/bin:/sbin',
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

$web = [ 'php53u', 'php53u-process', 'php53u-pdo', 'php53u-mysql', 'httpd', 'php53u-pecl-imagick' ]
package { $web:
	ensure => installed,
	require => Package[ 'ius-release-1.0-11.ius.centos5' ],
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
	require => Exec [ 'selinux-off-2' ],
}

service { 'mysql51-mysqld':
	ensure => running,
	enable => true,
	require => Exec [ 'selinux-off-2' ],
}