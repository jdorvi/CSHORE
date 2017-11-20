# -*- coding: utf-8 - Python 3.6.x *-
"""
runup_reduction.py

Description: Apply runup reduction coefficient to STATS_2perRunup.py outputs.

Input(s): file path to input file containing paths to:
          county runup reduction file,
          directory of STATS_2perRunup output files,
          directory to contain max_runup files after runup reduction
Output(s): max_runup.txt files with reduced runup.

Example of usage:
python runup_reduction.py <input_file_path>

Author(s):
J. Dorvinen

Email:
jdorvinen@dewberry.com

Created on Mon May 01 2017
"""
# Import modules
import os
import sys

# Import paths from config file
CONFIGFILE = sys.argv[1]
PATHS = [line.strip().split()[0] for line in open(CONFIGFILE, 'r')]
RUNUPF = PATHS[0]
INPATH = PATHS[1]
OUTPTH = PATHS[2]

# Import runup reduction factors
ROUGH = {lne.strip().split(',')[0]:float(lne.strip().split(',')[1]) for lne in open(RUNUPF, 'r')}

# Walk through files and apply reduction coefficient
for root, dirs, files in os.walk(INPATH):
    for name in files:
        if "max_runup.txt" in name:
            # Import roughness coefficient
            roughness = ROUGH[name.split('_')[0]]
            with open(os.path.join(OUTPTH, name), 'w') as outfile:
                with open(os.path.join(INPATH, name), 'r') as infile:
                    for line in infile:
                        # Parse each line and extract parameters
                        parsed = line.strip().split()
                        storm = parsed[0]
                        total_swel = float(parsed[1])
                        swel = float(parsed[2])
                        runup = float(parsed[3])
                        time_days = parsed[4]
                        # Apply runup reduction
                        new_swel = (total_swel-swel)*roughness + swel
                        new_runup = runup*roughness
                        # Form the new line for output
                        outline = '{0} {1:.6f} {2:.6f} {3:.6f} {4}\n'.format(storm,
                                                                             new_swel,
                                                                             swel,
                                                                             new_runup,
                                                                             time_days)
                        # Write each new line to the output file
                        outfile.write(outline)
