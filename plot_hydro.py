# -*- coding: utf-8 -*-
"""
Description: Plot hydrographs produced by getstationoutput9.exe
Input(s): 
Output(s): Hydrograph plots
jdorvinen@dewberry.com
"""

def main():
    import os
    import pandas as pd
    import matplotlib.pyplot as plt
    plt.style.use('ggplot')
    import os
    from os.path import isfile, join

    #Locate executable and input files
    PARENT_DIRECTORY     = "P:/02/NY/Monroe_36055C/STUDY__TO90/TECHNICAL/ENG_FLOOD_HAZ_DEV/COASTAL/WAVE_MODELING/CSHORE_J/"
    output_directory     = "P:/02/NY/Monroe_36055C/STUDY__TO90/TECHNICAL/ENG_FLOOD_HAZ_DEV/COASTAL/WAVE_MODELING/CSHORE_J/Hydrographs/ouput"
    
    os.chdir(PARENT_DIRECTORY)
    def plotting(stormfile):
        # read data 
        df = pd.read_fwf(stormfile,names=('Time','WSE','Hs','Tp'))
        df.Time = df.Time/86400.0  #seconds to days
        df.WSE  = df.WSE*10/0.3048    #meters to feet
        df.Hs   = df.Hs/0.3048     #meters to feet
        # plot figure
        fig, ax = plt.subplots(figsize=(12,6))
        ax.plot(df.Time,df.WSE,label='WSE*10')
        ax.plot(df.Time,df.Hs,label='Hs')
        ax.plot(df.Time,df.Tp,label='Tp')
        ax.legend(loc=2,frameon=False)
        ax.set_xlim([0,df.Time.max()])
        ax.set_ylim([-5,12])
        ax.set_ylabel('Feet/Seconds')
        ax.set_xlabel('Simulation Days')
        fig.suptitle(stormfile[:-4],fontsize=16)
        fig.savefig(stormfile[:-4]+".jpg")
        fig.clf()

    #Load in storm/scenario list(s)
    onlyfiles = [f for f in os.listdir(PARENT_DIRECTORY) if isfile(join(PARENT_DIRECTORY,f))]
    for i in onlyfiles:
        if i[-4:] == ".txt" and i[0:6] == "Hydrog":
            print("Boom!")
            plotting(i)

if __name__ == '__main__':
    main()
