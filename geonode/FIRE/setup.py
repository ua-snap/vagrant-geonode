from setuptools import setup

dependencies_list = ['rasterio','fiona','shapely','pandas','geopandas','scipy','numpy', 'requests']

classifiers = [ 	'Development Status :: 3 - Alpha',
			'Operating System :: POSIX :: Linux',
			'Environment :: Console',
			'Intended Audience :: Science/Research',
			'Intended Audience :: End Users/Desktop',
			'Topic :: Software Development :: Build Tools',
			'License :: OSI Approved :: MIT License',
			'Programming Language :: Python :: 2.7',
			'Natural Language :: English',
			'Operating System :: POSIX :: Linux',
			'Programming Language :: Python :: 2.7',
			'Topic :: Scientific/Engineering :: GIS',
			'Topic :: Scientific/Engineering :: Visualization'	]

setup(	name='fireventure',
		version='3.0',
		description='tool to return summaries of ALFRESCO Fire Dynamics Model output GeoTiff rasters',
		url='https://github.com/ua-snap/alfresco-calibration',
		author='Michael Lindgren',
		author_email='malindgren@alaska.edu',
		license='MIT',
		packages=['alfresco_postprocessing'],
		install_requires=dependencies_list,
		zip_safe=False,
		include_package_data=True,
		dependency_links='',
		scripts=scripts_list,
		classifiers=classifiers	)