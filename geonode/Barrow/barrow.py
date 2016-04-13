#!/usr/bin/python
import urllib2
import os
import subprocess
import json
import re
from datetime import datetime

jsonFeed = 'http://feeder.gina.alaska.edu/radar-uaf-barrow-seaice-geotif.json'
rawGeoTiff = '/tmp/barrow_raw.tif'
processedGeoTiff = '/tmp/barrow_sea_ice_radar.tif'

# Download and parse GINA's Barrow sea ice GeoTIFF feed.
# The first element in the feed is the most recent GeoTIFF.
response = urllib2.urlopen(jsonFeed)
geoTiffs = json.loads(response.read())
latestGeoTiff = geoTiffs[0]

# Grab the latest GeoTIFF's creation date, throwing out the time zone because
# strptime() is not able to parse the time zone in this format.
match = re.search('^.*(?=-0[8-9]:00$)', latestGeoTiff['created_at'])
dateObject = datetime.strptime(match.group(0), '%Y-%m-%dT%H:%M:%S')

# Format the date as needed for GeoNode's importlayers management command.
dateString = dateObject.strftime('%Y-%m-%d %H:%M:%S')

# Download and save the GeoTIFF file.
geoTiffUrl = latestGeoTiff['source']
response = urllib2.urlopen(geoTiffUrl)
localFile = open(rawGeoTiff, 'wb')
localFile.write(response.read())
localFile.close()

# Georeference the GeoTIFF in EPSG:3857 and make the background transparent.
subprocess.call([
  'gdalwarp',
  '-s_srs',
  '+proj=aeqd +lat_0=71.2925 +lon_0=-156.788333333333 +x_0=0 +y_0=0 +a=6358944.3 +b=6358944.3 +units=m +no_defs',
  '-t_srs',
  'EPSG:3857',
  '-of',
  'GTiff',
  '-srcnodata',
  '0',
  '-dstalpha',
  rawGeoTiff,
  processedGeoTiff
])

# Import the GeoTIFF over the existing Barrow sea ice layer in GeoNode, and
# update its publication date with the GeoTIFF's creation date.
subprocess.call([
  'python',
  os.environ['INSTALL_DIR'] + '/geonode/manage.py',
  'importlayers',
  '-d',
  dateString,
  '-o',
  processedGeoTiff
])

# Rename the Barrow sea ice map layer with the title from the JSON feed.
subprocess.call([
  'python',
  os.environ['INSTALL_DIR'] + '/geonode/manage.py',
  'changemaplayertitle',
  '32',
  'geonode:barrow_sea_ice_radar',
  latestGeoTiff['title']
])

# Clean up temporary files so we don't get warnings from GDAL in the future.
os.remove(rawGeoTiff)
os.remove(processedGeoTiff)
