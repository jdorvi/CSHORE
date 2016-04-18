# coding: utf-8
#Extracts hydrographs from all .63 files in directory folder starting at current directory
def main():
  import argparse
  parser = argparse.ArgumentParser()
  parser.add_argument("num")
  args = parser.parse_args()
  num  = int(args.num)
  print num
  #import modules
  import os
  import subprocess
  import pandas as pd
  #Locate executable and input files
  PARENT_DIRECTORY     = "P:/02/NY/Monroe_36055C/STUDY__TO90/TECHNICAL/ENG_FLOOD_HAZ_DEV/COASTAL/WAVE_MODELING/CSHORE_J/Hydrographs/input/"
  getstationoutput_exe = "C:/Users/jdorvinen/Desktop/cshore/getstationoutput9.exe"
  stationfile          = "C:/Users/jdorvinen/Desktop/cshore/stationfile.txt"
  stormlist            = ["C:/Users/jdorvinen/Desktop/cshore/stormslist1.txt",
                          "C:/Users/jdorvinen/Desktop/cshore/stormslist2.txt",
                          "C:/Users/jdorvinen/Desktop/cshore/stormslist3.txt",
                          "C:/Users/jdorvinen/Desktop/cshore/stormslist4.txt",
                          "C:/Users/jdorvinen/Desktop/cshore/stormslist5.txt"] ##getstationoutput_scripted.py eliminates the need for this.
  datafiles_directory  = "P:/02/LakeOntario/Storm/"
  output_directory     = "P:/02/NY/Monroe_36055C/STUDY__TO90/TECHNICAL/ENG_FLOOD_HAZ_DEV/COASTAL/WAVE_MODELING/CSHORE_J/Hydrographs/ouput"
  #call subprocess
  def crude_parrallelization(stormlist):
    df = pd.read_csv(stormlist,header=False,names=['storm'])
    for i in range(len(df.storm)):
      data1 = [1,df.storm[i*1]]
      ser1 = pd.Series(data1)
      name1 = str(ser1[1])+'.txt'
      ser1.to_csv(name1,index=False)
      subprocess.Popen([getstationoutput_exe,
                        stationfile,
                        name1,
                        datafiles_directory,
                        output_directory]).wait()
      os.remove(name1)
  crude_parrallelization(stormlist[num])
if __name__ == '__main__':
  main()
