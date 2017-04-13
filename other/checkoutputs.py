# coding: utf-8
"""Extracts all .63.bz2 files in directory folder starting at current directory """
def main():
    """ doc string """
    datafiles_directory  = "P:/02/NY/Monroe_36055C/STUDY__TO90/TECHNICAL/ENG_FLOOD_HAZ_DEV/COASTAL/WAVE_MODELING/CSHORE_J/"
    stormlist_file = "C:/Users/jdorvinen/Desktop/cshore/stormlist.txt"
    import os
    from os.path import isfile, join
    import subprocess
    import pandas as pd
    os.chdir(datafiles_directory)
    dfs = pd.read_csv(stormlist_file, skiprows=1, names=['storms'])
    stormlist = dfs['storms'].astype(str).tolist()
    filelist = []
    onlyfiles = [f for f in os.listdir(datafiles_directory) if isfile(join(datafiles_directory, f))]
    for i in onlyfiles:
        if i[-6:] == "_1.txt":
            filelist.append(i[6:-6])
    filelist.sort()
    for storm in stormlist:
        if storm not in filelist:
            print(storm)

if __name__ == '__main__':
    main()
