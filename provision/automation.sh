#! /bin/bash

# Change this to match a user to install Geonode and Maploom
#USER='vagrant'

# Full path to geonode-maploom-install.sh script
#SCRIPT=/home/vagrant/provision/geonode-maploom-install.sh

whoami

# Prevent apt-get steps from displaying interactive prompts
export DEBIAN_FRONTEND=noninteractive

# Node.js setup
sudo sh -c 'curl -sL https://deb.nodesource.com/setup | bash -'

sudo apt-get update
sudo apt-get install -y                 \
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
    zip                            \
    zlib1g-dev

sudo pip install virtualenvwrapper
sudo npm install -y -g bower
sudo npm install -y -g grunt-cli

cd ~

# GeoNode GitHub repo
git clone https://github.com/GeoNode/geonode.git

sudo -u postgres psql -c "CREATE USER geonode WITH PASSWORD 'geonode'"
sudo -u postgres psql -c "CREATE DATABASE geonode"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE geonode to geonode"

echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python" >> ~/.bashrc
echo "export WORKON_HOME=~/.venvs" >> ~/.bashrc
echo "source /usr/local/bin/virtualenvwrapper.sh" >> ~/.bashrc
echo "export PIP_DOWNLOAD_CACHE=$HOME/.pip-downloads" >> ~/.bashrc

source ~/.bashrc

source `which virtualenvwrapper.sh`
mkvirtualenv geonode
workon geonode
pip install -e geonode

pip install --download=. --no-use-wheel GDAL==1.10.0
tar -zxvf GDAL-1.10.0.tar.gz
sed -e 's/gdal_config = ..\/..\/apps\/gdal-config/gdal_config = \/usr\/bin\/gdal-config/' < GDAL-1.10.0/setup.cfg > GDAL-1.10.0/setup2.cfg
mv GDAL-1.10.0/setup2.cfg GDAL-1.10.0/setup.cfg

export CPLUS_INCLUDE_PATH=/usr/include/gdal
export C_INCLUDE_PATH=/usr/include/gdal

cd GDAL-1.10.0
python setup.py build_ext --gdal-config=/usr/local/bin/gdal-config
cd ..
pip install -e GDAL-1.10.0
rm GDAL-1.10.0.tar.gz

cd geonode
paver setup
paver sync

sudo service tomcat7 stop

cd ..
git clone https://github.com/ROGUE-JCTD/django-maploom.git
pip install -e django-maploom

sed -e "s/) + GEONODE_APPS/'maploom',\n) + GEONODE_APPS/" < geonode/geonode/settings.py > geonode/geonode/settings2.py
mv geonode/geonode/settings2.py geonode/geonode/settings.py

echo "from maploom.geonode.urls import urlpatterns as maploom_urls

# After the section where urlpatterns is declared
urlpatterns += maploom_urls" >> geonode/geonode/urls.py
