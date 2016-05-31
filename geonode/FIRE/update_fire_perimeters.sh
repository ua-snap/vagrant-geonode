#! /bin/bash

# This script updates the Active Fires layer for the current year.
# Maintainer: Bob Torgerson - SNAP (Scenarios Network of Alaska & Arctic Planning)

# Configure geonode's virtual environment
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python
export WORKON_HOME=~geonode/.venvs
source `which virtualenvwrapper.sh`
export PIP_DOWNLOAD_CACHE=~geonode/.pip-downloads
export INSTALL_DIR=/home/geonode/
source .venvs/geonode/bin/activate

# Set the import date and current year. This will automatically collect the current date's 
# fire perimeters and update the request from the ArcGIS server based on the current year.
import_date="`date +'%Y-%m-%d %H:%M:%S'`"
current_year="`date +'%Y'`"

# Request the active fire perimeters from the Alaska Fire Service's ArcGIS server
# for the current year.
`which ogr2ogr` active_fire_perimeters.shp http://afs.ak.blm.gov/arcgis/rest/services/MapAndFeatureServices/FirePerimeters/MapServer/1/query\?where\=FIREYEAR+%3D%27$current_year%27\&outFields\=\*\&f\=pjson

# Import the current layer with the current updated date. Has a high verbosity of reporting to let
# us be aware of any issues taking place. 
`which python` $INSTALL_DIR/geonode/manage.py importlayers -v 3 -d "$import_date" -t "Active Fires" -o active_fire_perimeters.shp

# Remove the current date's active fire perimeter files.
rm -f active_fire_perimeters.*
