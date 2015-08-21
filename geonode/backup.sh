#! /bin/bash
# This script is meant to make a backup for GeoNode and GeoServer
# of the current date. It dumps the PostgreSQL databases, copies
# all files that were uploaded in GeoNode, and copies all of the
# directories in the GeoServer data directory. It finally gzips
# the tar file of the created backup directory.

# Name of the backup. Has date included in the backup name e.g.
# backup-08-13-2015
BACKUP_NAME="backup-$(date +%m-%d-%Y)"

# Make the backup directory
mkdir $BACKUP_NAME

echo
echo "Creating backup in $BACKUP_NAME.tgz..."
# Dump all databases in the PostgreSQL database
sudo -u postgres pg_dumpall > $BACKUP_NAME/geonode-backup.sql

# Copy all uploaded geospatial layers and their thumbnails to backup
cp -r $INSTALL_DIR/geonode/geonode/uploaded/ $BACKUP_NAME/

# Copy all of the GeoServer data to the backup
cp -r $INSTALL_DIR/geonode/geoserver/data $BACKUP_NAME/

# Tar and gzip the backup
tar zcf $BACKUP_NAME.tgz $BACKUP_NAME

# Remove the backup directory
rm -rf $BACKUP_NAME

echo
echo "Backup finished."
