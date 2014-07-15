# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'
require 'pathname'
require 'socket'

abort "ERROR: config.yml file missing." if not Pathname('config.yml').exist?
settings = YAML.load_file('config.yml')
dnsServer = `scutil --dns|awk '$0 ~ /nameserver/ {printf $3; exit}'`

# sanity checks to the yaml configuration file
defaults = {'timezone'=> 'America/Chicago', 
            'hostname'=> Socket.gethostname + '.dev', 
            'webroot'=> '/var/www/hid',
            'aliases' => 'www.' + Socket.gethostname + '.dev',
           }

def checkPlugin(pluginName)
  unless Vagrant.has_plugin?(pluginName)
    raise Vagrant::Errors::VagrantError.new, pluginName + ' plugin missing. Install it with "sudo vagrant plugin install ' + pluginName + '"'
  end
end

['vagrant-cachier', 'vagrant-hostsupdater', 'vagrant-triggers'].each do |plugin|
  checkPlugin(plugin)
end

def checkErrors setting 
  if setting['value'] == nil
    raise Vagrant::Errors::VagrantError.new, "Configuration Error: #{setting['name']} not defined in config.yml file, setup cannot continue"
  end
end
[
  {'name' => 'database', 'value' => settings['database']},
  {'name' => 'database name', 'value' => settings['database']['name']},
  {'name' => 'database user', 'value' => settings['database']['user']},
  {'name' => 'database pass', 'value' => settings['database']['pass']},
  {'name' => 'database file', 'value' => settings['database']['file']},
].each do |item|
  checkErrors item
end

def checkWarnings settings, setting, default = nil
  if settings[setting] == nil and default == nil
    puts 'Warning: ' + setting + ' not defined in config.yml file. The setup should work, but are you sure this is what you want?'
  elsif settings[setting] == nil and default != nil
    puts 'Warning: ' + setting + ' not defined in config.yml file, assuming ' + default
    settings[setting] = default
  end
end
[
  {'setting' => 'languages', 'default' => nil},
  {'setting' => 'settingsphp', 'default' => nil},
  {'setting' => 'shares', 'default' => nil},
  {'setting' => 'aliases', 'default' => defaults['aliases']},
  {'setting' => 'hostname', 'default' => defaults['hostname']},
  {'setting' => 'timezone', 'default' => defaults['timezone']},
  {'setting' => 'webroot', 'default' => defaults['webroot']},
].each do |item|
  checkWarnings settings, item['setting'], item['default']
end

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "centos56"
  config.vm.box_url = "https://dl.dropbox.com/u/7196/vagrant/CentOS-56-x64-packages-puppet-2.6.10-chef-0.10.6.box"

  # if Vagrant.has_plugin?("vagrant-cachier")
    # config.cache.scope = :box

    # config.cache.synced_folder_opts = {
    #   type: :nfs,
    #   mount_options: ['rw', 'vers=3', 'tcp', 'nolock']
    # }
  # end

  # Disable automatic box Update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080
  if settings['ports']  != nil 
    settings['ports'].each do |item|
      config.vm.network "forwarded_port", guest: item['vm'], host: item['local']
    end
  end

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"
  config.vm.hostname = settings['hostname']
  if settings['languages'] != nil
    settings['languages'].each do |item|
      # settings['aliases'].merge!(item[1])
      item.each do |lang|
        settings['aliases'].concat([lang[1]])
      end
    end
  end
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
  config.vm.synced_folder ".", "/vagrant",  :mount_options => ["dmode=777,fmode=766"]
  settings['shares'].each do |item|
    config.vm.synced_folder item['local'], item['vm'], mount_options: ["dmode=777,fmode=766,uid=48,gid=48"]
    settings['local'] = item['local'] if item['vm'] == settings['webroot']
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
    vb.memory = 8192
    vb.cpus = 2
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end
  #
  # View the documentation for the provider you're using for more
  # information on available options.

  config.vm.provision :shell, :inline => "if [ ! `rpm -q puppet | grep -E '^puppet-3'` ]; then echo 'nameserver #{dnsServer}' > /etc/resolv.conf; yum update -y puppet; yum update -y rubygem-json; fi"


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
      "zonefile" => settings['timezone'],
      "webroot" => settings['webroot'],
      "webrootparsed" => settings['webroot'].gsub('/','\/'),
      "webhost" => settings['hostname'],
    }
    settings['database'].each do |item|
      puppet.facter.merge!({"db#{item[0]}" => item[1]})
    end
    if puppet.facter['dbfile'] != nil
      dbfile = "data/#{puppet.facter['dbfile']}"
      abort "Database file #{dbfile} not found." if not Pathname(dbfile).exist?
    end 
    if settings['languages'] != nil
      puppet.facter['languages'] = settings['languages'].to_yaml
    end
    if settings['aliases'] != nil
      puppet.facter['serveralias'] = 'ServerAlias ' + settings['aliases'].join(' ')
    end
  end
  config.trigger.before :provision do
    File.delete('data/insertlanguages.sql') if File.exist?('data/insertlanguages.sql')
  end
  vagstring = ' ## vagrant-provisioner'
  config.trigger.after :provision do
    puts 'Adjusting settings.php file'
    settingsfile = settings['local'].gsub('~', ENV['HOME']) + '/sites/default/settings.php'
    if not File.file?settingsfile
      defsettingsfile = settings['local'].gsub('~', ENV['HOME']) + '/sites/default/default.settings.php'
      cp(defsettingsfile, settingsfile)
    else
      File.chmod(0666, settingsfile)
    end
    settingslines = File.open(settingsfile,'r').readlines()
    writefile = File.open(settingsfile,'w+')
    settingslines.each do |line|
      writefile.write(line) if line !~ /#{vagstring}/
    end
    if settings['settingsphp'] != nil
      settings['settingsphp'].each do |settingline|
        writefile.write(settingline.gsub('USER', ENV['USER'].upcase) + vagstring + "\n")
      end
    end
    defaultDB = "$databases['default']['default'] = array("
    defaultDB += "'driver' => 'mysql',"
    defaultDB += "'database' => '" + settings['database']['name'] + "',"
    defaultDB += "'username' => '" + settings['database']['user'] + "',"
    defaultDB += "'password' => '" + settings['database']['pass'] + "',"
    defaultDB += "'host' => '127.0.0.1',"
    defaultDB += "'prefix' => '',"
    defaultDB += ");" + vagstring
    writefile.write(defaultDB)
    if settings['languages'] != nil
      settings['languages'].each do |lang|
        lang.each do |item|
          line = "$conf['language_domains']['#{item[0]}'] = 'http://#{item[1]}'; #{vagstring} \n"
          writefile.write(line)
        end
      end
    end 
    writefile.close()
  end
  config.trigger.before :destroy do
    puts 'Restoring settings.php file'
    settingsfile = settings['local'].gsub('~', ENV['HOME']) + '/sites/default/settings.php'
    settingslines = File.open(settingsfile,'r').readlines()
    writefile = File.open(settingsfile,'w+')
    settingslines.each do |line|
      writefile.write(line) if line !~ /#{vagstring}/
    end
    writefile.close()
  end
end
