Exec {
	path => '/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin',
}

stage { 'pre':
	before => Stage[ 'main' ],
}

class pre_stage { 

	exec { 'reset_dns':
		command => "echo 'nameserver $dnsserver' > /etc/resolv.conf",
		onlyif => "echo '! grep $dnsserver /etc/resolv.conf' | bash",
	}
	exec { 'reset_eth1':
		command => 'sed -i "s/BOOTPROTO=dhcp/BOOTPROTO=none/g" /etc/sysconfig/network-scripts/ifcfg-eth1',
		onlyif => 'grep "BOOTPROTO=dhcp" /etc/sysconfig/network-scripts/ifcfg-eth1',
	}
}

class { 'pre_stage':
	stage => 'pre',
}

include commonTools
include lamp
include drush