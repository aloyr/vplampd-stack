vplampd-stack
=============

Vagrant, puppet, lamp, drupal, drush, xhprof, xdebug, memcache stack, based on CentOS 5.6

Instructions

- You will need 3 vagrant plugins, installed by running the following command in terminal:
	sudo vagrant plugin install vagrant-cachier vagrant-hostsupdater vagrant-triggers
- Download the vplampd-stack: https://github.com/aloyr/vplampd-stack/archive/master.zip
- Move unzipped "vplampd-stack-master" folder to a place where you'd like to keep the new Vagrant build (ie, create something like /Users/[username]/vagrantbuilds and place it there...)
- Navigate to where you put the vplampd-stack-master folder
- Copy the example.config.yml file in that location, and make a copy called "config.yml"
	In terminal:
	cp {example.,config.yml}
	vim config.yml
- Ask a fellow dev for a copy of the HID DB, as well as their config.yml file.
- Using the other dev's config.yml file as a template, modify the config.yml file you copied from example.config.yml.
- Get a recent copy of the HID DB and put it in the same folder as config.yml.
- Run "vagrant up" from that location.
