# SNAP GeoNode

This repo contains notes and utilities for setting up GeoNode for our development environment.

## Development setup

Clone this repo, `vagrant up`, and when that finishes there are some manual steps to be done, [adapted from this site](http://docs.geonode.org/en/latest/tutorials/devel/install_devmode/index.html#install-devmode).  `vagrant ssh` into the box, then:

GeoNode should be available on your host machine at `http://localhost:8000`.

After a restart of the VM, you will need to manually run the following commands to get your development environment running again.

   ```
   workon geonode
   cd /install/portal/geonode
   paver start_geoserver && paver start_django -b 0.0.0.0:8000
   ```

## Production setup

These instructions assume you have already set up a GeoNode development environment by following the instructions above as the user `geonode`. They have been adapted from GeoNode's official [Custom Installation Guide](http://geonode.readthedocs.org/en/latest/tutorials/admin/install/custom_install.html) with many small fixes, clarifications, omissions to avoid redundancy with the rest of our infrastructure, and a few changes specifically for Debian.

Once you complete the production setup instructions, it will not be easy to go back to the development setup. If you need Paver's debugging information for development, stick with the development setup.

1. Make sure Paver is not running:

   ```
   sudo su - geonode
   workon geonode
   cd ~/geonode
   paver stop
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

1. Edit `/install/portal/geonode/geonode/local_settings.py`.

   Add the following two lines to the top of the file:

   ```
   import os
   from settings import PROJECT_ROOT
   ```

   Change this:

   ```
   SITEURL = "http://localhost:8000/"
   ```

   To port 80, like this, even if you are using Vagrant:

   ```
   SITEURL = "http://localhost/"
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

   To the public Apache proxy to GeoServer. For example:

   ```
   OGC_SERVER = {
     'default' : {
       ...
       'LOCATION' : 'http://<public domain>/geoserver/',
       'PUBLIC_LOCATION' : 'http://<public domain>/geoserver/',
       ...
   ```

   And add this to the bottom of the file:

   ```
   ALLOWED_HOST = ['localhost']
   ```

1. Create a `/etc/apache2/sites-available/geonode.conf` Apache configuration file with the following contents:

   ```
   WSGIDaemonProcess geonode python-path=/home/geonode/geonode:/home/geonode/.venvs/geonode/lib/python2.7/site-packages user=www-data threads=15 processes=2

   <VirtualHost *:80>
     ServerName http://localhost
     ServerAdmin webmaster@localhost
     DocumentRoot /home/geonode/geonode/geonode

     ErrorLog /var/log/apache2/error.log
     LogLevel warn
     CustomLog /var/log/apache2/access.log combined

     WSGIProcessGroup geonode
     WSGIPassAuthorization On
     WSGIScriptAlias / /home/geonode/geonode/geonode/wsgi.py

     <Directory "/home/geonode/geonode/geonode/">
       Require all granted
       Options Indexes FollowSymLinks
       IndexOptions FancyIndexing
     </Directory>

     Alias /static/ /home/geonode/geonode/geonode/static_root/
     Alias /uploaded/ /home/geonode/geonode/geonode/uploaded/

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
   sudo mkdir -p /home/geonode/geonode/geonode/uploaded
   sudo chown www-data -R /home/geonode/geonode/geonode/uploaded
   sudo chown www-data:www-data /home/geonode/geonode/geonode/static/
   sudo chown www-data:www-data /home/geonode/geonode/geonode/uploaded/
   sudo chown www-data:www-data /home/geonode/geonode/geonode/static_root/
   sudo service apache2 reload
   ```

1. Edit `/home/geonode/geonode/geoserver/geoserver/WEB-INF/web.xml`.

   Add the following alongside the other `<context-param>` elements:

   ```
   <context-param>
     <param-name>GEONODE_BASE_URL</param-name>
     <param-value>http://localhost/</param-value>
   </context-param>
   ```

1. Edit `/home/geonode/geonode/geoserver/data/security/auth/geonodeAuthProvider/config.xml`.

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
   sudo cp /home/geonode/geonode/downloaded/geoserver.war /var/lib/tomcat7/webapps/
   sudo service tomcat7 restart
   ```

1. Visit `http://<public domain>/` in your browser. Everything should now be working.

## Creating and Restoring from Backups

This section can be used to either create a backup of GeoNode and GeoServer from a production or development environment and restoring this backup on either a development or production environment.

### Create a backup

1. While on the development or production server, run the following command in the directory where you want to keep the backup.

   ```
   bash <path_to_backup.sh>
   On Vagrant VM: bash /install/backup.sh
   ```

   This will result in a backup file which you can use to restore from in the next section.

### Restore from a backup

1. While on the development or production server that you want to restore on, run the following command in a directory you have write privileges to:

   #### Production-to-production or development-to-development
   ```
   bash <path-to-restore.sh> <full-path-to-backup.tgz>
   An example on Vagrant VM: bash /install/restore.sh /install/backup-08-13-2015.tgz
   ```

   This will take a minute or so, but will result in a copy of the PostGIS database, GeoNode uploaded layers, and GeoServer layers that are queried by GeoNode.

   #### Production-to-development or development-to-production

   You can also restore a production backup into a development environment (or vice versa) by providing options to the `restore.sh` script.

   To restore a backup from a production server into a development environment:

   ```
   bash <path-to-restore.sh> -p <production-domain> -f <full-path-to-backup.tgz>
   Example: bash /install/restore.sh -p geonode.example.com -f /install/backup-08-13-2015.tgz
   ```

   To restore a backup from a development environment into a production server:

   ```
   bash <path-to-restore.sh> -p <production-domain> -t <full-path-to-backup.tgz>
   Example: bash /install/restore.sh -p geonode.example.com -t /install/backup-08-13-2015.tgz
   ```

   Remember, the `-f` option means "from production" and the `-t` option means "to production".
