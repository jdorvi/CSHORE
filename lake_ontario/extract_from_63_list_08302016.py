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
import os
os.chdir("P:/02/LakeOntario")
from NODES_LIST import NODES_LIST
from TRANSECTS import TRANSECTS

#------------User Inputs----------------------------#
PARENT_DIR = "P:/02/LakeOntario/Storm/"
INPUTFILES = ["fort.63", "swan_TP.63", "swan_HS.63"]
STORM_LIST = ["19710301"]#["19740314"]#, "19770107", "19800109", "20061026"]
PARAMETERS = {"fort.63":"SWEL", "swan_TP.63":"TPS", "swan_HS.63":"HS"}

#------------------------------BEGIN SCRIPT----------------------------------#

def extract(parent_dir, inputfiles, storm_list, nodes_list):

    """Extracts data from ADCIRC time series files"""

    os.chdir(parent_dir)

    for root, dirs, files in os.walk(parent_dir):
        if root.rsplit('/', 1)[1] in storm_list:
            os.chdir(root)
            print(root)
            # Extracting data
            for filed in inputfiles:
                print("Extracting "+root+"/"+filed)
                f63 = os.path.join(root, filed)                 #-- 63 files
                with open(f63) as fin:
                    for line in fin:
                        mynode = line.strip().split(' ')[0]     #--Test each line
                        if mynode in nodes_list.keys():
                            value = line.strip().split()[1]
                            nodes_list[mynode][PARAMETERS[filed]].append(value)
            # Writing data to files
            for transect in TRANSECTS.keys():
                for node in TRANSECTS[transect]:
                    for parameter in NODES_LIST[node].keys():
                        filename = "transect_{0}_node_{1}_{2}.txt".format(transect,
                                                                          node,
                                                                          parameter)
                        with open(os.path.join(root, filename),'w') as savefile:
                            for line in NODES_LIST[node][parameter]:
                                savefile.write(line+"\n")

def main():

    """Main function, runs extract() funtion and times it."""

    start_time = dt.now()
    print('Begin extracting data:')
    print(start_time)

    extract(PARENT_DIR, INPUTFILES, STORM_LIST, NODES_LIST)

    end_time = dt.now()
    elapsed_time = end_time-start_time
    print("===========END========== \n")
    print("Processing Time : ")
    print(elapsed_time)

if __name__ == "__main__":
    main()
