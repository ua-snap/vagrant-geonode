#! /bin/bash
# This script is designed to install GeoNode with the MapLoom extension that has
# been forked by the Univsity of Alaska Fairbanks group Scenarios Network for 
# Alaska and Arctic Planning (SNAP). By running this script on an Ubuntu 14.04
# system will result in a working GeoNode instance on the localhost port 8000. This
# is useful for development inside of a Vagrant instance that can provision the
# development host using this script. 

# User running this script. Must be a user with sudo to root.
USER=`whoami`

# Where should the source code be installed. Important for development environment as we want to use our
# preferred IDEs to edit code.
INSTALL_DIR='/install/portal'

# Prevent apt-get steps from displaying interactive prompts
export DEBIAN_FRONTEND=noninteractive

# Node.js setup
sudo sh -c 'curl -sL https://deb.nodesource.com/setup | bash -'

# Make sure apt-get is updated and install all necessary pacakges
sudo apt-get update
sudo apt-get install -y            \
    ant                            \
    apache2                        \
    build-essential                \
    gdal-bin                       \
    gettext                        \
    git                            \
    libapache2-mod-wsgi            \
    libgdal1h                      \
    libgdal-dev                    \
    libgeos-dev                    \
    libjpeg-dev                    \
    libpng-dev                     \
    libpq-dev                      \
    libproj-dev                    \
    libxml2-dev                    \
    libxslt1-dev                   \
    libpq-dev                      \
    maven2                         \
    nodejs                         \
    openjdk-7-jre                  \
    patch                          \
    postgresql                     \
    postgis                        \
    postgresql-contrib             \
    python                         \
    python-dev                     \
    python-gdal                    \
    python-httplib2                \
    python-imaging                 \
    python-lxml                    \
    python-nose                    \
    python-pastescript             \
    python-pip                     \
    python-psycopg2                \
    python-pyproj                  \
    python-shapely                 \
    python-software-properties     \
    python-support                 \
    python-urlgrabber              \
    python-virtualenv              \
    tomcat7                        \
    unzip                          \
    vim                            \
    zip                            \
    zlib1g-dev

sudo pip install virtualenvwrapper
sudo npm install -y -g bower
sudo npm install -y -g grunt-cli

sudo mkdir -p $INSTALL_DIR
sudo chown $USER $INSTALL_DIR
cd $INSTALL_DIR

# GeoNode GitHub repo
git clone https://github.com/GeoNode/geonode.git

# Create geonode user and database in PSQL
sudo -u postgres psql -c "CREATE USER geonode WITH PASSWORD 'geonode'"
sudo -u postgres psql -c "CREATE DATABASE geonode"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE geonode to geonode"

# Set alias for VI to VIM
echo "alias vi='vim'"

# Set virtual environment variables in BASHRC for user running this script
echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python" >> ~/.bashrc
echo "export WORKON_HOME=~/.venvs" >> ~/.bashrc
echo "source /usr/local/bin/virtualenvwrapper.sh" >> ~/.bashrc
echo "export PIP_DOWNLOAD_CACHE=$HOME/.pip-downloads" >> ~/.bashrc

# Sourcing these from the BASHRC was not working in the script. Explicitly,
# setting these from the BASHRC for immediate usage.
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python
export WORKON_HOME=$HOME/.venvs
source `which virtualenvwrapper.sh`
export PIP_DOWNLOAD_CACHE=$HOME/.pip-downloads

# Make a virtual environment called geonode and work within the virtual environment
mkvirtualenv geonode
workon geonode

# Install the GeoNode Python package
pip install -e geonode

# Download and untar the GDAL 1.10.0 Python package
pip install --download=. --no-use-wheel GDAL==1.10.0
tar -zxvf GDAL-1.10.0.tar.gz

# Edit the gdal_config variable within the setup.cfg of GDAL to point to the correct
# gdal-config location.
sed -e 's/gdal_config = ..\/..\/apps\/gdal-config/gdal_config = \/usr\/bin\/gdal-config/' < GDAL-1.10.0/setup.cfg > GDAL-1.10.0/setup2.cfg
mv GDAL-1.10.0/setup2.cfg GDAL-1.10.0/setup.cfg

# Export the include directory of GDAL to C and C++ include pathes
export CPLUS_INCLUDE_PATH=/usr/include/gdal
export C_INCLUDE_PATH=/usr/include/gdal

# Build the GDAL extensions 
cd GDAL-1.10.0
python setup.py build_ext --gdal-config=/usr/local/bin/gdal-config
cd ..

# Install GDAL 1.10.0 Python package
pip install -e GDAL-1.10.0
rm GDAL-1.10.0.tar.gz

# Run paver setup and paver sync to get the paver start / stop commands for the 
# GeoNode and GeoServer tools.
cd geonode
paver setup
paver sync

# Turn of Tomcat since it is unnecessary for running GeoNode / GeoServer
sudo service tomcat7 stop

# Clone and install the django-maploom Python package
cd ..
git clone https://github.com/ROGUE-JCTD/django-maploom.git
pip install -e django-maploom

# Chown the .npm directory to the user currently running this script
sudo chown -R $USER ~/.npm/

# Clone and make the MapLoom JS file from our local fork of the MapLoom repository
git clone https://github.com/ua-snap/MapLoom.git
cd MapLoom
npm install && bower install && grunt
cp -f bin/assets/MapLoom-1.2.0.js ../django-maploom/maploom/static/maploom/assets/MapLoom-1.2.js
cd ..

# Add maploom as a GeoNode app to settings.py
sed -e "s/) + GEONODE_APPS/'maploom',\n) + GEONODE_APPS/" < geonode/geonode/settings.py > geonode/geonode/settings2.py
mv geonode/geonode/settings2.py geonode/geonode/settings.py

# Add the maploom_urls to the list of urlpatterns in urls.py
echo "from maploom.geonode.urls import urlpatterns as maploom_urls

# After the section where urlpatterns is declared
urlpatterns += maploom_urls" >> geonode/geonode/urls.py

# Start GeoServer and Django for GeoNode
cd geonode
paver start_geoserver && paver start_django -b 0.0.0.0:8000
