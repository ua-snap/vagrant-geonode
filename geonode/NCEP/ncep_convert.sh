#! /bin/bash
# This script is necessary to parse the returned HTML for the file name of the created NetCDF data as this has no
# deterministic naming schema that could be expected by a script for automation of data capture. This script downloads
# the NetCDF data, renames it to a more recognizable file name (i.e. daily, weekly, etc.) and then uses GDAL to create
# a GeoTIFF from the NetCDF file. These raster files are currently being output in EPSG:4326, which matches the GeoNode's
# default projection for its OpenLayers maps.

#################### [ DAILY ] #################### 
# Set the day, month, and year we are requesting. Most recent data on NCEP website is from 2 days ago.
day=`date --date='-2 days' +%d`
month=`date --date='-2 days' +%m`
year=`date --date='-2 days' +%Y`

# Capture the HTML from the GET request for our data. Place it into a text file.
curl "http://www.esrl.noaa.gov/psd/cgi-bin/data/composites/comp.day.pl?var=Air%20Temperature;level=Surface;iy%5B1%5D=;im%5B1%5D=;id%5B1%5D=;iy%5B2%5D=;im%5B2%5D=;id%5B2%5D=;iy%5B3%5D=;im%5B3%5D=;id%5B3%5D=;iy%5B4%5D=;im%5B4%5D=;id%5B4%5D=;iy%5B5%5D=;im%5B5%5D=;id%5B5%5D=;iy%5B6%5D=;im%5B6%5D=;id%5B6%5D=;iy%5B7%5D=;im%5B7%5D=;id%5B7%5D=;iy%5B8%5D=;im%5B8%5D=;id%5B8%5D=;iy%5B9%5D=;im%5B9%5D=;id%5B9%5D=;iy%5B10%5D=;im%5B10%5D=;id%5B10%5D=;iy%5B11%5D=;im%5B11%5D=;id%5B11%5D=;iy%5B12%5D=;im%5B12%5D=;id%5B12%5D=;iy%5B13%5D=;im%5B13%5D=;id%5B13%5D=;iy%5B14%5D=;im%5B14%5D=;id%5B14%5D=;iy%5B15%5D=;im%5B15%5D=;id%5B15%5D=;iy%5B16%5D=;im%5B16%5D=;id%5B16%5D=;iy%5B17%5D=;im%5B17%5D=;id%5B17%5D=;iy%5B18%5D=;im%5B18%5D=;id%5B18%5D=;iy%5B19%5D=;im%5B19%5D=;id%5B19%5D=;iy%5B20%5D=;im%5B20%5D=;id%5B20%5D=;monr1=$month;dayr1=$day;monr2=$month;dayr2=$day;iyr%5B1%5D=$year;filenamein=;plotlabel=;lag=-1;labelc=Color;labels=Shaded;type=1;scale=;label=0;cint=;lowr=;highr=;istate=0;proj=ALL;xlat1=0;xlat2=90;xlon1=0;xlon2=360;custproj=Northern%20Hemisphere%20Polar%20Stereographic;level1=1000mb;level2=10mb;Submit=Create%20Plot" > daily.txt

# Some BASH "magic" to get just the full path to the created NetCDF file.
daily=`grep "\.nc" daily.txt | awk '{ print $2; }' | cut -c6- | rev | cut -c5- | rev`

# Download the NetCDF file.
wget "http://www.esrl.noaa.gov/$daily"

# Rename the file to daily.nc rather than its randomly generated name.
mv ${daily##*/} daily.nc

# GDAL translate the NetCDF file into a GeoTIFF with EPSG:4326 projection called daily.tif.
gdal_translate -a_srs EPSG:4326 -of GTiff netCDF:"daily.nc":air daily.tif

# All of the rest of the code is currently repeats of the above code for different days. The comments
# above should be similarly relavent to the code below.


#################### [ WEEKLY ] #################### 
day=`date --date='-7 days' +%d`
month=`date --date='-7 days' +%m`
year=`date --date='-7 days' +%Y`

curl "http://www.esrl.noaa.gov/psd/cgi-bin/data/composites/comp.day.pl?var=Air%20Temperature;level=Surface;iy%5B1%5D=;im%5B1%5D=;id%5B1%5D=;iy%5B2%5D=;im%5B2%5D=;id%5B2%5D=;iy%5B3%5D=;im%5B3%5D=;id%5B3%5D=;iy%5B4%5D=;im%5B4%5D=;id%5B4%5D=;iy%5B5%5D=;im%5B5%5D=;id%5B5%5D=;iy%5B6%5D=;im%5B6%5D=;id%5B6%5D=;iy%5B7%5D=;im%5B7%5D=;id%5B7%5D=;iy%5B8%5D=;im%5B8%5D=;id%5B8%5D=;iy%5B9%5D=;im%5B9%5D=;id%5B9%5D=;iy%5B10%5D=;im%5B10%5D=;id%5B10%5D=;iy%5B11%5D=;im%5B11%5D=;id%5B11%5D=;iy%5B12%5D=;im%5B12%5D=;id%5B12%5D=;iy%5B13%5D=;im%5B13%5D=;id%5B13%5D=;iy%5B14%5D=;im%5B14%5D=;id%5B14%5D=;iy%5B15%5D=;im%5B15%5D=;id%5B15%5D=;iy%5B16%5D=;im%5B16%5D=;id%5B16%5D=;iy%5B17%5D=;im%5B17%5D=;id%5B17%5D=;iy%5B18%5D=;im%5B18%5D=;id%5B18%5D=;iy%5B19%5D=;im%5B19%5D=;id%5B19%5D=;iy%5B20%5D=;im%5B20%5D=;id%5B20%5D=;monr1=$month;dayr1=$day;monr2=$month;dayr2=$day;iyr%5B1%5D=$year;filenamein=;plotlabel=;lag=-1;labelc=Color;labels=Shaded;type=1;scale=;label=0;cint=;lowr=;highr=;istate=0;proj=ALL;xlat1=0;xlat2=90;xlon1=0;xlon2=360;custproj=Northern%20Hemisphere%20Polar%20Stereographic;level1=1000mb;level2=10mb;Submit=Create%20Plot" > weekly.txt 

weekly=`grep "\.nc" weekly.txt | awk '{ print $2; }' | cut -c6- | rev | cut -c5- | rev`
wget "http://www.esrl.noaa.gov/$weekly"
mv ${weekly##*/} weekly.nc
gdal_translate -a_srs EPSG:4326 -of GTiff netCDF:"weekly.nc":air weekly.tif


#################### [ MONTHLY ] #################### 
day=`date --date='-1 month' +%d`
month=`date --date='-1 month' +%m`
year=`date --date='-1 month' +%Y`

curl "http://www.esrl.noaa.gov/psd/cgi-bin/data/composites/comp.day.pl?var=Air%20Temperature;level=Surface;iy%5B1%5D=;im%5B1%5D=;id%5B1%5D=;iy%5B2%5D=;im%5B2%5D=;id%5B2%5D=;iy%5B3%5D=;im%5B3%5D=;id%5B3%5D=;iy%5B4%5D=;im%5B4%5D=;id%5B4%5D=;iy%5B5%5D=;im%5B5%5D=;id%5B5%5D=;iy%5B6%5D=;im%5B6%5D=;id%5B6%5D=;iy%5B7%5D=;im%5B7%5D=;id%5B7%5D=;iy%5B8%5D=;im%5B8%5D=;id%5B8%5D=;iy%5B9%5D=;im%5B9%5D=;id%5B9%5D=;iy%5B10%5D=;im%5B10%5D=;id%5B10%5D=;iy%5B11%5D=;im%5B11%5D=;id%5B11%5D=;iy%5B12%5D=;im%5B12%5D=;id%5B12%5D=;iy%5B13%5D=;im%5B13%5D=;id%5B13%5D=;iy%5B14%5D=;im%5B14%5D=;id%5B14%5D=;iy%5B15%5D=;im%5B15%5D=;id%5B15%5D=;iy%5B16%5D=;im%5B16%5D=;id%5B16%5D=;iy%5B17%5D=;im%5B17%5D=;id%5B17%5D=;iy%5B18%5D=;im%5B18%5D=;id%5B18%5D=;iy%5B19%5D=;im%5B19%5D=;id%5B19%5D=;iy%5B20%5D=;im%5B20%5D=;id%5B20%5D=;monr1=$month;dayr1=$day;monr2=$month;dayr2=$day;iyr%5B1%5D=$year;filenamein=;plotlabel=;lag=-1;labelc=Color;labels=Shaded;type=1;scale=;label=0;cint=;lowr=;highr=;istate=0;proj=ALL;xlat1=0;xlat2=90;xlon1=0;xlon2=360;custproj=Northern%20Hemisphere%20Polar%20Stereographic;level1=1000mb;level2=10mb;Submit=Create%20Plot" > monthly.txt

monthly=`grep "\.nc" monthly.txt | awk '{ print $2; }' | cut -c6- | rev | cut -c5- | rev`
wget "http://www.esrl.noaa.gov/$monthly"
mv ${monthly##*/} monthly.nc
gdal_translate -a_srs EPSG:4326 -of GTiff netCDF:"monthly.nc":air monthly.tif


#################### [ YEARLY ] #################### 
day=`date --date='-1 year' +%d`
month=`date --date='-1 year' +%m`
year=`date --date='-1 year' +%Y`

curl "http://www.esrl.noaa.gov/psd/cgi-bin/data/composites/comp.day.pl?var=Air%20Temperature;level=Surface;iy%5B1%5D=;im%5B1%5D=;id%5B1%5D=;iy%5B2%5D=;im%5B2%5D=;id%5B2%5D=;iy%5B3%5D=;im%5B3%5D=;id%5B3%5D=;iy%5B4%5D=;im%5B4%5D=;id%5B4%5D=;iy%5B5%5D=;im%5B5%5D=;id%5B5%5D=;iy%5B6%5D=;im%5B6%5D=;id%5B6%5D=;iy%5B7%5D=;im%5B7%5D=;id%5B7%5D=;iy%5B8%5D=;im%5B8%5D=;id%5B8%5D=;iy%5B9%5D=;im%5B9%5D=;id%5B9%5D=;iy%5B10%5D=;im%5B10%5D=;id%5B10%5D=;iy%5B11%5D=;im%5B11%5D=;id%5B11%5D=;iy%5B12%5D=;im%5B12%5D=;id%5B12%5D=;iy%5B13%5D=;im%5B13%5D=;id%5B13%5D=;iy%5B14%5D=;im%5B14%5D=;id%5B14%5D=;iy%5B15%5D=;im%5B15%5D=;id%5B15%5D=;iy%5B16%5D=;im%5B16%5D=;id%5B16%5D=;iy%5B17%5D=;im%5B17%5D=;id%5B17%5D=;iy%5B18%5D=;im%5B18%5D=;id%5B18%5D=;iy%5B19%5D=;im%5B19%5D=;id%5B19%5D=;iy%5B20%5D=;im%5B20%5D=;id%5B20%5D=;monr1=$month;dayr1=$day;monr2=$month;dayr2=$day;iyr%5B1%5D=$year;filenamein=;plotlabel=;lag=-1;labelc=Color;labels=Shaded;type=1;scale=;label=0;cint=;lowr=;highr=;istate=0;proj=ALL;xlat1=0;xlat2=90;xlon1=0;xlon2=360;custproj=Northern%20Hemisphere%20Polar%20Stereographic;level1=1000mb;level2=10mb;Submit=Create%20Plot" > yearly.txt

yearly=`grep "\.nc" yearly.txt | awk '{ print $2; }' | cut -c6- | rev | cut -c5- | rev`
wget "http://www.esrl.noaa.gov/$yearly"
mv ${yearly##*/} yearly.nc
gdal_translate -a_srs EPSG:4326 -of GTiff netCDF:"yearly.nc":air yearly.tif


