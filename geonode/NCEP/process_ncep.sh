#! /bin/bash
set -x

# rm -rf /tmp/ncep
mkdir -p /tmp/ncep

# Download this & last year's NetCDF files.
this_year=`date +%Y`
last_year=$((this_year - 1))

# Skip download?
DOWNLOAD=true

# Since the new data is only released on the 8th of each month,
# if we are not on the 9th of the month, do not try to go to the new data.
if [ "`date +%d`" -ge "09" ]; then
  req_date="`date +%Y%m`"
  import_date="`date +'%Y-%m-%d %H:%M:%S'`"
else
  req_date="`date +%Y%m --date='-1 month'`"
  import_date="`date --date='-1 month' +'%Y-%m-%d %H:%M:%S'`"
fi

# http://ftp.cpc.ncep.noaa.gov/NMME/realtime_anom/CFSv2/2016010800/
# Fetch files
tmp2m_file="tmp2m.${req_date}0100.01.CFSv2.anom.avrg.1x1.grb"
if [ ! -f /tmp/ncep/$tmp2m_file ]; then
	wget -O "/tmp/ncep/$tmp2m_file" "ftp://ftp.cpc.ncep.noaa.gov/NMME/realtime_anom/CFSv2/${req_date}0800/$tmp2m_file"
fi

gdal_translate \
	-of Gtiff \
	-b 1 \
	/tmp/ncep/$tmp2m_file \
	/tmp/ncep/ncep_projected_wrong_center.tif

gdalwarp \
	-nomd \
	-overwrite \
	-multi \
	-r bilinear \
	-t_srs "EPSG:4326" \
	-tr 1 1 \
	-te -180 -90 180 90 \
	-wo "SOURCE_EXTRA=50" \
	/tmp/ncep/ncep_projected_wrong_center.tif \
	/tmp/ncep/ncep_projected_greenwich.tif

gdalwarp \
	-nomd \
	-overwrite \
	-multi \
	-r bilinear \
	-t_srs "EPSG:3572" \
	-wo "SOURCE_EXTRA=50" \
	-dstnodata 9999 \
	-dstalpha \
	/tmp/ncep/ncep_projected_greenwich.tif \
	/tmp/ncep/ncep_projected_epsg3572.tif

gdalwarp \
	-nomd \
	-overwrite \
	-cutline "40N_epsg3572.shp" \
	-crop_to_cutline \
	-srcnodata 9999 \
	-dstnodata 9999 \
	-dstalpha \
	/tmp/ncep/ncep_projected_epsg3572.tif \
	/tmp/ncep/ncep_projected_air_temp_k.tif

gdal_calc.py \
	--overwrite \
	--NoDataValue=9999 \
	-A /tmp/ncep/ncep_projected_air_temp_k.tif \
	--calc "A+273.15" \
	--outfile /tmp/ncep/ncep_projected_air_temp.tif

`which python` \
	$INSTALL_DIR/geonode/manage.py \
	importlayers \
	-d "$import_date" \
	-o "/tmp/ncep/ncep_projected_air_temp.tif"

# Historical data
if $DOWNLOAD; then
	wget -O "air.sig995.$this_year.nc" "ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis/surface/air.sig995.$this_year.nc"
	wget -O "air.sig995.$last_year.nc" "ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis/surface/air.sig995.$last_year.nc"
fi

# Which historical dates do we fetch?
dates=('-2 days'
       '-7 days'
       '-1 month'
       '-1 year')

# Set up environment so we can talk to GeoNode
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python
export WORKON_HOME=$HOME/.venvs
source `which virtualenvwrapper.sh`
export PIP_DOWNLOAD_CACHE=$HOME/.pip-downloads
workon geonode

for cur_date in "${dates[@]}"; do
	year=`date --date="$cur_date" +%Y`
	day_of_year=`date --date="$cur_date" +%j`

	# Create a stable layer name for insert into GeoNode
	name=${cur_date/ /_}
	layername="${name/-/}_ago"

	# This isolates the band in the NetCDF file corresponding
	# to noon for the given day.
	# The 10#$ prefix casts the day of year to integer,
	# which otherwise can be interpreted as octal because
	# of preceeding zeros in the date.
	desired_band=$((4 * (10#$day_of_year - 1) + 3))

	echo "$year"
	echo "$desired_band"

	# select the variable we want and convert the series to a multiband GTiff
	gdal_translate -a_srs WGS84 \
		NETCDF:"air.sig995.$year.nc":air \
		-b $desired_band \
		/tmp/ncep/ncep_historical_${layername}_base.tif

	# rotate longitudes from pacific-centered latlong and into greenwich-centered latlong (global extent)
	gdalwarp \
		-overwrite \
		-tr 2.5 2.5 \
		-tap \
		-r bilinear \
		-te -180 -90 180 90 \
		-multi \
		-t_srs WGS84 \
		-wo "SOURCE_EXTRA=10" \
		/tmp/ncep/ncep_historical_${layername}_base.tif \
		/tmp/ncep/ncep_historical_${layername}_greenwich.tif

	# warp to polar -- GDAL 1.9.1 seems to have issues reprojecting from anything but the full WGS84 extent to the 3572.
	gdalwarp \
		-overwrite \
		-r bilinear \
		-multi \
		-s_srs WGS84 \
		-t_srs EPSG:3572 \
		/tmp/ncep/ncep_historical_${layername}_greenwich.tif \
		/tmp/ncep/ncep_historical_${layername}_epsg3572.tif

	# clip the data with a cutline -- (see below for cutline generation example)
	gdalwarp \
		-overwrite \
		-r bilinear \
		-multi \
		-t_srs EPSG:3572 \
		-cutline "40N_epsg3572.shp" \
		-crop_to_cutline \
		/tmp/ncep/ncep_historical_${layername}_epsg3572.tif \
		/tmp/ncep/ncep_historical_${layername}_clipped.tif

	# convert it to Celcius from Kelvin (-273.15)
	gdal_calc.py \
		--overwrite \
		-A /tmp/ncep/ncep_historical_${layername}_clipped.tif \
		--calc "A-273.15" \
		--outfile /tmp/ncep/ncep_historical_${layername}.tif

	# \ # reconstruct canonical map with these layers
	# \ # specify the date this data comes from
	# \ # rename MapLayer??
    `which python` \
    	$INSTALL_DIR/geonode/manage.py \
    	importlayers \
	-d "`date --date="$cur_date" +'%Y-%m-%d %H:%M:%S'`" \
    	-o $tif_name \
    	/tmp/ncep/ncep_historical_$layername.tif

done

