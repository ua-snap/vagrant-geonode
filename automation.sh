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

# Delete old INSTALL_DIR if present
if [ -d $INSTALL_DIR ]; then
  echo "Removing old geonode installation for fresh provisioning."
  rm -rf $INSTALL_DIR
fi

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
    openjdk-7-jre                  \
    patch                          \
    postgresql                     \
    postgis*                       \
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
    software-properties-common     \
    tomcat7                        \
    unzip                          \
    vim                            \
    zip                            \
    zlib1g-dev

sudo add-apt-repository -y ppa:ubuntugis/ubuntugis-unstable && sudo apt-get update
sudo apt-get install -y libgdal-dev
sudo apt-get install -y gdal-bin

sudo pip install virtualenvwrapper

# Ensure that the INSTALL_DIR is created and owned by the user running the script
sudo mkdir -p $INSTALL_DIR
sudo chown $USER $INSTALL_DIR
cd $INSTALL_DIR

# GeoNode GitHub repo
git clone -b 2.4.x https://github.com/ua-snap/geonode.git

# Create geonode user and databases in PSQL
sudo -u postgres psql -c "CREATE USER geonode WITH PASSWORD 'geonode'"
sudo -u postgres psql -c "CREATE DATABASE geonode"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE geonode to geonode"
sudo -u postgres createdb -O geonode geonode_data
sudo -u postgres psql -d geonode_data -c 'CREATE EXTENSION postgis;'
sudo -u postgres psql -d geonode_data -c 'GRANT ALL ON geometry_columns TO PUBLIC;'
sudo -u postgres psql -d geonode_data -c 'GRANT ALL ON spatial_ref_sys TO PUBLIC;'

# Replace a line in the pg_hba.conf file for Postgres
sudo sh -c "sed -e 's/local   all             all                                     peer/local   all             all                                     md5/' < /etc/postgresql/9.3/main/pg_hba.conf > /etc/postgresql/9.3/main/pg_hba.conf.tmp"
sudo mv /etc/postgresql/9.3/main/pg_hba.conf.tmp /etc/postgresql/9.3/main/pg_hba.conf
sudo service postgresql restart

# Add the modified local_settings.py file in GeoNode
cp $INSTALL_DIR/../local_settings.py $INSTALL_DIR/geonode/geonode/local_settings.py

# Set alias for VI to VIM
echo "alias vi='vim'" >> ~/.bashrc

# Set virtual environment variables in BASHRC for user running this script
echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python" >> ~/.bashrc
echo "export WORKON_HOME=~/.venvs" >> ~/.bashrc
echo "source /usr/local/bin/virtualenvwrapper.sh" >> ~/.bashrc
echo "export PIP_DOWNLOAD_CACHE=$HOME/.pip-downloads" >> ~/.bashrc
echo "export INSTALL_DIR=$INSTALL_DIR" >> ~/.bashrc

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

# Download and untar the GDAL 1.11.2 Python package
pip install --download=. --no-use-wheel GDAL==1.11.2
tar -zxvf GDAL-1.11.2.tar.gz

# Edit the gdal_config variable within the setup.cfg of GDAL to point to the correct
# gdal-config location.
sed -e 's/gdal_config = ..\/..\/apps\/gdal-config/gdal_config = \/usr\/bin\/gdal-config/' < GDAL-1.11.2/setup.cfg > GDAL-1.11.2/setup2.cfg
mv GDAL-1.11.2/setup2.cfg GDAL-1.11.2/setup.cfg

# Export the include directory of GDAL to C and C++ include pathes
export CPLUS_INCLUDE_PATH=/usr/include/gdal
export C_INCLUDE_PATH=/usr/include/gdal

# Build the GDAL extensions
cd GDAL-1.11.2
python setup.py build_ext --gdal-config=/usr/local/bin/gdal-config
cd ..

# Install GDAL 1.11.2 Python package
pip install -e GDAL-1.11.2
rm GDAL-1.11.2.tar.gz

# Install all required software for MapProxy
sudo aptitude install -y python-imaging   \
    python-yaml                           \
    libproj0                              \
    libgeos-dev                           \
    python-lxml                           \
    libgdal-dev                           \
    python-shapely                        \ 
    build-essential                       \
    python-dev                            \
    libjpeg-dev                           \
    zlib1g-dev                            \
    libfreetype6-dev

# Install MapProxy and its base configuration
pip install MapProxy
mapproxy-util create -t base-config mapventure-mapproxy
cd mapventure-mapproxy
cp $INSTALL_DIR/../mapventure-mapproxy.yaml mapproxy.yaml 
cd ..

# Increase JVM heap size for GeoServer when launched with Paver to boost
# GeoServer performance, especially with raster overlays.
sed -e "s/-Xmx512m/-Xmx4096m/" < geonode/pavement.py > geonode/pavement2.py
mv geonode/pavement2.py geonode/pavement.py

# Remove default base layers from GeoNode
sed -i'.bak' -r '/^MAP_BASELAYERS/, /}]$/ d' geonode/geonode/settings.py
sed -i'.bak' -r '/^DEFAULT_MAP_ZOOM/ a MAP_BASELAYERS = []' geonode/geonode/settings.py

# Run paver setup and paver sync to get the paver start / stop commands for the
# GeoNode and GeoServer tools.
cd geonode
paver setup
paver sync
cd ..

# Turn of Tomcat since it is unnecessary for running GeoNode / GeoServer
sudo service tomcat7 stop
sudo update-rc.d tomcat7 disable

# Configure PostGIS as the GeoNode backend
cd geonode
pip install psycopg2
python manage.py syncdb --noinput
python manage.py createsuperuser --username=admin --email=ad@m.in --noinput
python manage.py collectstatic --noinput

# Start GeoServer and Django for GeoNode
paver start_geoserver && paver start_django -b 0.0.0.0:8000

echo
echo "A new admin user account has been created but requires a password to be used on the website."
echo "Please do the following manual steps: "
echo "1. vagrant ssh "
echo "2. workon geonode "
echo "3. cd $INSTALL_DIR/geonode "
echo "4. python manage.py changepassword admin "
echo 
echo "Also, MapProxy has been installed to proxy the OSM Humanitarian tiles. You can view MapProxy by running the following commands:"
echo "1. vagrant ssh "
echo "2. workon geonode "
echo "3. mapproxy-util serve-develop -b 0.0.0.0:8888 $INSTALL_DIR/mapventure-mapproxy/mapproxy.yaml "
echo
echo "Build of GeoNode finished."
