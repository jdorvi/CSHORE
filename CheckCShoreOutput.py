"""@package dewberry

@brief script that identifies the incorrect CSHORE output

This software is provided free of charge under the New BSD License. Please see
the following license information:

Copyright (c) 2014, Dewberry
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Dewberry nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE DEWBERRY
BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


@author(s) Janghwoan Choi <jchoi@dewberry.com>
           Jared Dorvinen <jdorvinen@dewberry.com>

4/13/2017 - Reformatted, rewrote directory walking method, added commentary, added logfile, and
updated syntax to be compatible with Python 3.x - JD

"""
# Import modules
import sys
import os

# Define functions
def is_number(string):
    """ Check if a string is a valid number.
    input:
    string - string characters being checked
    output:
    returns True or False
    ref:
    http://stackoverflow.com/questions/354038/how-do-i-check-if-a-string-is-a-number-in-python
    """
    try:
        # Convert original string to a float and then back to a string
        number = str(float(string))
        # Check if the number is 'nan' or a non-real number
        if number == "nan" or number == "inf" or number == "-inf":
            # if 'string' is not a real number, then it's not a number
            return False
    except ValueError:
        # if could not convert original string to a number, check it it is a complex number
        try:
            complex(string) # for complex
        except ValueError:
            # If can't confirm that 'string' is a complex number, then it's not a number
            return False
    # If 'string' is not a non-real number and/or is a complex number, then it's a number
    return True

def CheckCShoreOutput(inputfolderpath):
    """ CheckCShoreOutput(inputfolderpath)
    Function examines all CSHORE ODOC output files found in an 'inputfolderpath' to see if the
    model simulation was able to completely execute through all of the inputfile's timesteps.
    Input:
    inputfolderpath - parent folder containing all CSHORE model outputs
    Outputs:
    prints to screen path to any model simulations that did not completely finish.
    """
    # Open logfile in inputfolderpath
    with open(os.path.join(inputfolderpath, 'checkCSHOREoutput.log'), 'w') as logfile:
        # Walk the directory structure from the bottom up
        for root, dirs, files in os.walk(inputfolderpath, topdown=False):
            # For each file in a given directory
            for filed in files:
                # Check if the filename is 'ODOC', this is the CSHORE output file we're checking
                if filed == 'ODOC':
                    # Create full path to the ODOC file
                    odocfile = os.path.join(root, filed)
                    # Open the odoc file in read only mode
                    with open(odocfile, 'r') as odoc:
                        # Initialize variables
                        time_step_to_compare = ''
                        last_time_step = ''
                        # Read each line of the ODOC file
                        for line in odoc:
                            parsed = line.strip().split()
                            if len(parsed) == 6 and is_number(parsed[0]):
                                last_time_step = parsed[0]
                            elif "on input bottom profile at TIME" in line:
                                # changed this to use the parsed object - JD
                                time_step_to_compare = parsed[7] #line.split('=')[1].split('Line')[0].strip()
                            elif "on bottom profile computed at TIME" in line:
                                # changed this to use the parsed object - JD
                                time_step_to_compare = parsed[8] #line.split('=')[1].split('Line')[0].strip()
                        # If the last timestep of the model input and output are not the same,
                        if last_time_step != time_step_to_compare:
                            # create an error message
                            errormessage = 'error: {0} {1} {2}\n'.format(odocfile,
                                                                         last_time_step,
                                                                         time_step_to_compare)
                            # write it to the logfile
                            logfile.write(errormessage)
                            # and print it in the terminal
                            print(errormessage)
        # Check if any errors have been found,
        try:
            if errormessage in locals():
                pass
        except UnboundLocalError:
            # if not, print 'All's good' to errorlog
            message = 'No errors found in CSHORE output files contained in directory\n{}'
            logfile.write(message.format(inputfolderpath))
            # and print it in the terminal
            print(message.format(inputfolderpath))
    # Once all files are checked, print out "completed..."
    print("completed...")

if __name__ == '__main__':
    INPUTFOLDERPATH = sys.argv[1]
    CheckCShoreOutput(INPUTFOLDERPATH)
