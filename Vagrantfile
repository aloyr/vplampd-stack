# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'

settings = YAML.load_file('config.yml')
dnsServer = `scutil --dns|awk '$0 ~ /nameserver/ {printf $3; exit}'`

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "centos56"
  config.vm.box_url = "https://dl.dropbox.com/u/7196/vagrant/CentOS-56-x64-packages-puppet-2.6.10-chef-0.10.6.box"

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end

  # Disable automatic box Update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080
  settings['ports'].each do |item|
    config.vm.network "forwarded_port", guest: item['vm'], host: item['local']
  end

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"
  config.vm.hostname = settings['hostname']
  config.hostsupdater.aliases = settings['aliases']
  # config.hostsupdater.remove_on_suspend = true
  config.vm.network "private_network", ip: settings['hostip']

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # If true, then any SSH connections made will enable agent forwarding.
  # Default value: false
  # config.ssh.forward_agent = true

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"
  settings['shares'].each do |item|
    config.vm.synced_folder item['local'], item['vm']
  end

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
  #   # Don't boot with headless mode
  #  vb.gui = true
  #
  #   # Use VBoxManage to customize the VM. For example to change memory:
    vb.memory = 4096
    vb.cpus = 2
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end
  #
  # View the documentation for the provider you're using for more
  # information on available options.

  config.vm.provision :shell, :inline => "echo 'nameserver #{dnsServer}' > /etc/resolv.conf; yum update -y puppet"


  # Enable provisioning with Puppet stand alone.  Puppet manifests
  # are contained in a directory path relative to this Vagrantfile.
  # You will need to create the manifests directory and a manifest in
  # the file default.pp in the manifests_path directory.
  #
  config.vm.provision "puppet" do |puppet|
    # puppet.manifests_path = "manifests"
    # puppet.manifest_file  = "default.pp"
    puppet.module_path  = "modules"
    puppet.facter = {
      "vagrant" => "1",
      "dnsserver" => dnsServer,
      "webroot" => settings['webroot'],
      "webrootparsed" => settings['webroot'].gsub('/','\/'),
    }
  end
end
