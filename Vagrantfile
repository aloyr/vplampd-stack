# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'pathname'
require 'socket'
require 'timeout'
require 'yaml'

# is the config file present? if not, halt execution as there is nothing to do!
raise Vagrant::Errors::VagrantError.new, "ERROR: config.yml file missing." if not Pathname('config.yml').exist?

# setup settings variable, dnsserver and some defaults
settings = YAML.load_file('config.yml')
dnsServer = `scutil --dns|awk '$0 ~ /nameserver/ {printf $3; exit}'`
defaults = {'timezone'=> 'America/Chicago', 
            'hostname'=> Socket.gethostname + '.dev', 
            'webroot'=> '/var/www/hid',
            'aliases' => 'www.' + Socket.gethostname + '.dev',
           }

# sanity checks to the yaml configuration file
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

# output helper message if developer is re-provisioning the box
if ARGV[0] == 'provision' and ENV['REDODB'] == nil
  puts "\nYou can reprovision the database by issuing the command below:"
  puts "REDODB='yes' vagrant provision\n\n"
elsif ARGV[0] == 'provision' and ENV['REDODB'] == 'yes'
  puts "\nVagrant will make puppet reprovision the database.\n\n"
end

# helper functions to manipulate the settings.php file
def resetSettingsFile settings, vagstring
  settingsfile = settings['local'].gsub('~', ENV['HOME']) + '/sites/default/settings.php'
  removeString = vagstring.gsub("\n",'')
  if File.file?settingsfile
    puts 'Restoring settings.php file'
    File.chmod(0666, settingsfile)
    settingslines = File.open(settingsfile,'r').readlines()
    writefile = File.open(settingsfile,'w+')
    settingslines.each do |line|
      writefile.write(line) if line !~ /#{removeString}/
    end
    writefile.close()
  end
end

def adjustSettingsFile settings, vagstring
  resetSettingsFile settings, vagstring
  puts 'Adjusting settings.php file'
  settingsfile = settings['local'].gsub('~', ENV['HOME']) + '/sites/default/settings.php'
  if not File.file?settingsfile
    defsettingsfile = settings['local'].gsub('~', ENV['HOME']) + '/sites/default/default.settings.php'
    cp(defsettingsfile, settingsfile)
  end
  File.chmod(0666, settingsfile)
  settingslines = File.open(settingsfile,'r').readlines()
  writefile = File.open(settingsfile,'w+')
  settingslines.each do |line|
    writefile.write(line) if line !~ /#{vagstring}/
  end
  if settings['settingsphp'] != nil
    settings['settingsphp'].each do |settingline|
      writefile.write(settingline.gsub('USER', ENV['USER'].upcase) + vagstring)
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
        line = "$conf['language_domains']['#{item[0]}'] = 'http://#{item[1]}'; #{vagstring}"
        writefile.write(line)
      end
    end
  end 
  writefile.close()
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
    vb.memory = 4182
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
    if ENV['REDODB'] == 'yes'
      puppet.facter['redodb'] = 'y'
    end
    if settings['themename'] != nil
      puppet.facter['themename'] = settings['themename']
    end
    keyfile = '~/.ssh/id_rsa.pub'.gsub('~', ENV['HOME'])
    if File.file?keyfile
      puppet.facter['ssh_key'] = File.open(keyfile, 'rb').read
    end
  end
  config.trigger.before :provision do
    File.delete('data/insertlanguages.sql') if File.exist?('data/insertlanguages.sql')
  end

  # provisioning triggers stuff below
  vagstring = ' ## vagrant-provisioner' + "\n"
  config.trigger.before :provision do
    adjustSettingsFile settings, vagstring
  end

  config.trigger.before :destroy do
    resetSettingsFile settings, vagstring
  end
end
