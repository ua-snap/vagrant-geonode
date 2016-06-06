# LETS DO SOME SCHEDULING WITH THE FIRE MAP DATA:
import sched, time, os
import geopandas as gpd

s = sched.scheduler( time.time, time.sleep )
os.chdir( '/workspace/Shared/Tech_Projects/FireMap/project_data/CODE' )
def run_query( cur_fn ):
	# read in the file from the last check
	shp = gpd.read_file( cur_fn )
	# run the processing -- this will need updating
	fn = subprocess.call([ 'ipython', 'get_fire_data.py' ])
	# read in new shapefile
	new_shp = gpd.read_file( fn )
	# compare the 2 for diffs
	if shp != new_shp:
		print( 'perimeter file updated:  %s' % datetime.datetime.now().strftime( "%I:%M%p on %B %d, %Y" ) ) # "%B_%d_%Y_%I%M%p"

cur_fn = '/workspace/Shared/Tech_Projects/FireMap/project_data/this_years_perimeters/this_years_perimeters_laundered.shp'
s.enter( 36, 1, run_query, (cur_fn,) )
s.run( )

