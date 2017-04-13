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
from time import sleep
from concurrent.futures import ProcessPoolExecutor
import os
import numpy as np
os.chdir("P:/02/NY/Chautauqua_Co_36013C/STUDY__TO90/TECHNICAL/ENG_FLOOD_HAZ_DEV/COASTAL/WAVE_MODELING/CSHORE/hydrographs")
from NODES_LIST_chautauqua_redo_tran_16 import NODES_LIST
from TRANSECTS_chautauqua_redo_tran_16 import TRANSECTS
from STORM_LIST_chautauqua import STORM_LIST

#------------User Inputs----------------------------#
PARENT_DIR = "P:/05/LakeErie_General/Storms/"
OUTPUT_DIR = "P:/02/NY/Chautauqua_Co_36013C/STUDY__TO90/TECHNICAL/ENG_FLOOD_HAZ_DEV/COASTAL/WAVE_MODELING/CSHORE/hydrographs/test/"
INPUTFILES = ["fort.63", "swan_TPS.63", "swan_HS.63"]
PARAMETERS = {"fort.63":"SWEL", "swan_TPS.63":"TPS", "swan_HS.63":"HS"}
TIME_STEPS = {"SWEL":0, "TPS":0, "HS":0}

# Create empty list to store processes
PROCESSES = []
# Maximum number of processes to run at one time
MAX_PROCESSES = 6
EXECUTOR = ProcessPoolExecutor(MAX_PROCESSES)

#------------------------------BEGIN SCRIPT----------------------------------#
def div_rem(x, y):
    """ Divide x by y, return int value and remainder """
    value = x//y
    remainder = x%y
    return (value, remainder)

def normalize_data_timesteps(time_steps, nodes_list):
    """ Normalize time steps for all data """
    # Check if there are different timestep lengths present in the data
    if max(time_steps.values()) != min(time_steps.values()):
        # If there are we need to resample the data so that everything is on a uniform timestep
        #print("need to resample")
        # Define the relative size of a given parameter's timestep to the minimum timestep size
        relative_steps = deepcopy(TIME_STEPS)
        relative_steps['SWEL'] = div_rem(time_steps['SWEL'], min(time_steps.values()))
        relative_steps['HS'] = div_rem(time_steps['HS'], min(time_steps.values()))
        relative_steps['TPS'] = div_rem(time_steps['TPS'], min(time_steps.values()))
        # Make sure that all timesteps of differnt sizes are multiples of one another
        if max([relative_steps['SWEL'][1], relative_steps['HS'][1], relative_steps['TPS'][1]]) > 0:
            print("SWAN and ADCIRC timesteps non divisible, cannot resample data")
            raise TypeError
        # Make sure that the largest and smallest timesteps are just a factor of two different
        elif max([relative_steps['SWEL'][0], relative_steps['HS'][0], relative_steps['TPS'][0]]) > 2:
            print("SWAN and ADCIRC timesteps ratio greater than 2, cannot resample data")
            raise TypeError
        # Resample data
        #print("Resampling!")
        # Step through each parameter in the data
        for param in relative_steps:
            # Check if the data needs to be scaled.
            if relative_steps[param][0] == 2:
                # If the data needs to be scaled, let's progress transect by transect
                for transect in TRANSECTS:
                    #print(transect)
                    # Step through the nodes extracted at each transect
                    for node in TRANSECTS[transect]:
                        # The length of the new dataset will be twice that of the current dataset
                        new_steps = np.arange(0, 2*len(nodes_list[node][param]))
                        # Create an empty list to temporarily store our new, resampled, data
                        new_values = []
                        # For each step in the new dataset
                        for i in new_steps:
                            # If it's the first step, we'll set it to half of the original first
                            # step value
                            if i == 0:
                                new_values.append(nodes_list[node][param][i]/2)
                            # If it's an even numbered step, we will interpolate between previous
                            # values from our original, coarse dataset
                            elif i%2 == 0:
                                new_values.append((nodes_list[node][param][i/2]+nodes_list[node][param][(i/2)-1])/2)
                            # If it's an odd numbered step, we'll keep the original value from the
                            # coarse dataset
                            else:
                                new_values.append(nodes_list[node][param][(i-1)/2])
                        #print(len(nodes_list[node][param]))
                        # Update the values for the given node/parameter combination
                        nodes_list[node][param] = new_values
                        #print(len(nodes_list[node][param]))
    # If everything has the same stepsize there is no need to resample the data
    else:
        #print("no need to resample")
        pass
    # Return the updated dataset
    return nodes_list

def write_data_to_files(time_steps, nodes_list, storm):
    """ Writing data to files """
    #print("writing data to files")
    # Step throught the transects that we're extracting
    for transect in TRANSECTS:
        #print(transect)
        # Step through the nodes that we're extracting
        for node in TRANSECTS[transect]:
            # Set output file name
            filename = "{0}_{1}_{2}.txt".format(storm, transect, node)
            # Find the length of the longest dataset
            length = max([len(nodes_list[node]['SWEL']),
                          len(nodes_list[node]['HS']),
                          len(nodes_list[node]['TPS'])])
            # Create timestep series of same length as longest dataset
            timesteps = np.arange(0, length)
            #print(len(timesteps))
            # Open output file and write data line by line
            with open(os.path.join(OUTPUT_DIR, filename), 'w') as savefile:
                # Set standard line format
                line = '{0:>12.2f}{1:>15.6f}{2:>15.6f}{3:15.6f}\n'
                # Write first line, timestep zero with all parameters set to zero
                savefile.write(line.format(0, 0, 0, 0)) #format(0, SWEL[storm], 0, 0))
                # Step through timestep series
                for step in timesteps:
                    # Model time at each timestep is based on the minimum sized timestep
                    try:
                        time = (step+1)*min(time_steps.values())
                    except Exception:
                        time = 0
                        print("Damnit!")
                    # Extract value at each timestep for each parameter, from each node
                    try:
                        swel = nodes_list[node]['SWEL'][step]
                    except LookupError:
                        swel = 'nan'
                    try:
                        hsig = nodes_list[node]['HS'][step]
                    except LookupError:
                        hsig = 'nan'
                    try:
                        tps = nodes_list[node]['TPS'][step]
                    except LookupError:
                        tps = 'nan'
                    # Write line to savefile for each timestep
                    savefile.write(line.format(time, swel, hsig, tps))

def extract(root, storm):
    """Extracts data from ADCIRC time series files"""
    nodes_list = deepcopy(NODES_LIST)
    time_steps = deepcopy(TIME_STEPS)
    for filed in INPUTFILES:
        print("Extracting {0}/{1}".format(root, filed))
        f63 = os.path.join(root, filed)                 #-- 63 files
        # Get timestep for each input file from file header
        with open(f63, 'r') as fin:
            # Waste first to lines of file header, not needed
            [fin.readline() for i in range(2)]
            # Our value of interest is located on the third line of the file header
            time_step = int(fin.readline().strip().split()[1])
            # Assign the timestep size to the corresponding data parameter in time_steps
            time_steps[PARAMETERS[filed]] = time_step
        # Extract data for each node in nodes_list
        with open(f63, 'r') as fin:
            for line in fin:
                mynode = line.strip().split(' ')[0]     #--Test each line
                if mynode in nodes_list.keys():
                    value = float(line.strip().split()[1])
                    nodes_list[mynode][PARAMETERS[filed]].append(value)
    # Resample data to uniform timesteps
    nodes_list = normalize_data_timesteps(time_steps, nodes_list)
    # Write the resampled data to our output files
    write_data_to_files(time_steps, nodes_list, storm)

def control_processes(max_processes):
    """ Control number of processes runing at one time.
    Inputs:
    PROCESSES = list of current processes
    max_processes = maximum number of processes to run at one time
    """
    while len(PROCESSES) >= max_processes:
        sleep(2)
        for process_number in reversed(range(len(PROCESSES))):
            if PROCESSES[process_number].done() is not False:
                del PROCESSES[process_number]

def tic():
    """ start timer """
    start_time = dt.now()
    print("\n==========START========= \n")
    print('Begin extracting data:\n')
    print(start_time)
    return start_time

def toc(start_time):
    """ stop timer """
    # Wait for it...
    while len(PROCESSES) > 0:
        sleep(2)
        for process_number in reversed(range(len(PROCESSES))):
            if PROCESSES[process_number].done() is not False:
                del PROCESSES[process_number]
    # Done!
    end_time = dt.now()
    tda = str(end_time-start_time).split('.')[0].split(':')
    print("\n===========END==========\n")
    print("Processing Time :\n")
    print("{0} hrs, {1} mins, {2} sec \n\n".format(tda[0], tda[1], tda[2]))

def main():
    """Main function, runs extract() funtion and times it."""
    start_time = tic()
    with open(os.path.join(OUTPUT_DIR, 'extract63.log'), 'w') as log:
        for storm in STORM_LIST:
            root = os.path.join(PARENT_DIR, storm)
            try:
                sleep(0.5)
                process = EXECUTOR.submit(extract, root, storm)
                PROCESSES.append(process)
                control_processes(MAX_PROCESSES)
                log.write(root + '\n')
            except FileNotFoundError:
                log.write(root + ' ' + 'FileNotFoundError')
    #toc(start_time)

if __name__ == "__main__":
    main()
