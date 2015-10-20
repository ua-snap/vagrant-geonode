#! /bin/bash
# This script is necessary to parse the returned HTML for the file name of the created NetCDF data as this has no
# deterministic naming schema that could be expected by a script for automation of data capture. This script downloads
# the NetCDF data, renames it to a more recognizable file name (i.e. daily, weekly, etc.) and then uses GDAL to create
# a GeoTIFF from the NetCDF file. These raster files are currently being output in EPSG:4326, which matches the GeoNode's
# default projection for its OpenLayers maps.

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

nc_variables=('Air+Temperature'
	      'Sea+Surface+Temperature')

file_names=('air_temperature'
	    'sea_surface_temperature')

var_names=('air'
           'skt')

dates=('-2 days'
       '-7 days'
       '-1 month'
       '-1 year')

printf "\n${RED}########################################################################\n"
printf "#######################${YELLOW}[NCEP Historical Data]${RED}###########################\n"
printf "########################################################################${NC}\n"

total_vars=${#nc_variables[*]}

export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python
export WORKON_HOME=$HOME/.venvs
source `which virtualenvwrapper.sh`
export PIP_DOWNLOAD_CACHE=$HOME/.pip-downloads
workon geonode

for (( i=0; i< $(($total_vars)); i++)); do
  for cur_date in "${dates[@]}"; do
    day=`date --date="$cur_date" +%d`
    month=`date --date="$cur_date" +%m`
    year=`date --date="$cur_date" +%Y`
    variable_full_name=`echo ${nc_variables[$i]} | sed -e 's/+/ /g'`

    printf "\n${RED}Downloading ${YELLOW}$variable_full_name ${RED}for the date ${BLUE}$month/$day/$year ${RED}...\n" 
    printf "This can take a few seconds...${NC}\n\n"

    # Capture the HTML from the GET request for our data. Place it into a text file.
    curl "http://www.esrl.noaa.gov/psd/cgi-bin/data/composites/comp.day.pl?var=${nc_variables[$i]}&level=Surface&iy%5B1%5D=&im%5B1%5D=&id%5B1%5D=&iy%5B2%5D=&im%5B2%5D=&id%5B2%5D=&iy%5B3%5D=&im%5B3%5D=&id%5B3%5D=&iy%5B4%5D=&im%5B4%5D=&id%5B4%5D=&iy%5B5%5D=&im%5B5%5D=&id%5B5%5D=&iy%5B6%5D=&im%5B6%5D=&id%5B6%5D=&iy%5B7%5D=&im%5B7%5D=&id%5B7%5D=&iy%5B8%5D=&im%5B8%5D=&id%5B8%5D=&iy%5B9%5D=&im%5B9%5D=&id%5B9%5D=&iy%5B10%5D=&im%5B10%5D=&id%5B10%5D=&iy%5B11%5D=&im%5B11%5D=&id%5B11%5D=&iy%5B12%5D=&im%5B12%5D=&id%5B12%5D=&iy%5B13%5D=&im%5B13%5D=&id%5B13%5D=&iy%5B14%5D=&im%5B14%5D=&id%5B14%5D=&iy%5B15%5D=&im%5B15%5D=&id%5B15%5D=&iy%5B16%5D=&im%5B16%5D=&id%5B16%5D=&iy%5B17%5D=&im%5B17%5D=&id%5B17%5D=&iy%5B18%5D=&im%5B18%5D=&id%5B18%5D=&iy%5B19%5D=&im%5B19%5D=&id%5B19%5D=&iy%5B20%5D=&im%5B20%5D=&id%5B20%5D=&monr1=$month&dayr1=$day&monr2=$month&dayr2=$day&iyr%5B1%5D=$year&filenamein=&plotlabel=&lag=0&labelc=Color&labels=Shaded&type=1&scale=&label=0&cint=&lowr=&highr=&istate=0&proj=ALL&xlat1=&xlat2=&xlon1=&xlon2=&custproj=Northern+Hemisphere+Polar+Stereographic&level1=1000mb&level2=10mb&Submit=Create+Plot" > temporary.txt 2>/dev/null

    # Some BASH "magic" to get just the full path to the created NetCDF file.
    temporary=`grep "\.nc" temporary.txt | awk '{ print $2; }' | cut -c6- | rev | cut -c5- | rev`

    if [ "$temporary" == "" ]; then
        last_date=`grep "Last day is" temporary.txt | cut -c13- | rev | cut -c6- | rev`
	printf "${RED}The last day available for the ${YELLOW}${nc_variables[$i]} ${RED}variable is ${BLUE}$last_date ${RED}. The GeoTIFF has not been updated.${NC}\n"
    else

    # Download the NetCDF file.
    wget "http://www.esrl.noaa.gov/$temporary" > /dev/null 2>&1

    # Rename the file to daily.nc rather than its randomly generated name.
    mv ${temporary##*/} temporary.nc

    case $cur_date in
      '-2 days')
        tif_name="NCEP_daily_${file_names[$i]}.tif"
        ;;
      '-7 days')
        tif_name="NCEP_weekly_${file_names[$i]}.tif"
        ;;
      '-1 month')
        tif_name="NCEP_monthly_${file_names[$i]}.tif"
        ;;
      '-1 year')
        tif_name="NCEP_yearly_${file_names[$i]}.tif"
        ;;
    esac

    # GDAL translate the NetCDF file into a GeoTIFF with EPSG:4326 projection called daily_air_temp.tif.
    printf "${RED}Translating the NetCDF file into a GeoTiff file...${NC}\n"
    gdal_translate -a_srs EPSG:4326 -of GTiff netCDF:"temporary.nc":${var_name[$i]} temporary.tif > /dev/null 2>&1
    gdalwarp -t_srs WGS84 temporary.tif grey.tif -wo SOURCE_EXTRA=1000 --config CENTER_LONG 0 > /dev/null 2>&1
    gdaldem color-relief grey.tif color.txt $tif_name > /dev/null 2>&1
    printf "\n${GREEN}Successfully created ${RED}$tif_name ${NC}\n"

    # Import layer into GeoNode. Will replace layer if already created.
    `which python` $INSTALL_DIR/geonode/manage.py importlayers -o $tif_name
    rm -f temporary.txt
    rm -f temporary.nc
    rm -f temporary.tif
    rm -f grey.tif
   fi
  done
done

