#! /bin/bash
BACKUP_NAME=`echo "$1" | cut -d'.' -f1`

tar zxf $1
cd $BACKUP_NAME
sudo -u postgres dropdb geonode
sudo -u postgres dropdb geonode_data
sudo -u postgres psql < geonode-backup.sql
cp -r uploaded $INSTALL_DIR/geonode/geonode/
cp -r data $INSTALL_DIR/geonode/geoserver/
paver stop
paver start_geoserver && paver start_django -b 0.0.0.0:8000
