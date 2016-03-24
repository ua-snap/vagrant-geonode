#!/usr/bin/python
import urllib2
import os
import subprocess
import json

jsonFeed = 'http://feeder.gina.alaska.edu/radar-uaf-barrow-seaice-geotif.json'
rawGeoTiff = '/tmp/barrow_raw.tif'
processedGeoTiff = '/tmp/barrow_sea_ice_radar.tif'
mapId = 2

response = urllib2.urlopen(jsonFeed)
geoTiffs = json.loads(response.read())
geoTiffUrl = geoTiffs[0]['source']

response = urllib2.urlopen(geoTiffUrl)
localFile = open(rawGeoTiff, 'wb')
localFile.write(response.read())
localFile.close()

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

subprocess.call([
  'python',
  os.environ['INSTALL_DIR'] + '/geonode/manage.py',
  'importlayers',
  '-o',
  processedGeoTiff
])

subprocess.call([
  'python',
  os.environ['INSTALL_DIR'] + '/geonode/manage.py',
  'changemaplayertitle',
  mapId,
  'geonode:barrow_sea_ice_radar',
  geoTiffs[0]['title']
])

os.remove(rawGeoTiff)
os.remove(processedGeoTiff)
