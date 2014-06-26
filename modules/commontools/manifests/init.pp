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

	if $operatingsystem == "CentOS" {
		case $operatingsystemmajrelease {
			5: {
				$epel_package = "epel-release-5-4"
				$epel_source = "http://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm"
				$remi_package = "remi-release-5.10-1.el5.remi"
				$remi_source = "http://rpms.famillecollet.com/enterprise/remi-release-5.rpm"
				$ius_package = "ius-release-1.0-11.ius.centos5"
				$ius_source = "http://dl.iuscommunity.org/pub/ius/stable/CentOS/5/x86_64/ius-release-1.0-11.ius.centos5.noarch.rpm"
			}
			6: {
				$epel_package = "epel-release-6-8"
				$epel_source = "http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm"
				$remi_package = "remi-release-6.5-1.el6.remi"
				$remi_source = "http://rpms.famillecollet.com/enterprise/remi-release-6.rpm"
				$ius_package = "ius-release-1.0-11.ius.centos6"
				$ius_source = "http://dl.iuscommunity.org/pub/ius/stable/CentOS/6/x86_64/ius-release-1.0-11.ius.centos6.noarch.rpm"
				exec { 'import_mariadb_rpm':
					command => "rpm --import https://yum.mariadb.org/RPM-GPG-KEY-MariaDB",
					unless => 'rpm -qi gpg-pubkey-1bb943db-511147a9 > /dev/null'
				}
				exec { 'mariadb_repo':
					command => 'echo "[mariadb]" > /etc/yum.repos.d/MariaDB.repo \
								&& echo "name = MariaDB" >> /etc/yum.repos.d/MariaDB.repo \
								&& echo "baseurl = http://yum.mariadb.org/5.5/centos5-x86" >> /etc/yum.repos.d/MariaDB.repo \
								&& echo "gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB" >> /etc/yum.repos.d/MariaDB.repo \
								&& echo "gpgcheck=1" >> /etc/yum.repos.d/MariaDB.repo',
					creates => '/etc/yum.repos.d/MariaDB.repo'
				}
			}
		}
	}

	file { 'adjust_timezone':
		replace => yes,
		source => "/usr/share/zoneinfo/$zonefile",
		path => "/etc/localtime",
	}

	package { $epel_package:
		source => $epel_source,
		ensure => installed,
		provider => rpm,
		require => Exec[ 'selinux-off-2' ],
	}

	package { $remi_package:
		source => $remi_source,
		ensure => installed,
		provider => rpm,
		require => Package[ $epel_package ],
	}

	package { $ius_package:
		source => $ius_source,
		ensure => installed,
		provider => rpm,
		require => Package[ $epel_package ],
	}

	$commonTools = [ 'screen', 'vim-enhanced', 'nano', 'git', 'updatedb', 'which', 'ssmtp', 'yum-utils' ]
	package { $commonTools:
		ensure => installed,
		require => Package[ $ius_package ],
	}

	exec { 'selinux-off-1': 
		command => "sed -i 's/^SELINUX=.*$/SELINUX=disabled/g' /etc/selinux/config",
		onlyif => "echo '! grep -E \"^SELINUX=disabled$\" < /etc/selinux/config > /dev/null' | bash",
	}

	exec { 'selinux-off-2': 
		command => "setenforce 0",
		onlyif => "sestatus |grep -E \"enforcing\" > /dev/null",
	} 

	if defined('$vagrant') {
		$firewall = [ 'iptables', 'ip6tables' ]
		service { $firewall:
			ensure => stopped,
			enable => false,
		}
	}
}