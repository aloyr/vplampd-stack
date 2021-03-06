class commontools {	
	# define yumgroup($ensure = "present", $optional = false) {
	#    case $ensure {
	#       present,installed: {
	#          $pkg_types_arg = $optional ? {
	#             true => "--setopt=group_package_types=optional,default,mandatory",
	#             default => ""
	#          }
	#          exec { "Installing $name yum group":
	#             command => "yum -y groupinstall $pkg_types_arg $name",
	#             # unless => "yum -y groupinstall $pkg_types_arg $name --downloadonly",
	#             onlyif => "echo '! yum grouplist $name | grep -E \"^Installed\" > /dev/null' |bash",
	#             timeout => 600,
	#          }
	#       }
	#    }
	# }

	# if $operatingsystem == "CentOS" {
	# 	case $operatingsystemmajrelease {
	# 		5: {
				$epel_package = "epel-release-5-4"
				$epel_source = "http://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm"
				$remi_package = "remi-release-5.10-1.el5.remi"
				$remi_source = "http://rpms.famillecollet.com/enterprise/remi-release-5.rpm"
				$ius_package = "ius-release-1.0-13.ius.centos5"
				$ius_source = "http://dl.iuscommunity.org/pub/ius/stable/CentOS/5/x86_64/ius-release-1.0-13.ius.centos5.noarch.rpm"
				$ius_cmd = "sed -si '0,/enabled=0/{s/enabled=0/enabled=1/}' /etc/yum.repos.d/ius-archive.repo" 
				$ius_onlyif = "test `yum repolist --noplugins | grep -E \"ius-archive\" |wc -l ` -eq 0"
	# 		}
	# 		6: {
	# 			$epel_package = "epel-release-6-8"
	# 			$epel_source = "http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm"
	# 			$remi_package = "remi-release-6.5-1.el6.remi"
	# 			$remi_source = "http://rpms.famillecollet.com/enterprise/remi-release-6.rpm"
	# 			$ius_package = "ius-release-1.0-13.ius.centos6"
	# 			$ius_source = "http://dl.iuscommunity.org/pub/ius/stable/CentOS/6/x86_64/ius-release-1.0-13.ius.centos6.noarch.rpm"
	# 			$ius_cmd = "true" 
	# 			$ius_onlyif = "false" 
	# 			exec { 'import_mariadb_rpm':
	# 				command => "rpm --import https://yum.mariadb.org/RPM-GPG-KEY-MariaDB",
	# 				unless => 'rpm -qi gpg-pubkey-1bb943db-511147a9 > /dev/null'
	# 			}
	# 			exec { 'mariadb_repo':
	# 				command => 'echo "[mariadb]" > /etc/yum.repos.d/MariaDB.repo \
	# 							&& echo "name = MariaDB" >> /etc/yum.repos.d/MariaDB.repo \
	# 							&& echo "baseurl = http://yum.mariadb.org/5.5/centos5-x86" >> /etc/yum.repos.d/MariaDB.repo \
	# 							&& echo "gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB" >> /etc/yum.repos.d/MariaDB.repo \
	# 							&& echo "gpgcheck=1" >> /etc/yum.repos.d/MariaDB.repo',
	# 				creates => '/etc/yum.repos.d/MariaDB.repo'
	# 			}
	# 		}
	# 	}
	# }

	if defined('$ssh_key') {
		file { '/root/.ssh':
			ensure => 'directory',
			owner => 'root',
			mode => '700',
		}

		file { '/root/.ssh/authorized_keys2':
			ensure => 'file',
			content => $ssh_key,
			require => File [ '/root/.ssh' ],
			mode => '644'
		}
	}

		file { 'adjust_timezone':
		replace => yes,
		source => "/usr/share/zoneinfo/$zonefile",
		path => "/etc/localtime",
	}

	# package { $epel_package:
	# 	source => $epel_source,
	# 	ensure => installed,
	# 	provider => rpm,
	# 	require => Exec[ 'selinux-off-2' ],
	# }

	# package { $remi_package:
	# 	source => $remi_source,
	# 	ensure => installed,
	# 	provider => rpm,
	# 	require => Package[ $epel_package ],
	# }

	# package { $ius_package:
	# 	source => $ius_source,
	# 	ensure => installed,
	# 	provider => rpm,
	# 	require => Package[ $epel_package ],
	# }

	# exec { 'ius-archive':
	# 	command => $ius_cmd,
	# 	onlyif => $ius_onlyif,
	# 	require => Package [ $ius_package ],
	# }

	# $commonTools = [ 'screen', 'vim-enhanced', 'nano', 'git', 'mlocate', 'which', 'ssmtp', 'yum-utils', 'pv' ]
	# package { $commonTools:
	# 	ensure => installed,
	# 	require => Exec[ 'ius-archive' ],
	# }

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

	if defined('$themename') {

		# exec { 'nodejs':
		# 	command => 'curl -sL https://rpm.nodesource.com/setup | bash -',
		# 	creates => '/etc/yum.repos.d/nodesource-el.repo',
		# 	require => Exec [ 'selinux-off-2' ],
		# }

		# package { 'nodejs':
		# 	ensure => installed,
		# 	require => Exec [ 'nodejs' ],
		# }

		# exec { 'rvm':
		# 	command => 'curl -sSL https://get.rvm.io | bash -',
		# 	creates => '/usr/local/rvm/bin/rvm',
		# 	require => Package [ 'nodejs' ],
		# }

	 # 	exec { 'libffi':
		# 	command => 'rpm -Uvh http://yum.puppetlabs.com/el/5/dependencies/x86_64/libffi-3.0.5-2.el5.x86_64.rpm',
		# 	creates => '/usr/lib64/libffi.so.5.0.6',
		# 	require => Exec [ 'rvm' ],
		# }

	 # 	exec { 'libffi-devel':
		# 	command => 'rpm -Uvh --nodeps http://yum.puppetlabs.com/el/5/dependencies/x86_64/libffi-devel-3.0.5-2.el5.x86_64.rpm',
		# 	creates => '/usr/lib64/libffi-3.0.5/include/ffi.h',
		# 	require => Exec [ 'libffi' ],
		# }

		# $yaml = ['libyaml', 'libyaml-devel']
		# package { $yaml:
		# 	ensure => installed,
		# 	require => Exec ['libffi-devel'],
		# }

	 # 	exec { 'yaml_rvm':
		# 	command => 'bash --login -c \'rvm pkg install libyaml\'',
		# 	creates => '/usr/local/rvm/usr/lib/libyaml.a',
		# 	require => Exec [ 'libffi-devel' ],
		# }

	 #  	exec { 'ruby193':
		# 	command => 'bash --login -c \'rvm reinstall 1.9.3 --with-libyaml;
		# 				rvm reset;\'',
		# 	# creates => '/usr/local/rvm/rubies/ruby-1.9.3-p547/bin/ruby',
		# 	unless => '/usr/local/rvm/bin/rvm list | grep 1.9.3 > /dev/null',
		# 	require => Exec [ 'yaml_rvm' ],
		# 	timeout => 1800,
		# }

	  	exec { 'ad_build_root':
			command => "bash --login -c 'rvm use 1.9.3; 
						cd $webroot/sites/all/themes/$themename; 
						gem install bundler; 
						npm install -g bower; 
						npm install -g grunt-cli; 
						npm install; 
						CI=true bower install --allow-root; 
						bundle install; 
						rvm reset;'",
			creates => "/usr/lib/node_modules/grunt-cli",
			# require => Exec [ 'ruby193' ],
		}

		exec { 'ad_build_nonroot':
			command => "bash --login -c 'rvm use 1.9.3; 
						cd $webroot/sites/all/themes/$themename; 
						grunt --force; 
						rvm reset;'",
			# creates => "$webroot/sites/all/themes/$themename/node_modules",
			require => Exec [ 'ad_build_root' ],
			# user => 'vagrant',
		}

		file { 'grunt_file':
			path => '/usr/local/bin/gruntwatch',
			ensure => file,
			content => template('commontools/gruntwatch.erb'),
			mode => 'a+x',
		}

		exec { 'grunt_run':
			command => "bash --login -c 'rvm use 1.9.3; 
						cd $webroot/sites/all/themes/$themename; 
						/usr/local/bin/gruntwatch &
						rvm reset;'",
			require => [ Exec [ 'ad_build_nonroot' ], File [ 'grunt_file' ], ],
			unless => 'pidof grunt >/dev/null',
		}
	}
}