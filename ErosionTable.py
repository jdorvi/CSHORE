# -*- coding: utf-8 -*-
"""
Description:

Input(s): WAVEPATH

Output(s): Transect & Station files

slawler@dewberry.com

Created on Fri Apr 15 10:57:54 2016
"""
import os
import pandas as pd

#----Assign Directories ==> Copy from CoastalErosion.py 
WAVEPATH = "P:/02/NY/Monroe_36055C/STUDY__TO90/TECHNICAL/ENG_FLOOD_HAZ_DEV/COASTAL/WAVE_MODELING/STARTING_WAVE_CONDITIONS_S"

#----Short hand formatting variables
tab, nl  = '\t', '\n'

#----Assign Filenames w/directory paths
csv_table                 = os.path.join(WAVEPATH,"Export_Output.csv")
transectfile              = os.path.join(WAVEPATH, "transect_nodes_jpm.txt")
stationfile               = os.path.join(WAVEPATH, "stationfile.txt")

#----Read in tables & sort
table = pd.read_excel(csv_table)
tables_sort = table.sort(['TRANSECTID'], ascending = [1])

#----Make a node index list 
nodes = range(1,len(table)+1)

#----Initialize output files
with open(stationfile, 'w') as f: f.write(str(len(nodes)) + '\n')
with open(transectfile, 'w') as f: f.write('')

#----Write output files  
for i, n in enumerate(nodes):
    lat, lon = str(tables_sort['X'][i]),str(tables_sort['Y'][i])
    station, transect = str(n), str(tables_sort['TRANSECTID'][i]) 
    with open(stationfile, 'a') as f:
        f.write(station + tab + lat + tab + lon + tab + nl )
    with open(transectfile,'a') as f2:
        f2.write(station + tab + transect + nl)
        
