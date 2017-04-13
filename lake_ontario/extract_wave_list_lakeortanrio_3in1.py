# -*- coding: utf-8 - Python 2.7.11 *-
"""
Description: Reads Adcirc Global Output file fort.63 & returns time series at
selected nodes.
Input(s): fort.63, Nodes of interest
Output(s): Time series .txt files
jdorvinen@dewberry.com, slawler@dewberry.com
Created on Tue Apr 19 15:08:33 2016
"""
#------------Load Python Modules--------------------#
#import fileinput
from datetime import datetime as dt
from copy import deepcopy
import os
import numpy as np
os.chdir("P:/02/LakeOntario")
from NODES_LIST import NODES_LIST
from TRANSECTS import TRANSECTS
from STORM_LIST import STORM_LIST

#------------User Inputs----------------------------#
PARENT_DIR = "P:/02/LakeOntario/Storm/"
OUTPUT_DIR = "P:/02/NY/Oswego_Co_36075/STUDY__TO90/TECHNICAL/ENG_FLOOD_HAZ_DEV/COASTAL/WAVE_MODELING/CSHORE/Hydrographs/test/"
INPUTFILES = ["fort.63", "swan_TP.63", "swan_HS.63"]
#STORM_LIST = ["20061026"] #["20061026"] #
PARAMETERS = {"fort.63":"SWEL", "swan_TP.63":"TPS", "swan_HS.63":"HS"}

#------------------------------BEGIN SCRIPT----------------------------------#

def extract(root, storm):

    """Extracts data from ADCIRC time series files"""
    nodes_list = deepcopy(NODES_LIST)
    for filed in INPUTFILES:
        print("Extracting "+root+"/"+filed)
        f63 = os.path.join(root, filed)                 #-- 63 files
        with open(f63) as fin:
            for line in fin:
                mynode = line.strip().split(' ')[0]     #--Test each line
                if mynode in nodes_list.keys():
                    value = line.strip().split()[1]
                    nodes_list[mynode][PARAMETERS[filed]].append(value)
    # Writing data to files
    for transect in TRANSECTS:
        for node in TRANSECTS[transect]:
            filename = "{0}_{1}.txt".format(storm, transect)
            length = max([len(nodes_list[node]['SWEL']),
                          len(nodes_list[node]['HS']),
                          len(nodes_list[node]['TPS'])])
            timesteps = np.arange(0, length-1)
            with open(os.path.join(OUTPUT_DIR, filename), 'w') as savefile:
                for step in timesteps:
                    time = '{:>12}'.format(str((step+1)*1800))
                    try:
                        swel = '{:>24.6f}'.format(nodes_list[node]['SWEL'][step])
                    except LookupError:
                        swel = '{:>24}'.format('nan')
                    try:
                        hsig = '{:>24.6f}'.format(nodes_list[node]['HS'][step+1])
                    except LookupError:
                        hsig = '{:>24}'.format('nan')
                    try:
                        tps = '{:>24.6f}'.format(nodes_list[node]['TPS'][step+1])
                    except LookupError:
                        tps = '{:>24}'.format('nan')
                    line = time+swel+hsig+tps+"\n"
                    savefile.write(line)

def main():

    """Main function, runs extract() funtion and times it."""

    start_time = dt.now()
    print("\n==========START========= \n")
    print('Begin extracting data:\n')
    print(start_time)

    for storm in STORM_LIST:
        root = os.path.join(PARENT_DIR, storm)
        extract(root, storm)

    end_time = dt.now()
    tda = str(end_time-start_time).split('.')[0].split(':')
    print("\n===========END==========\n")
    print("Processing Time :\n")
    print("{0} hrs, {1} mins, {2} sec \n\n".format(tda[0], tda[1], tda[2]))

if __name__ == "__main__":
    main()
