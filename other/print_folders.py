# coding: utf-8
#Extracts all .63.bz2 files in directory folder starting at current directory

import os
import pandas as pd

DATAFILES_DIRECTORY = "P:/02/LakeOntario/Storm/"

def main(datafiles_directory):
    """ doc string """
    os.chdir(datafiles_directory)
    stormlist = []
    for root, dirs, files in os.walk("."):
        if os.path.exists(root+"/fort.63") is True:
            if len(root) == 10:
                print(root.strip(".").strip("\\"))
                stormlist.append(root.strip(".").strip("\\"))
    stormlist.sort()

    stormlist1 = stormlist[0:30]
    stormlist2 = stormlist[30:60]
    stormlist3 = stormlist[60:90]
    stormlist4 = stormlist[90:120]
    stormlist5 = stormlist[120:150]

    stormlist1.insert(0, len(stormlist1))
    stormlist2.insert(0, len(stormlist2))
    stormlist3.insert(0, len(stormlist3))
    stormlist4.insert(0, len(stormlist4))
    stormlist5.insert(0, len(stormlist5))

    storms1 = pd.Series(stormlist1)
    storms2 = pd.Series(stormlist2)
    storms3 = pd.Series(stormlist3)
    storms4 = pd.Series(stormlist4)
    storms5 = pd.Series(stormlist5)

    storms1.to_csv('stormslist1.txt', index=False)
    storms2.to_csv('stormslist2.txt', index=False)
    storms3.to_csv('stormslist3.txt', index=False)
    storms4.to_csv('stormslist4.txt', index=False)
    storms5.to_csv('stormslist5.txt', index=False)

if __name__ == '__main__':
    main(DATAFILES_DIRECTORY)
