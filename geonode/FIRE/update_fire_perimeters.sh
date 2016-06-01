#! /bin/bash

# If this is running on a local dev VM, we need
# some prefixes
if [ -z "$MV_LOCAL" ]; then
	# Non-local env
	echo "Running in production environment..."
	prefix='geonode'
	export INSTALL_DIR=/home/geonode/
else
	echo "Running in dev VM environment..."
	export INSTALL_DIR=/install/portal/
	prefix=''
fi

# This script updates the Active Fires layer for the current year.
# Maintainer: Bob Torgerson - SNAP (Scenarios Network of Alaska & Arctic Planning)

# Configure geonode's virtual environment
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python
export WORKON_HOME="~$prefix/.venvs"
source `which virtualenvwrapper.sh`

source "$WORKON_HOME/geonode/bin/activate"

# Set the import date and current year. This will automatically collect the current date's
# fire perimeters and update the request from the ArcGIS server based on the current year.
import_date="`date +'%Y-%m-%d %H:%M:%S'`"
current_year="`date +'%Y'`"

# Request the active fire perimeters from the Alaska Fire Service's ArcGIS server
# for the current year.
`which ogr2ogr` active_fire_perimeters.shp http://afs.ak.blm.gov/arcgis/rest/services/MapAndFeatureServices/FirePerimeters/MapServer/1/query\?where\=FIREYEAR+%3D%27$current_year%27\&outFields\=\*\&f\=pjson

# Reproject to 3338
`which ogr2ogr` active_fire_perimeters_3338.shp -t_srs "EPSG:3338" active_fire_perimeters.shp

# Import the current layer with the current updated date. Has a high verbosity of reporting to let
# us be aware of any issues taking place.
`which python` $INSTALL_DIR/geonode/manage.py importlayers -v 3 -d "$import_date" -t "Active Fires" -o active_fire_perimeters_3338.shp

# Remove the current date's active fire perimeter files.
rm -f active_fire_perimeters*
