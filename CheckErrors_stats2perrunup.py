# -*- coding: utf-8 - Python 3.5.1 *-
"""
Description: Check Results from Max Runp (Step 6, Great_Lake_Modeling_Process)
Input(s): paths
Output(s): error log
slawler@dewberry.com
Created on Mon Aug 29 08:31:29 2016
"""
#------------Load Python Modules--------------------#
from glob import glob
import os
import pandas as pd

#------------------------------USER INPUT----------------------------------#
ROOTDIR = r"P:\02\NY\Chautauqua_Co_36013C\STUDY__TO90\TECHNICAL\ENG_FLOOD_HAZ_DEV\COASTAL\WAVE_MODELING\CSHORE\STATS_2perRunup\output"
STORMLIST = r"P:\02\NY\Chautauqua_Co_36013C\STUDY__TO90\TECHNICAL\ENG_FLOOD_HAZ_DEV\COASTAL\WAVE_MODELING\CSHORE\stormlist_erie.txt" 
LOGFILE = r"P:\02\NY\Chautauqua_Co_36013C\STUDY__TO90\TECHNICAL\ENG_FLOOD_HAZ_DEV\COASTAL\WAVE_MODELING\WAVE_RUNUP\Erie_NY_RUNUP_method.csv"
#------------------------------BEGIN SCRIPT----------------------------------#

def main():
    """ doc string """
    max_runs = glob(os.path.join(ROOTDIR, "*.txt"))  #Get list of max_runp files

    #Read in Stormlist
    storms = pd.read_csv(STORMLIST, skiprows=1, header=None, names=['storm'])

    #Loop through files, cehck against storm list, write error log for the storms not processed
    with open(LOGFILE, 'w') as logfile:
        logfile.write("Transect\tStorm\n")
        for run in max_runs:
            runup_file = pd.read_csv(run, names=['storm', 'a', 'b', 'c', 'd'], header=None, sep=" ")
            dfs = pd.merge(storms, runup_file, left_on='storm', right_on='storm', how='left')
            errors = dfs[dfs.a.isnull()]
            transect = run.split("\\")[-1].split("_")[0]
            print("Checking file for Transect " + str(transect))
            nopeaks = errors.storm.tolist()

            for peakless in nopeaks:
                if len(nopeaks) != len(storms):
                    printline = "{0}\t{1}\n".format(transect, str(peakless))
                else:
                    printline = "{0}\tNo Storms Processed\n".format(transect)
                    break
                logfile.write(printline)
        print("\nProcess Complete\n")
        print("Error Log saved to \n {0}".format(LOGFILE))

if __name__ == '__main__':
    main()
