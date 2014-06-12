class commontools {
	
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

	package { 'epel-release':
		source => "http://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm",
		ensure => installed,
		provider => rpm,
		require => Exec[ 'selinux-off-2' ],
	}

	package { 'remi-release':
		source => "http://rpms.famillecollet.com/enterprise/remi-release-5.rpm",
		ensure => installed,
		provider => rpm,
		require => Package[ 'epel-release' ],
	}

	package { 'ius':
		source => "http://dl.iuscommunity.org/pub/ius/stable/CentOS/5/x86_64/ius-release-1.0-11.ius.centos5.noarch.rpm",
		ensure => installed,
		provider => rpm,
		require => Package[ 'epel-release' ],
	}

	$commonTools = [ 'screen', 'vim-enhanced', 'nano', 'git' ]
	package { $commonTools:
		ensure => installed,
		require => Package[ 'ius' ],
	}

	exec { 'selinux-off-1': 
		command => "sed -i 's/^SELINUX=.*$/SELINUX=disabled/g' /etc/selinux/config",
		onlyif => "echo '! grep -E \"^SELINUX=disabled$\" < /etc/selinux/config > /dev/null' | bash",
	}

	exec { 'selinux-off-2': 
		command => "setenforce 0",
		onlyif => "sestatus |grep -E \"enforcing\" > /dev/null",
	} 

	$firewall = [ 'iptables', 'ip6tables' ]
	service { $firewall:
		ensure => stopped,
		enable => false,
	}

}