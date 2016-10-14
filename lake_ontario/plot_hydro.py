# -*- coding: utf-8 -*-
"""
Description: Plot hydrographs produced by getstationoutput9.exe

Input(s):
Output(s): Hydrograph plots

Author: J. Dorvinen
Email: jdorvinen@dewberry.com
"""
# Load modules
import os
from os.path import isfile, join
from datetime import datetime as dt

#Locate executable and input files
PARENT_DIRECTORY = "P:/02/LakeOntario/Storm/19881117/hydrographs_cayuga"
OUTPUT_DIRECTORY = "P:/02/LakeOntario/Storm/19881117/hydrographs_cayuga/output/"

def plotting(stormfile):
    """ Plot extracted SWEL, TPS, and HS from ADCIRC files """
    import pandas as pd
    import matplotlib.pyplot as plt
    plt.style.use('ggplot')
    # read data
    dataframe = pd.read_fwf(stormfile, names=('Time', 'WSE', 'Hs', 'Tp'))
    dataframe['Time'] = dataframe.Time/86400.0    #seconds to days
    dataframe['WSE'] = dataframe.WSE/0.3048    #meters to feet
    dataframe['Hs'] = dataframe.Hs/0.3048     #meters to feet
    # plot figure
    fig, axs = plt.subplots(figsize=(12, 6))
    axs.plot(dataframe.Time, dataframe.WSE, label='WSE') #*10')
    axs.plot(dataframe.Time, dataframe.Hs, label='Hs')
    axs.plot(dataframe.Time, dataframe.Tp, label='Tp')
    axs.legend(loc=2, frameon=False)
    axs.set_xlim([0, dataframe.Time.max()])
    axs.set_ylim([-5, 12])
    axs.set_ylabel('Feet/Seconds')
    axs.set_xlabel('Simulation Days')
    fig.suptitle(stormfile[:-4], fontsize=16)
    fig.savefig(OUTPUT_DIRECTORY+stormfile[:-4]+".jpg")
    plt.close('all')

def main():
    """ Main function """
    start_time = dt.now()
    print("\n==========START==========\n")
    print('Begin creating plots:\n')
    print(start_time)

    os.chdir(PARENT_DIRECTORY)
    #Load in storm/scenario list(s)
    onlyfiles = [f for f in os.listdir(PARENT_DIRECTORY) if isfile(join(PARENT_DIRECTORY, f))]
    for filed in onlyfiles:
        if filed[-4:] == ".txt": # and filed[0:8] == "transect":
            plotting(filed)

    end_time = dt.now()
    tda = str(end_time-start_time).split('.')[0].split(':')
    print("\n===========END==========\n")
    print("Processing Time :\n")
    print("{0} hrs, {1} mins, {2} sec \n\n".format(tda[0], tda[1], tda[2]))

if __name__ == '__main__':
    main()
