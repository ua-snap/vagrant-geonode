# geojson data that will be used to update the data
# pts = '/workspace/Shared/Tech_Projects/FireMap/project_data/fireseason_2016/fires_2016_all.json'
# perims_all = '/workspace/Shared/Tech_Projects/FireMap/project_data/fireseason_2016/fireperimeters_2016_all.json'
# perims_active = '/workspace/Shared/Tech_Projects/FireMap/project_data/fireseason_2016/fireperimeters_2016_active.json'

def main( pts, perims_all, perims_active, output_directory, join_field_perims='FIREID', join_field_pts='ID' ):
	# read in the data
	fires = gpd.read_file( pts )
	perims = gpd.read_file( perims_all )
	perims_active = gpd.read_file( perims_active )

	# merge and add ACTIVENOW column --> HARDWIRED AND DANGERTOWN
	# joined = perims.join( fires_clean, how='left', on=join_field, lsuffix='_pol', rsuffix='_pts' )
	fires_clean = fires.drop( ['geometry', 'NAME'] , axis=1 )
	merged_pols = perims.merge( fires_clean, how='left', left_on=join_field_perims, right_on=join_field_pts, suffixes=['_pol','_pts'] )
	merged_pols[ 'ACTIVENOW' ] = merged_pols.FIREID.isin( perims_active.FIREID ).astype( int )
	
	# drop the ones that have perimeters from the points database
	keep = [ i for i in fires.ID if i not in perims.FIREID ]
	pts_noperim = fires[ fires.ID.isin( keep ) ]

	# keep the fields that we want™
	pols = [ 'NAME', 'ACRES', 'FIREYEAR', 'UPDATETIME', 'FIREID', 'ACTIVENOW', 'PERIMETERDATE', 'geometry' ]
	pts = [ 'GENERALCAUSE', 'PRIMARYFUELTYPE', 'DISCOVERYDATETIME', 'ISACTIVE' ]
	fields = pols + pts

	# remove what we dont want
	merged_pols = merged_pols.ix[ :, fields ]
	pts_noperim = pts_noperim.ix[ :, fields ]

	# update the time fields
	time_fields = [ 'UPDATETIME','DISCOVERYDATETIME' ]
	for t in time_fields:
		merged_pols[t] = [ time.ctime(i) for i in merged_pols[t].astype(int)/1000 ]

	# update the dates in the points without perims layer
	pts_noperim[time_fields[1]] = [ time.ctime(i) for i in pts_noperim[time_fields[1]].astype(int)/1000 if i != np.nan ]

	# re-geo the geometry column
	merged_pols = gpd.GeoDataFrame( merged_pols, geometry='geometry' ) # crs={'init':'epsg:3338'}, #this crs may be incorrect
	pts_noperim = gpd.GeoDataFrame( pts_noperim, geometry='geometry' ) # crs={'init':'epsg:3338'}, #this crs may be incorrect

	# write merged file to a new GeoJSON
	output_filename = 'fireperimeters_2016_all_cleaned_joined.json'
	if os.path.exists( output_filename ):
		os.remove( output_filename )

	# merged_pols.to_file( output_filename, driver='GeoJSON' )

	output_filename = 'fireperimeters_2016_all_cleaned_joined.shp'
	merged_pols.to_file( output_filename, driver='ESRI Shapefile' )

	# this is a hack since the to_file method is failing...
	# with open( output_filename, 'w' ) as f:
	# 	json.dump( merged_pols.to_json(), f )

	# write the remainder of un-joined points to a new GeoJSON
	# output_filename = 'fires_2016_cleaned_noperim.json'
	# if os.path.exists( output_filename ):
	# 	os.remove( output_filename )

	# pts_noperim.to_file( output_filename, driver='GeoJSON' )

	output_filename = 'fires_2016_cleaned_noperim.shp'
	pts_noperim.to_file( output_filename, driver='ESRI Shapefile' )

	# # this is a hack since the to_file method is failing...
	# with open( output_filename, 'w' ) as f:
	# 	json.dumps( pts_noperim.to_json(), f)

if __name__ == '__main__':
	# get that damn data and make it join together
	import geopandas as gpd
	import numpy as np
	import os, time, json
	import argparse

	# pts
	# perims_all
	# perims_active
	# output_directory
	# join_field_perims='FIREID'
	# join_field_pts='ID'

	# parse commandline args
	# output_directory = '/workspace/Shared/Tech_Projects/FireMap/project_data/fireseason_2016' # '/Users/malindgren/Documents/firemap/fire_2016'
	parser = argparse.ArgumentParser( description='GET FIRE DATA FROM THE AICC REST SERVICES' )
	parser.add_argument( '-pts', '--pts', action='store', dest='pts', type=str, help='path to geojson all pts data from the AICC ESRI REST services' )
	parser.add_argument( '-pall', '--pall', action='store', dest='perims_all', type=str, help='path to geojson all perimeters data from the AICC ESRI REST services' )
	parser.add_argument( '-pactive', '--pactive', action='store', dest='perims_active', type=str, help='path to geojson active perimeters data from the AICC ESRI REST services' )
	parser.add_argument( '-p', '--output_directory', action='store', dest='output_directory', type=str, help='path to output directory' )

	args = parser.parse_args()
	pts = args.pts
	perims_all = args.perims_all
	perims_active = args.perims_active
	output_directory = args.output_directory
	# join_field_perims = args.join_field_perims
	# join_field_pts = args.join_field_pts

	os.chdir( output_directory )
	main( pts, perims_all, perims_active, output_directory )
