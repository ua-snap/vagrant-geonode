#! /bin/bash
BACKUP_NAME="backup-$(date +%m-%d-%Y)"
mkdir $BACKUP_NAME
sudo -u postgres pg_dumpall > $BACKUP_NAME/geonode-backup.sql
cp -r $INSTALL_DIR/geonode/geonode/uploaded/ $BACKUP_NAME/
cp -r $INSTALL_DIR/geonode/geoserver/data $BACKUP_NAME/
tar zcf $BACKUP_NAME.tgz $BACKUP_NAME
rm -rf $BACKUP_NAME
