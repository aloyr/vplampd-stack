vplampd-stack
=============

Vagrant, puppet, lamp, drupal, drush, xhprof, xdebug, memcache stack, based on CentOS 5.6

## Prerequisites
- You will need to have your ssh keys created and setup in github, if you havent done that yet
- You will need 3 vagrant plugins, installed by running the following command in terminal:
	sudo vagrant plugin install vagrant-cachier vagrant-hostsupdater vagrant-triggers
- You will also need VirtualBox installed:
 	https://www.virtualbox.org/wiki/Downloads
- You will need to pull a branch of your site from github (ie, https://github.com/HID-GS/HID-Global), and place it in the location specified in the "shares" section of config.yml (ie,  ~/Sites/HID-Global/hid)

## Instructions
	
- Setup your SSH keys
  - If you have nothing in the `~/.ssh` folder, run the following commands in terminal:

```bash
ssh-keygen # press <enter> until it is done
cat ~/.ssh/id_rsa.pub | pbcopy # this will copy your public key to the pasteboard
```
- Setup your SSH keys (cont'd)
  - Visit the [ssh keys page](https://github.com/settings/ssh) in github and click on **Add SSH Key**
  - Choose any name you'd like such as **work laptop** for the title field
  - Go to the **key field** and press ⌘-V to paste the ssh key you copied above
  - Click on **Add key** to Save
- Download the latest version of [vagrant](http://www.vagrantup.com/downloads.html)
- Download the [vplampd-stack](https://github.com/aloyr/vplampd-stack/archive/master.zip)
  - Alternatively, clone the git repo with:

```bash
mkdir -p ~/workspace/vagrant 2> /dev/null
cd ~/workspace/vagrant
git clone https://github.com/aloyr/vplampd-stack
cd vplampd-stack
```

- Move unzipped "vplampd-stack-master" folder to a place where you'd like to keep the new Vagrant build (ie, create something like /Users/[username]/workspace/vagrant and place it there...)
- Navigate to where you put the vplampd-stack-master folder
- Copy the example.config.yml file in that location, and make a copy called "config.yml"
	In terminal:

```bash
cp {example.,config.yml}
vim config.yml
```

- Ask a fellow dev for a copy of the current **Drupal DB**, as well as their **config.yml** file.
- Using the other dev's config.yml file as a template, modify the config.yml file you copied from example.config.yml.
- Get a recent mysql dump of the DB, modify the "database" section of the config.yml to suit the DB you're using, and put the DB in the "vplampd-stack-master/data" folder.
- Create a ".drush" folder in your home directory.
	In terminal:
	mkdir ~/.drush
	- Ideally, you could also properly install drush on your host box, but that's not necessary for this process.
	  - To install drush, use the following commands:

```bash
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/bin/composer
composer global require drush/drush:7.*
```

- In terminal, run `vagrant up` inside the vplampd-stack-master folder.
  - If you get a permissions error, run `sudo chown -R $USER $HOME/.vagrant.d`, then run `vagrant up` again.
- If all works well, run the grunt build in order to use the current CSS / JS.
	In terminal:

```bash
	ssh root@[hostname]
	cd [location of the new theme folder on the vagrant box]
	nvm install 0.10.32
	nvm use v0.10.32
	rvm install 1.9.3
	rvm use 1.9.3
	npm install
	CI=true bower install --allow-root
	bundle install
	grunt
```

- Navigate to the hostname defined in the config.yml file on your host box's browser
- Clear Drupal cache (if needed)
- Voila! All set!
	
