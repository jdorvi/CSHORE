# -*- coding: utf-8 - Python 3.5.1 *-
"""
Description: Check & Fix Errors from GeoRAMP CSHORE Infile Creater tool

Input(s):  dirs, executable
Output(s): cshore files

Authors:
S.Lawler, J.Dorvinen

Email:
slawler@dewberry.com
jdorvinen@dewberry.com

Created on Wed Aug 31 08:54:01 2016

Updated on 3/23/2017
- added parallelization, process control, and timing fuctionality. JD

"""
#------------Load Python Modules--------------------#
import os
import shutil
import subprocess
import timeit
from time import sleep

# ~\CSHORE_Infile_Creater\output
ROOTDIR = r'P:\02\NY\Chautauqua_Co_36013C\STUDY__TO90\TECHNICAL\ENG_FLOOD_HAZ_DEV\COASTAL\WAVE_MODELING\CSHORE\CSHORE_Infile_Creater\output_test\TR1'

# CSHORE executable source directory
CSHOREDIR = r'\\wolftrap\MCS\FederalPrograms\Dept62\Coastal Group\CSHORE\cshore_usace_nosource-2015-05-06-10-57\convert_to_exe'

# CSHORE executable full path
CSHORE_EXE = os.path.join(CSHOREDIR, "CSHORE_Runup.exe")

# Command to execute
CMD = "CSHORE_Runup.exe"

# Create empty list to store processes
PROCESSES = []

# Maximum number of processes to run at one time
MAX_PROCESSES = 10

# Define helper functions
def control_processes(processes, max_processes):
    """ Control number of processes runing at one time.
    Inputs:
    processes = list of current processes
    max_processes = maximum number of processes to run at one time
    Script will continue to sleep and poll current processes until less than the maximum number of
    processeses (max_processes) are running, it will then allow the script to proceed.
    """
    while len(processes) >= max_processes:
        sleep(2)
        for process_number in reversed(range(len(PROCESSES))):
            if PROCESSES[process_number].poll() is not None:
                del PROCESSES[process_number]

def tic():
    """ start timer """
    global _start_time
    _start_time = timeit.default_timer()

def toc():
    """ stop timer """
    t_sec = round(timeit.default_timer() - _start_time)
    (t_min, t_sec) = divmod(t_sec, 60)
    (t_hour, t_min) = divmod(t_min, 60)
    print('CSHORE_Infile_Checker.py has finished, elapsed time: {}hour:{}min:{}sec'.format(t_hour,
                                                                                           t_min,
                                                                                           t_sec))

def main():
    """ Main program funtion. Open each transect folder, go through each storm, and verify ouput
    files were created. If not, copy the CSHORE_EXE to that folder and run it. """
    # Start script timer
    tic()
    # Open logfile, set write mode to append
    with open(os.path.join(CSHOREDIR, 'InfileChecker.log'), 'a') as logfile:
        # Walk directory structure
        for root, dirs, files in os.walk(ROOTDIR):
            # If only one file exists in the directory, assume it's a CSHORE input file and
            # attempt to run CSHORE, else move to next directory
            if len(files) == 1:
                try:
                    print(root)
                    shutil.copy(CSHORE_EXE, root)
                    os.chdir(root)
                    process = subprocess.Popen([CMD, os.path.join(root, files[0])],
                                               stdout=subprocess.PIPE)
                    PROCESSES.append(process)
                    control_processes(PROCESSES, MAX_PROCESSES)
                    logfile.write(root + '\n')
                except FileNotFoundError:
                    # If one of the necessary input files isn't in the cwd when attempt
                    # to start CSHORE is made, script will skip it and log a FileNotFoundError
                    logfile.write(root + ' FileNotFoundError\n')
                except PermissionError:
                    # If there is a file lock (e.g. another thread already started to work in
                    # this directory), script will skip it and log a PermissionError
                    logfile.write(root + ' PermissionError\n')
    toc()

if __name__ == '__main__':
    main()
