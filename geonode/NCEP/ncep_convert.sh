#! /bin/bash
# This script is necessary to parse the returned HTML for the file name of the created NetCDF data as this has no
# deterministic naming schema that could be expected by a script for automation of data capture. This script downloads
# the NetCDF data, renames it to a more recognizable file name (i.e. daily, weekly, etc.) and then uses GDAL to create
# a GeoTIFF from the NetCDF file. These raster files are currently being output in EPSG:4326, which matches the GeoNode's
# default projection for its OpenLayers maps.

nc_variables=('Air+Temperature'
	      'Sea+Surface+Temperature')

file_names=('air_temp'
	    'sea_surf_temp')

var_names=('air'
           'skt')

dates=('-2 days'
       '-7 days'
       '-1 month'
       '-1 year')

total_vars=${#nc_variables[*]}

for (( i=0; i< $(($total_vars)); i++)); do
  for cur_date in "${dates[@]}"; do
    day=`date --date="$cur_date" +%d`
    month=`date --date="$cur_date" +%m`
    year=`date --date="$cur_date" +%Y`

    # Capture the HTML from the GET request for our data. Place it into a text file.
    curl "http://www.esrl.noaa.gov/psd/cgi-bin/data/composites/comp.day.pl?var=Sea+Surface+Temperature&level=Surface&iy%5B1%5D=&im%5B1%5D=&id%5B1%5D=&iy%5B2%5D=&im%5B2%5D=&id%5B2%5D=&iy%5B3%5D=&im%5B3%5D=&id%5B3%5D=&iy%5B4%5D=&im%5B4%5D=&id%5B4%5D=&iy%5B5%5D=&im%5B5%5D=&id%5B5%5D=&iy%5B6%5D=&im%5B6%5D=&id%5B6%5D=&iy%5B7%5D=&im%5B7%5D=&id%5B7%5D=&iy%5B8%5D=&im%5B8%5D=&id%5B8%5D=&iy%5B9%5D=&im%5B9%5D=&id%5B9%5D=&iy%5B10%5D=&im%5B10%5D=&id%5B10%5D=&iy%5B11%5D=&im%5B11%5D=&id%5B11%5D=&iy%5B12%5D=&im%5B12%5D=&id%5B12%5D=&iy%5B13%5D=&im%5B13%5D=&id%5B13%5D=&iy%5B14%5D=&im%5B14%5D=&id%5B14%5D=&iy%5B15%5D=&im%5B15%5D=&id%5B15%5D=&iy%5B16%5D=&im%5B16%5D=&id%5B16%5D=&iy%5B17%5D=&im%5B17%5D=&id%5B17%5D=&iy%5B18%5D=&im%5B18%5D=&id%5B18%5D=&iy%5B19%5D=&im%5B19%5D=&id%5B19%5D=&iy%5B20%5D=&im%5B20%5D=&id%5B20%5D=&monr1=$month&dayr1=$day&monr2=$month&dayr2=$day&iyr%5B1%5D=$year&filenamein=&plotlabel=&lag=0&labelc=Color&labels=Shaded&type=1&scale=&label=0&cint=&lowr=&highr=&istate=0&proj=ALL&xlat1=&xlat2=&xlon1=&xlon2=&custproj=Northern+Hemisphere+Polar+Stereographic&level1=1000mb&level2=10mb&Submit=Create+Plot" > temporary.txt

    # Some BASH "magic" to get just the full path to the created NetCDF file.
    temporary=`grep "\.nc" temporary.txt | awk '{ print $2; }' | cut -c6- | rev | cut -c5- | rev`
    rm -f temporary.txt

    # Download the NetCDF file.
    wget "http://www.esrl.noaa.gov/$temporary"

    # Rename the file to daily.nc rather than its randomly generated name.
    mv ${temporary##*/} temporary.nc

    case $cur_date in
      '-2 days')
        tif_name="daily_${file_names[$i]}.tif"
        ;;
      '-7 days')
        tif_name="weekly_${file_names[$i]}.tif"
        ;;
      '-1 month')
        tif_name="monthly_${file_names[$i]}.tif"
        ;;
      '-1 year')
        tif_name="yearly_${file_names[$i]}.tif"
        ;;
    esac

    # GDAL translate the NetCDF file into a GeoTIFF with EPSG:4326 projection called daily_air_temp.tif.
    gdal_translate -a_srs EPSG:4326 -of GTiff netCDF:"temporary.nc":${var_name[$i]} temporary.tif
    gdalwarp -t_srs WGS84 temporary.tif $tif_name -wo SOURCE_EXTRA=1000 --config CENTER_LONG 0
    rm -f temporary.nc
    rm -f temporary.tif
  done
done

