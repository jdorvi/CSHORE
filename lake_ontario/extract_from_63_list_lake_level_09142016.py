# -*- coding: utf-8 - Python 3.5 *-
"""
Description: Reads Adcirc Global Output file fort.63 & returns time series at
selected nodes.
Input(s): fort.63, Nodes of interest
Output(s): Time series .txt files
jdorvinen@dewberry.com, slawler@dewberry.com
Created on Tue Apr 19 15:08:33 2016
"""
#-----------------------------Load Python Modules-----------------------------#
#import fileinput
from datetime import datetime as dt
from copy import deepcopy
import os
from NODES_LIST_cayuga import NODES_LIST
from TRANSECTS_cayuga import TRANSECTS
import numpy as np

#--------------------------------User Inputs----------------------------------#
PARENT_DIR = "P:/02/LakeOntario/Storm/"
INPUTFILES = ["fort.63", "swan_TP.63", "swan_HS.63"]
STORM_LIST = ["19881117"] #"19740314", "19770107", "19800109", "20061026", "19710301"]
PARAMETERS = {"fort.63":"SWEL", "swan_TP.63":"TPS", "swan_HS.63":"HS"}
STORM_LAKE_LEVEL = 0.35375
#--------------------------------BEGIN SCRIPT---------------------------------#

def extract(root):

    """Extracts data from ADCIRC time series files"""
    nodes_list = deepcopy(NODES_LIST)
    for filed in INPUTFILES:
        print("Extracting "+root+"/"+filed)
        f63 = os.path.join(root, filed)                 #-- 63 files
        with open(f63) as fin:
            for line in fin:
                mynode = line.strip().split(' ')[0]     #--Test each line
                if mynode in nodes_list.keys():
                    value = float(line.strip().split()[1])
                    nodes_list[mynode][PARAMETERS[filed]].append(value)
    return nodes_list

def write_data(root, nodes_list, storm):
    """ Write extracted data to files """
    for transect in TRANSECTS:
        for node in TRANSECTS[transect]:
            filename = "{0}_{1}.txt".format(storm, transect)
            length = max([len(nodes_list[node]['SWEL']),
                          len(nodes_list[node]['HS']),
                          len(nodes_list[node]['TPS'])])
            timesteps = np.arange(0, length)
            with open(os.path.join(root, filename), 'w') as savefile:
                for step in timesteps:
                    time = '{:>12.2f}'.format(step*1800)
                    if step == 0:
                        swel = '{:>15.6f}'.format((nodes_list[node]['SWEL'][step]\
                                                   +STORM_LAKE_LEVEL))
                        hsig = '{:>15.6f}'.format(0)
                        tps = '{:>15.6f}'.format(0)
                    elif step == 1:
                        try:
                            swel = '{:>15.6f}'.format((nodes_list[node]['SWEL'][step-1]\
                                                       +STORM_LAKE_LEVEL))
                        except LookupError:
                            swel = '{:>15}'.format('nan')
                        try:
                            hsig = '{:>15.6f}'.format(nodes_list[node]['HS'][step]/2)
                        except LookupError:
                            hsig = '{:>15}'.format('nan')
                        try:
                            tps = '{:>15.6f}'.format(nodes_list[node]['TPS'][step]/2)
                        except LookupError:
                            tps = '{:>15}'.format('nan')
                    else:
                        try:
                            swel = '{:>15.6f}'.format((nodes_list[node]['SWEL'][step-1]\
                                                       +STORM_LAKE_LEVEL))
                        except LookupError:
                            swel = '{:>15}'.format('nan')
                        try:
                            hsig = '{:>15.6f}'.format(nodes_list[node]['HS'][step-1])
                        except LookupError:
                            hsig = '{:>15}'.format('nan')
                        try:
                            tps = '{:>15.6f}'.format(nodes_list[node]['TPS'][step-1])
                        except LookupError:
                            tps = '{:>15}'.format('nan')
                    line = time+swel+hsig+tps+"\n"
                    savefile.write(line)

#--------------------------------MAIN FUNCTION--------------------------------#
def main():

    """Main function, runs extract() funtion and times it."""

    start_time = dt.now()
    print("\n==========START========= \n")
    print('Begin extracting data:\n')
    print(start_time)

    for storm in STORM_LIST:
        root = os.path.join(PARENT_DIR, storm)
        nodes_list = extract(root)
        write_data(root, nodes_list, storm)

    end_time = dt.now()
    tda = str(end_time-start_time).split('.')[0].split(':')
    print("\n===========END==========\n")
    print("Processing Time :\n")
    print("{0} hrs, {1} mins, {2} sec \n\n".format(tda[0], tda[1], tda[2]))
    #return nodes_list
if __name__ == "__main__":
    main()
