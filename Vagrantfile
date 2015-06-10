# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "puppetlabs/debian-7.8-64-puppet"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  config.vm.network "forwarded_port", guest: 8000, host: 8888
  config.vm.network "forwarded_port", guest: 8080, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"
  end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "shell", inline: <<-SHELL
    # Adapted from: http://docs.geonode.org/en/latest/tutorials/devel/install_devmode/index.html#install-devmode

    # Prevent apt-get steps from displaying interactive prompts
    export DEBIAN_FRONTEND=noninteractive

    echo "deb http://http.us.debian.org/debian unstable main non-free contrib" >> /etc/apt/sources.list
    apt-get update

    # Build tools and libraries
    apt-get install -y build-essential libxml2-dev libxslt1-dev libpq-dev zlib1g-dev

    # Postgis
    touch /etc/apt/sources.list.d/pgdg.list
    echo "deb http://apt.postgresql.org/pub/repos/apt/ wheezy-pgdg main" >> /etc/apt/sources.list.d/pgdg.list
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
    apt-key add -
    apt-get update
    apt-get install -y postgresql-9.3-postgis-2.1 postgresql-9.3-postgis-scripts

    # GDAL libraries from unstable repository
    apt-get install -y libgdal1h libgdal-dev

    # Python dependencies
    apt-get install -y python-dev python-imaging python-lxml python-pyproj python-shapely python-nose python-httplib2 python-pip python-software-properties python-gdal
    pip install virtualenvwrapper

    # Java
    apt-get install -y --force-yes openjdk-6-jdk ant maven2 --no-install-recommends

    # Supporting tools
    apt-get install -y git gettext

    # Nodejs for client build tools
    apt-get install curl build-essential
    curl -sL https://deb.nodesource.com/setup | bash -
    apt-get install -y nodejs
    npm install -y -g bower
    npm install -y -g grunt-cli

    # Core repo
    git clone https://github.com/GeoNode/geonode.git
    chown -R vagrant:vagrant geonode

  SHELL
end
