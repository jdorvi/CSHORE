import arcpy, os, shutil

#----Assign Directories
SRCPATH =  "P:/02/NY/Monroe_36055C/STUDY__TO90/TECHNICAL/ENG_FLOOD_HAZ_DEV/COASTAL/WAVE_MODELING/PGDB_S/Monroe_NY_PGDB.mdb"
WAVEPATH = "P:/02/NY/Monroe_36055C/STUDY__TO90/TECHNICAL/ENG_FLOOD_HAZ_DEV/COASTAL/WAVE_MODELING/STARTING_WAVE_CONDITIONS_S"
adcirc_grid  = "P:/02/LakeOntario/LakeOntario_mesh_grid.shp"

#----Assign Filenames w/directory paths
S_CST_OFFSH_LN            =os.path.join(SRCPATH,"S_CST_OFFSH_LN")
offshore_pts              = os.path.join(WAVEPATH,"Offshore_pts.shp")
offshore_pts_spatial_join = os.path.join(WAVEPATH,"Offshore_pts_SpatialJoin.shp")
table                     = os.path.join(WAVEPATH,"Export_Output.xls")
csv_table                 = os.path.join(WAVEPATH,"Export_Output.csv")

arcpy.FeatureVerticesToPoints_management(S_CST_OFFSH_LN,offshore_pts,"END")
arcpy.SpatialJoin_analysis(offshore_pts,adcirc_grid,offshore_pts_spatial_join,"JOIN_ONE_TO_ONE","KEEP_ALL",None,"CLOSEST","#","dist")
arcpy.TableToExcel_conversion(offshore_pts_spatial_join,table,"NAME","CODE")
shutil.copy(table,csv_table)

