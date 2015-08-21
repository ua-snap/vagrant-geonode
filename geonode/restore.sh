#! /bin/bash
# This script is meant to restore from a gzipped tar file
# built by the script backup.sh. It requires an input argument
# of the gzipped tar file path. Here is an example run of the
# script: bash ./restore.sh /install/backup-08-13-2015.tgz

# Verify that an argument has been supplied to the restore script
if [ $# -eq 0 ]; then
  echo
  echo "No arguments supplied to script."
  echo "Please provide the full path to a gzipped tar file containing a backup."
  echo
else

  # This generates the basename of the gzipper tar file
  BACKUP_NAME=`basename "$1" | cut -d'.' -f1`

  # Unzip and untar the backup directory
  echo 
  echo "Untarring backup..."
  tar zxf $1 -C $PWD > /dev/null 2>&1

  # Descend into the backup
  cd $BACKUP_NAME
  
  # Drop the databases that conflict with the backup
  echo
  echo "Dropping and restoring databases..."
  sudo -u postgres dropdb geonode > /dev/null 2>&1
  sudo -u postgres dropdb geonode_data > /dev/null 2>&1

  # Restore the databases from a SQL dump
  sudo -u postgres psql < geonode-backup.sql > /dev/null 2>&1

  # Copy the uploaded GeoNode data to GeoNode's installed directory
  echo
  echo "Moving GeoNode and GeoServer directories into place..."
  cp -r uploaded $INSTALL_DIR/geonode/geonode/

  # Copy the GeoServer data directory to its required location
  cp -r data $INSTALL_DIR/geonode/geoserver/
  
  # Remove the untarred backup
  cd ..
  rm -rf $BACKUP_NAME

  # Export and source the virtual environment for the script 
  export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python
  export WORKON_HOME=$HOME/.venvs
  source `which virtualenvwrapper.sh`
  export PIP_DOWNLOAD_CACHE=$HOME/.pip-downloads

  # Workon the geonode virtual environment
  workon geonode

  # Change directories to GeoNode
  cd $INSTALL_DIR/geonode

  # Restart GeoServer and GeoNode for them to get latest changes
  echo
  echo "Restarting GeoNode and GeoServer..."
  echo "This can take a minute..."
  paver stop > /dev/null 2>&1
  paver start_geoserver > /dev/null 2>&1 && paver start_django -b 0.0.0.0:8000 > /dev/null 2>&1

  echo 
  echo "Backup restored."
fi
