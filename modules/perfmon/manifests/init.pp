class perfmon {
	$perfPackages = [ 'grunt', 'grunt-cli', 'phantom', 'grunt-phantom', 'phantomas', 'yslow', 'slimerjs', 'wraith', ]
	package { $perfPackages:
		ensure => installed,
		provider => 'npm',
	}
}