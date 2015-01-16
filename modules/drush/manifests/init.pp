class drush {
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

	file { '/opt/local':
		ensure => 'directory',
	}

	exec { 'composer':
		command => 'curl -sS https://getcomposer.org/installer \
				   | php -d allow_url_fopen=On -- --filename=composer --install-dir=/usr/local/bin',
		creates => '/usr/local/bin/composer',
		require => [ Exec [ 'php_ini' ], Package [ $lamp::pear ], ],
	}

	exec { 'pear_Console_Table':
		command => 'pear install Console_Table',
		unless => 'pear list | grep Console_Table > /dev/null',
		require => [ Exec [ 'php_ini' ], Package [ $lamp::pear ], ],
	}

	exec { 'drush':
		command => 'git clone -b 5.x https://github.com/drush-ops/drush.git /opt/local/drush',
		creates => '/opt/local/drush',
		require => [ Exec [ 'composer', 'pear_Console_Table' ], Package [ 'git' ], ],
	}

	file { '/usr/local/bin/drush':
		ensure => link,
		target => '/opt/local/drush/drush',
		require => Exec [ 'drush' ],
	}

	if defined('$dbfile') {
		exec { 'drush_enable_modules':
			command => "/usr/local/bin/drush -r $webroot -y en stage_file_proxy devel xhprof memcache memcache_admin update language_domains devel_themer",
			require => defined('$redodb') ? {
				false => [ File [ '/usr/local/bin/drush'], Service [ $lamp::dbservice ], Exec [ 'setup_dbfile' ], ],
				true  => [ File [ '/usr/local/bin/drush'], Service [ $lamp::dbservice ], Exec [ 'reprovision_dbfile' ], ],
			},
		}
	}

	filehttp { 'set_prompt.sh':
		ensure => present,
		name => '/etc/profile.d/set_prompt.sh',
		source => 'https://raw.githubusercontent.com/aloyr/system_config_files/master/dotfiles/set_prompt.sh',
		mode => 0755,
	}
}
