# SNAP GeoNode

This repo contains notes and utilities for setting up GeoNode for our development environment.

## Development setup

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
   * Edit the `geonode/settings.py` file, in the JSON data structure `OGC_SERVER: default:` change `'LOCATION'` to `http://0.0.0.0:8080/geoserver/`.


 * Stop Tomcat to free up port 8080 for GeoServer, then run GeoNode and GeoServer:

   ```
   sudo service tomcat7 stop
   paver start_geoserver && paver start_django -b 0.0.0.0:8000
   ```

GeoNode should be available on your host machine at `http://localhost:8000`.

### Add MapLoom

1. Make sure Paver is not running:

   ```
   workon geonode
   cd ~/geonode
   paver stop
   ```

1. Install the `django-maploom` into the `geonode` virtual environment:

   ```
   cd ~
   git clone https://github.com/ROGUE-JCTD/django-maploom.git
   pip install -e django-maploom
   ```   

1. Edit `~/geonode/geonode/settings.py`, adding `maploom` to `INSTALLED_APPS` like this:

   ```
   INSTALLED_APPS = (
     ...
     'maploom',
   ) + GEONODE_APPS
   ```

1. Edit `~/geonode/geonode/urls.py`, adding the following lines:

   ```
   from maploom.geonode.urls import urlpatterns as maploom_urls

   # After the section where urlpatterns is declared
   urlpatterns += maploom_urls
   ```

1. Restart Paver if it's not already running:

   ```
   cd ~/geonode
   paver start_geoserver && paver start_django -b 0.0.0.0:8000
   ```

This is all it takes for MapLoom to **almost** work right, except that because GeoServer requests are not proxied through the same port as GeoNode, your web browser will report same-origin-policy errors when you try to create or view a map. A quick fix for a development environment is to simply disable the same-origin-policy on your browser. This can be done in Chrome using the [Allow-Control-Allow-Origin: * extension](https://chrome.google.com/webstore/detail/allow-control-allow-origi/nlfbmbojpeacfghkpbjhddihlkkiljbi?hl=en). The proper fix for a production environment is to proxy GeoServer requests through the same port as GeoNode via Apache, which is described in the production setup instructions below.

## Production setup

These instructions assume you have already set up a GeoNode development environment by following the instructions above. They have been adapted from GeoNode's official [Custom Installation Guide](http://geonode.readthedocs.org/en/latest/tutorials/admin/install/custom_install.html) with many small fixes, clarifications, additions for MapLoom support, omissions to avoid redundancy with the rest of our infrastructure, and a few changes specifically for Debian.

Once you complete the production setup instructions, it will not be easy to go back to the development setup due to port, permission, and database changes. In the future we might be able to make it easier to switch between the two, but for now, if you need Paver's debugging information for development, stick with the development setup and bypassing the same-origin-policy in your browser.

1. Make sure Paver is not running:

   ```
   workon geonode
   cd ~/geonode
   paver stop
   ```

1. Run the following commands to set up a PostGIS database to be used in place of the development SQLite database:

   ```
   sudo -u postgres createdb -O geonode geonode_data
   sudo su postgres
   psql -d geonode_data -c 'CREATE EXTENSION postgis;'
   psql -d geonode_data -c 'GRANT ALL ON geometry_columns TO PUBLIC;'
   psql -d geonode_data -c 'GRANT ALL ON spatial_ref_sys TO PUBLIC;'
   exit
   ```
1. Edit `/etc/postgresql/9.4/main/pg_hba.conf`.

   Change this line:

   ```
   local   all         all        peer
   ```

   To:

   ```
   local   all         all        md5
   ```

   And add this line to the bottom of the file:

   ```
   host    geonode     geonode    127.0.0.1/32    md5
   ```

1. Restart the PostgreSQL server:

   ```
   sudo service postgresql restart
   ```

1. Create a `local_settings.py` file:

   ```
   cd ~/geonode/geonode
   cp local_settings.py.sample local_settings.py
   ```

1. Edit `~/geonode/geonode/local_settings.py`.

   Add the following two lines to the top of the file:

   ```
   import os
   from settings import PROJECT_ROOT
   ```

   Change this:

   ```
   SITEURL = "http://localhost:8000/"
   ```

   To port 80 for production (as shown here) or to port 8888 if this is inside of Vagrant:

   ```
   SITEURL = "http://localhost/"
   ```

   Change this:

   ```
   'datastore' : {
     #'ENGINE': 'django.contrib.gis.db.backends.postgis',
     'ENGINE': '', # Empty ENGINE name disables
     'NAME': 'geonode',
     ...
   }
   ```

   To:

   ```
   'datastore' : {
     'ENGINE': 'django.contrib.gis.db.backends.postgis',
     'NAME': 'geonode_data',
     ...
   }
   ```

   Change these URLs:

   ```
   OGC_SERVER = {
     'default' : {
       ...
       'LOCATION' : 'http://localhost:8080/geoserver/',
       'PUBLIC_LOCATION' : 'http://localhost:8080/geoserver/',
       ...
   ```

   To the Apache port, which is port 80 on a production server (as shown here) or port 8888 if you are setting this up in Vagrant:

   ```
   OGC_SERVER = {
     'default' : {
       ...
       'LOCATION' : 'http://localhost/geoserver/',
       'PUBLIC_LOCATION' : 'http://localhost/geoserver/',
       ...
   ```

   And add this to the bottom of the file:

   ```
   ALLOWED_HOST = ['localhost']
   ```

1. Perform the following Django setup steps to sync the database, set up a superuser account, etc.:

   ```
   cd ~/geonode
   pip install psycopg2
   python manage.py syncdb --noinput
   python manage.py createsuperuser
   python manage.py collectstatic
   ```

1. Create a `/etc/apache2/sites-available/geonode.conf` Apache configuration file with the following contents:

   ```
   WSGIDaemonProcess geonode python-path=/home/vagrant/geonode:/home/vagrant/.venvs/geonode/lib/python2.7/site-packages user=www-data threads=15 processes=2

   <VirtualHost *:80>
     ServerName http://localhost
     ServerAdmin webmaster@localhost
     DocumentRoot /home/vagrant/geonode/geonode

     ErrorLog /var/log/apache2/error.log
     LogLevel warn
     CustomLog /var/log/apache2/access.log combined

     WSGIProcessGroup geonode
     WSGIPassAuthorization On
     WSGIScriptAlias / /home/vagrant/geonode/geonode/wsgi.py

     <Directory "/home/vagrant/geonode/geonode/">
       Require all granted
       Options Indexes FollowSymLinks
       IndexOptions FancyIndexing
     </Directory>

     Alias /static/ /home/vagrant/geonode/geonode/static_root/
     Alias /uploaded/ /home/vagrant/geonode/geonode/uploaded/

     <Proxy *>
       Order allow,deny
       Allow from all
     </Proxy>

     ProxyPreserveHost On
     ProxyPass /geoserver http://localhost:8080/geoserver
     ProxyPassReverse /geoserver http://localhost:8080/geoserver
   </VirtualHost>
   ```

1. Set up the Apache environment by running the following commands:

   ```
   sudo a2dissite 000-default
   sudo a2ensite geonode
   sudo a2enmod proxy_http
   sudo mkdir -p /home/vagrant/geonode/geonode/uploaded
   sudo chown www-data -R /home/vagrant/geonode/geonode/uploaded
   sudo chown www-data:www-data /home/vagrant/geonode/geonode/static/
   sudo chown www-data:www-data /home/vagrant/geonode/geonode/uploaded/
   sudo chown www-data:www-data /home/vagrant/geonode/geonode/static_root/
   sudo service apache2 reload
   ```

1. Edit `~/geonode/geoserver/geoserver/WEB-INF/web.xml`.

   Add the following alongside the other `<context-param>` elements:

   ```
   <context-param>
     <param-name>GEONODE_BASE_URL</param-name>
     <param-value>http://localhost/</param-value>
   </context-param>
   ```

1. Edit `~/geonode/geoserver/data/security/auth/geonodeAuthProvider/config.xml`.

   Change this line:

   ```
   <baseUrl>http://localhost:8000/</baseUrl>
   ```

   To:

   ```
   <baseUrl>http://localhost/</baseUrl>
   ```

1. Copy the GeoServer webapp into Tomcat's webapp directory:

   ```
   sudo cp ~/geonode/downloaded/geoserver.war /var/lib/tomcat7/webapps/
   sudo service tomcat7 restart
   ```

1. Copy MapLoom's static files into the new `static_root` directory, as Apache's new alias for /static breaks this otherwise:

   ```
   cp -r ~/django-maploom/maploom/static/maploom ~/geonode/geonode/static_root/
   ```

1. Everything should now be working. If this was performed on a real server, load the GeoNode website over port 80. If this was performed in a Vagrant host, load the GeoNode website at http://localhost:8888 on the host machine.
