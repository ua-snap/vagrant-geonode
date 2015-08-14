#! /bin/bash

GEONODE_DIR=/install/portal/geonode/
MAPLOOM_DIR=/install/portal/MapLoom/
SNAPMAP_DIR=/install/portal/snap-arctic-portal/
DJANGO_MAPLOOM_DIR=/install/portal/django-maploom/

# Export virtual environment variables
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python
export WORKON_HOME=$HOME/.venvs
source `which virtualenvwrapper.sh`
export PIP_DOWNLOAD_CACHE=$HOME/.pip-downloads

# Work on the GeoNode virtual environment
workon geonode

# Update, compile, and move the new MapLoom code into place
cd $MAPLOOM_DIR
git pull > /tmp/up2date.txt
UP2DATE=`cat /tmp/up2date.txt`
if [ "$UP2DATE" = "Already up-to-date." ]; then
  echo "MapLoom is already up-to-date. Not recompiling code."
else
  npm install && bower install && grunt
  cp -f bin/assets/MapLoom-1.2.0.js $DJANGO_MAPLOOM_DIR/maploom/static/maploom/assets/MapLoom-1.2.js
fi

# Update the snapmapapp code
cd $SNAPMAP_DIR
git checkout snapmapapp > /dev/null 2>&1
git pull

echo "GeoNode has been updated."
