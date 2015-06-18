# SNAP GeoNode

This repo contains notes and utilities for setting up GeoNode for our development environment.

## Setup

Clone this repo, `vagrant up`, and when that finishes there are some manual steps to be done, [adapted from this site](http://docs.geonode.org/en/latest/tutorials/devel/install_devmode/index.html#install-devmode).  `vagrant ssh` into the box, then:

 * Postgres:

   ```
   sudo passwd -u postgres # change password expiry information
   sudo passwd postgres # change unix password for postgres
   su postgres
   psql
   (postgres=#) \password postgres
   (postgres=#) CREATE USER geonode WITH PASSWORD 'geonode';
   (postgres=#) CREATE DATABASE "geonode";
   (postgres=#) GRANT ALL PRIVILEGES ON DATABASE "geonode" to geonode;
   (postgres=#) \q
   ```

 * Then, `exit` to return to default Vagrant user, and add to `~/.bashrc`:

   ```
   export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python
   export WORKON_HOME=~/.venvs
   source /usr/local/bin/virtualenvwrapper.sh
   export PIP_DOWNLOAD_CACHE=$HOME/.pip-downloads
   ```

 * `source ~/.bashrc` then make the `geonode` directory a virtualenv:

   ```
   mkvirtualenv geonode
   workon geonode
   pip install -e geonode
   ```

 * Download and extract GDAL Python module without installing it:

   ```
   pip install --download=. --no-use-wheel GDAL==1.10.0
   tar -zxvf GDAL-1.10.0.tar.gz
   cd GDAL-1.10.0
   ```

 * Modify the following line in `setup.cfg`:

   ```
   gdal_config = ../../apps/gdal-config
   ```

   To:

   ```
   gdal_config = /usr/bin/gdal-config
   ```

 * Run the following commands to modify and install the GDAL module:

   ```
   export CPLUS_INCLUDE_PATH=/usr/include/gdal
   export C_INCLUDE_PATH=/usr/include/gdal
   python setup.py build_ext --gdal-config=/usr/local/bin/gdal-config
   cd ..
   pip install -e GDAL-1.10.0
   rm GDAL-1.10.0.tar.gz
   ```

 * Preparing to run the Geonode server:

   ```
   cd geonode
   paver setup
   paver sync
   ```

 * Modify the IP addresses so we can see it from our host machine.

   * Edit the `pavement.py` file, around line 348 change the url to be `http://0.0.0.0:8080/geoserver/`
   * Edit the `geonode/settings.py` file, around line 504 change `'LOCATION'` to `http://0.0.0.0:8080/geoserver/`.

 * Run the server:

   ```
   paver start_geoserver && paver start_django -b 0.0.0.0:8000
   ```

GeoNode should be available on your host machine at `http://localhost:8888`.
