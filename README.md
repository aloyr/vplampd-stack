vplampd-stack
=============

Vagrant, puppet, lamp, drupal stack, based on CentOS 5.6

You will need 3 vagrant plugins, installed by running the following command:

	sudo vagrant plugin install vagrant-cachier vagrant-hostsupdater vagrant-triggers

Then create and adjust your configuration:

	cp {example.,config.yml}
	vim config.yml