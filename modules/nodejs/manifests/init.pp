class nodejs {
	if $operatingsystem == 'CentOS' and $operatingsystemmajrelease == '6' {
		$nodePackages = [ 'nodejs', 'npm' ]
		package { $nodePackages:
			ensure => installed,
			require => $commonTools::epel_package,
		}

	}
}