""" Extract 2 percent runup to text file.
author: J. Dorvinen
email: jdorvinen@dewberry.com
date: 5/11/2017
"""

# Initiate runup and slope variables
runup_ts = []
slope_ns = []
# extract runup timeseries
with open('ODOC', 'r') as fid:
    for line in fid:
        if '2 percent runup' in line:
            runup_ts.append(line.strip().split()[-1])
        elif 'SLPRUN=' in line:
            slope_ns.append(line.strip().split()[-1])
# write out timeseries to file
with open('runup2percent_slopenearshore.txt', 'w') as out:
    lineform = '{0:.2f}, {1:.6f}\n'
    for i in range(len(runup_ts)):
        out.write(lineform.format(float(runup_ts[i]), float(slope_ns[i])))
