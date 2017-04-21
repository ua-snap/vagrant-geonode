#! /bin/bash
# This script is meant to restore from a gzipped tar file
# built by the script backup.sh. It requires an input argument
# of the gzipped tar file path. Here is an example run of the
# script: bash ./restore.sh /install/backup-08-13-2015.tgz

if [ $INSTALL_DIR ]; then
  VAGRANT=true
fi

# Process options
while getopts ":p:fth" opt; do
  case $opt in
    p) PROD_DOMAIN=$OPTARG ;;
    t) DEV_TO_PROD=true ;;
    f) PROD_TO_DEV=true ;;
    h) HELP=true ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

if [ "$DEV_TO_PROD" -a "$PROD_TO_DEV" ]; then
  echo
  echo "Error: You cannot set both the -t and -f flags."
fi

# Offset option index to first non-optional argument
shift $((OPTIND-1))

# Show help if requested or if a backup file has not been provided
if [ "$HELP" -o $# -eq 0 ]; then
  echo
  echo "Syntax: restore.sh [-p <production-domain>] [-t|-f] <backup-file>"
  echo
  echo "-p  <production-domain>  domain of the live server (e.g., geonode-test.iarc.uaf.edu)"
  echo "-t  to production from development"
  echo "-f  from production to development"
  echo "<backup-file>  backup .tgz file created by backup.sh script"
  echo
else
  # This generates the basename of the gzipper tar file
  BACKUP_NAME=`basename "$1" | cut -d'.' -f1`

  # Unzip and untar the backup directory
  echo 
  echo "Untarring backup..."
  mkdir -p $PWD/$BACKUP_NAME
  tar zxf $1 -C $PWD/$BACKUP_NAME --strip-components=1 > /dev/null 2>&1

  # Descend into the backup
  cd $BACKUP_NAME
  
  if [ $PROD_DOMAIN ]; then
    PROD_GEOSERVER_URL="$PROD_DOMAIN:8080/geoserver"
    PROD_GEOSERVER_PATH="/var/lib/tomcat7/webapps/geoserver"
    PROD_GEONODE="$PROD_DOMAIN:8000/"
    PROD_LOCALHOST="localhost/"

    DEV_GEOSERVER_URL="localhost:8080/geoserver"
    DEV_GEOSERVER_PATH="/install/portal/geonode/geoserver"
    DEV_GEONODE="localhost:8000/"
    DEV_LOCALHOST="localhost:8000/"

    # Escape slashes and dots to prepare our replacement patterns for sed
    PROD_GEOSERVER_URL=`echo $PROD_GEOSERVER_URL | perl -pe 's/(\.|\/)/\\\\$1/g'`
    PROD_GEOSERVER_PATH=`echo $PROD_GEOSERVER_PATH | perl -pe 's/(\.|\/)/\\\\$1/g'`
    PROD_GEONODE=`echo $PROD_GEONODE | perl -pe 's/(\.|\/)/\\\\$1/g'`
    PROD_LOCALHOST=`echo $PROD_LOCALHOST | perl -pe 's/(\.|\/)/\\\\$1/g'`

    DEV_GEOSERVER_URL=`echo $DEV_GEOSERVER_URL | perl -pe 's/(\.|\/)/\\\\$1/g'`
    DEV_GEOSERVER_PATH=`echo $DEV_GEOSERVER_PATH | perl -pe 's/(\.|\/)/\\\\$1/g'`
    DEV_GEONODE=`echo $DEV_GEONODE | perl -pe 's/(\.|\/)/\\\\$1/g'`
    DEV_LOCALHOST=`echo $DEV_LOCALHOST | perl -pe 's/(\.|\/)/\\\\$1/g'`

    if [ $PROD_TO_DEV ]; then
      echo
      echo "Restoring from $PROD_DOMAIN to development server."
      for FILE in `find . -type f`; do
        sed -i "s/$PROD_GEOSERVER_URL/$DEV_GEOSERVER_URL/g" $FILE
        sed -i "s/$PROD_GEOSERVER_PATH/$DEV_GEOSERVER_PATH/g" $FILE
        sed -i "s/$PROD_GEONODE/$DEV_GEONODE/g" $FILE
        sed -i "s/$PROD_LOCALHOST/$DEV_LOCALHOST/g" $FILE
      done
    elif [ $DEV_TO_PROD ]; then
      echo
      echo "Restoring from development server to $PROD_DOMAIN."
      for FILE in `find . -type f`; do
        sed -i "s/$DEV_GEOSERVER_URL/$PROD_GEOSERVER_URL/g" $FILE
        sed -i "s/$DEV_GEOSERVER_PATH/$PROD_GEOSERVER_PATH/g" $FILE
        sed -i "s/$DEV_GEONODE/$PROD_GEONODE/g" $FILE
        sed -i "s/$DEV_LOCALHOST/$PROD_LOCALHOST/g" $FILE
      done
    fi
  fi

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

  if [ $VAGRANT ]; then
    rm -rf $INSTALL_DIR/geonode/geonode/uploaded
    rm -rf $INSTALL_DIR/geonode/geoserver/data
    cp -r uploaded $INSTALL_DIR/geonode/geonode/
    cp -r data $INSTALL_DIR/geonode/geoserver/
  else
    GEONODE_DIR=/home/geonode/geonode/geonode
    GEOSERVER_DIR=/var/lib/tomcat7/webapps/geoserver
    sudo rm -rf $GEONODE_DIR/uploaded
    sudo rm -rf $GEOSERVER_DIR/data
    sudo cp -r uploaded $GEONODE_DIR/
    sudo cp -r data $GEOSERVER_DIR/
    sudo chown -R www-data:www-data $GEONODE_DIR/uploaded
    sudo chown -R tomcat7:tomcat7 $GEOSERVER_DIR/data
    find $GEOSERVER_DIR/data -type d -exec sudo chmod 775 '{}' +
  fi

  # Remove the untarred backup
  cd ..
  rm -rf $BACKUP_NAME

  # Export and source the virtual environment for the script 
  export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python
  export WORKON_HOME=$HOME/.venvs
  source `which virtualenvwrapper.sh`
  export PIP_DOWNLOAD_CACHE=$HOME/.pip-downloads

  # Restart GeoServer and GeoNode for them to get latest changes
  echo
  echo "Restarting GeoNode and GeoServer..."
  echo "This can take a minute..."

  if [ $VAGRANT ]; then
    # Workon the geonode virtual environment
    workon geonode

    # Change directories to GeoNode
    cd $GEONODE_DIR

    paver stop > /dev/null 2>&1
    paver start_geoserver > /dev/null 2>&1 && paver start_django -b 0.0.0.0:8000 > /dev/null 2>&1
  else
    sudo service tomcat7 restart
  fi

  echo 
  echo "Backup restored."
fi
