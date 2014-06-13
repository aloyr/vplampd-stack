class perfmon {
	$perfPackages = [ 'grunt', 'grunt-cli', 'phantom', 'grunt-phantom', 'phantomas', 'slimerjs', 'wraith', ]
	package { $perfPackages:
		ensure => installed,
		provider => 'npm',
		creates => '/usr/lib/node_modules/$name'
	}
	
}