""" Extract 2 percent runup to text file.
author: J. Dorvinen
email: jdorvinen@dewberry.com
date: 5/11/2017
"""

# Initiate runup variable
runup_ts = []
# extract runup timeseries
with open('ODOC', 'r') as fid:
    for line in fid:
        if '2 percent runup' in line:
            runup_ts.append(line.strip().split()[-1])
# write out timeseries to file
with open('runup2percent.txt', 'w') as out:
    lineform = '{:.2f}\n'
    for runup in runup_ts:
        out.write(lineform.format(float(runup)))
