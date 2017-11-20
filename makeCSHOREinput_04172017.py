""" makeCSHOREinput.py
makeCSHOREinput(inpth1, inpth2, outpth, transect_id, erod, d50, fb, dconv):
---------------------------------------------------------------------------
This code creates the CSHORE infile for the set of storms specified in the
input folder
infile:        This file will be the input file for CSHORE. This script
               will write out the infile, along with creating folders for
               each transect.
MFS    08-12-2014
MFS    09-24-2014 - Modified CSHORE input params: GAMMA, SLP, BLP
                  - Modified to not include sed params for non-eroding cases
       10-02-2014 - Remove first day of storm for ramping period
       11-17-2014 - Modified to filter out timesteps with ice or when dry
J.Dorvinen 03/22/2017 - converted to Python and refactored.
--------------------------------------------------------------------------
INPUT
   inpth1      - input file path for transect (req units in input file: meters)
   inpth2      - input file path for storms
   outpth      - output file path
   transect_id - transect ID (hydroid)
   erod        - indicator if erodible profile (1=true, 0=false)
   d50         - mean sediment grain size diameter D50 (mm)
   fb          - bottom friction factor (used if>0, otherwise default is 0.002)
   dconv       - conversion factor in meters added to storm water levels
OUTPUT
   err         - error code (=1 if successful)
--------------------------------------------------------------------------
Inputs/Files needed
--------------------------------------------------------------------------
profile*.txt:   Profile file for transect with specified id. Profile
(inpth1)        starting from Station 0 (offshore) and go to the most
                inland point. The Stations and Elevations are in meteres.
                The elevations have been normalized so the shoreline has
                the elevation 0 m.

stormlist.txt   List of storms for which input files will be created
(inpth2)
StormName_ID.txt: This file was created using the hydrograph extraction process,
(inpth2)        and has the time series of water elevation, Hs, and Tp
                for the storm duration
                Format: |Time (s) |Water ele(m) | Hs (m) | Tp(s) |

--------------------------------------------------------------------------
"""
# Import modules
from __future__ import division
import os
from time import localtime, strftime
import sys
import getopt
import numpy as np
#from cshore_transects import TRANSECTS

inpth1='//surly.mcs.local/flood/02/NY/Chautauqua_Co_36013C/STUDY__TO90/TECHNICAL/ENG_FLOOD_HAZ_DEV/COASTAL/WAVE_MODELING/CSHORE/CSHORE_Infile_Creater/input'
inpth2='//surly.mcs.local/flood/02/NY/Chautauqua_Co_36013C/STUDY__TO90/TECHNICAL/ENG_FLOOD_HAZ_DEV/COASTAL/WAVE_MODELING/CSHORE/Hydrograph_stretching/output'
outpth='//surly.mcs.local/flood/02/NY/Chautauqua_Co_36013C/STUDY__TO90/TECHNICAL/ENG_FLOOD_HAZ_DEV/COASTAL/WAVE_MODELING/CSHORE/CSHORE_Infile_Creater/output_test'
#transect_id = int('35') #35, 38
#d50 = float('0.7')
fb = float('0.015') # Default CSHORE value is 0.002, got recommendation for 0.015 from USACE
#erod = int('0')
dconv = float('174') # Lake Erie: 174, Lake Ontario: 74.2

# CSHORE execution and physical params
ILINE = 1        # 1 = single line
#IPROFL = erod    # 0 = no morph, 1 = run morph
ISEDAV = 0       # 0 = unlimited sand, 1 = hard bottom
IPERM = 0        # 0 = no permeability, 1 = permeable
IOVER = 1        # 0 = no overtopping , 1 = include overtopping
INFILT = 0       # 1 = include infiltration landward of dune crest
IWTRAN = 0       # 0 = no standing water landward of crest,
                 # 1 = wave transmission due to overtopping
IPOND = 0        # 0 = no ponding seaward of SWL
IWCINT = 1       # 0 = no Wave & Current interaction , 1 = include W & C interaction
IROLL = 1        # 0 = no roller, 1 = roller
IWIND = 0        # 0 = no wind effect
ITIDE = 0        # 0 = no tidal effect on currents
DX = 0.5         # constant dx
GAMMA = 0.5      # shallow water ratio of wave height to water depth
#SPORO = 0        # sediment porosity
#D50 = d50        # d_50 in mm
SG = 2.65        # specific gravity of sediment
EFFB = 0.005     # suspension efficiency due to breaking eB
EFFF = 0.01      # suspension efficiency due to friction ef
SLP = 0.4        # suspended load parameter
#SLPOT = .1       # overtopping suspended load parameter
TANPHI = 0.63    # tangent (sediment friction angle)
BLP = 0.002      # bedload parameter
RWH = 0.015      # numerical rununp wire height
ILAB = 0         # controls the boundary condition timing. reading the input wave and water level data separately.
FRIC_FAC = fb    # bottom friction factor

# Define constants
G = 9.81 # (m/s/s)
T = 2    # (deg C) assumed average temperature for storm season (Nov-April)
S = 0    # (salinity) assume freshwater
RHOS = SG*1000 # sediment density in kg/m**3

# Define functions
def getDensity(temperature=2, salinity=0):
    """ Estimate water density from temperature and salinity
        Approximation from VanRijn, L.C. (1993) Handbook for Sediment Transport
        by Currents and Waves
        where rho = density of water (kg/(m**3))
                T = temperature (deg C)
                S = salinity (o/oo) """
    _cl = (salinity-0.03)/1.805  #VanRijn
    if _cl < 0:
        _cl = 0.0

    rho = 1000 + 1.455*_cl - 6.5*10**(-3)*(temperature - 4 + (0.4*_cl))**2  # from VanRijn (1993)
    return rho

def getKinematicViscosity(temperature=2):
    """Kinematic viscosity of water approximation from
    VanRijn, L.C. (1989) Handbook of Sediment Transport
    valid range approximately 0-35 deg C - JD 3/21/2017
    kvis = kinematic viscosity (m**2/sec)
    T = temperature (C) """
    kvis = 1*10**(-6)*(1.14 - 0.031*(temperature-15) + 6.8*10**(-4)*(temperature-15)**2)
    return kvis

def getFallVelocity(rho, kvis, rhos, d50):
    """compute fall velocity from D50 based on Soulsby's (1997) optimization.
    adopted code from Jarrell Smith, USACE CHL, Vicksburg, MS
    w = 10.36 * (kvis/d) * ((1 + 0.156*((s-1)*g*(d**3)))**0.5 - 1)
    or
    w = kvis/d* [sqrt(10.36^2 + 1.049 D^3) - 10.36]
    where w = sediment fall velocity (m/s)
          d = grain diameter (mm)
          T = temperature (deg C)
          S = Salinity (o/oo)"""
    d50_m = d50/1000. #convert mm to m
    s = rhos/rho
    D = (G*(s-1) / kvis**2)**(1/3.) * d50_m
    w = (kvis/d50_m) * ((10.36**2 + 1.049*D**3)**0.5 - 10.36)
    return w

def makeCSHOREinput(inpth1, inpth2, outpth, transect_id, erod, d50, dconv=0):
    """ Build CSHORE input file """
    # Initialize 'err' variable
    err = 1

    # Standard error log string format
    logline = "{0}\t{1}\t{2}\t{3}\t{4}\t{5}\t{6}\t{7}\n"

    # Calculate sediment fall velocity
    rho = getDensity(T, S)
    kvis = getKinematicViscosity(T)
    wf = getFallVelocity(rho, kvis, RHOS, d50)

    # Load in transect profile information that has been extracted from DEM
    #profile = pd.read_csv(os.path.join(inpth1,'profile{}.txt'.format(transect_id)),
    #                      delimiter=" ",
    #                      header=None,
    #                      names=["station", "elevation"])
    # or could use numpy
    profile = np.loadtxt(os.path.join(inpth1, 'profile{}.txt'.format(transect_id)))

    # Create profile matrix, the third column is the bottom friction
    # coefficient. Use default of 0.002 if not specified.
    bottom_friction = profile.sum(1)[..., None]*0+FRIC_FAC
    profile = np.append(profile, bottom_friction, axis=1)

    # Load in storm/scenario list
    storms = np.loadtxt(os.path.join(inpth2, 'stormlist.txt'))

    with open(os.path.join(outpth, 'makeCSHOREinput.log'), 'a') as log:
        log.write(logline.format('Datetime',
                                 'Transect ID',
                                 'Storm',
                                 'Num of Timesteps',
                                 'Valid Timesteps SWEL',
                                 'Valid Timesteps Hs',
                                 'Valid Timesteps Tp',
                                 'Filtered Timesteps'))

        # Initialize count
        count = len(storms)

        # Step through all storms
        ii = 0
        while ii < count and err == 1:
            # For every scenario/storm, create the input files.

            # Load hydrograph data
            data = np.loadtxt(os.path.join(inpth2, '{}_{}.txt'.format(int(storms[ii]), transect_id)))
            time = data[:, 0]
            swel = data[:, 1] + dconv # Add conversion factor
            height = data[:, 2]/np.sqrt(2) # convert Hs to Hrms
            period = data[:, 3]

            # Remove first day for ramping period
            id_s = int(np.where(time == 86400)[0])
            swel = swel[id_s:]
            height = height[id_s:]
            period = period[id_s:]
            time = time[id_s:]-86400
            # Check for good data values (> -100) in SWEL, Hs, and Tp. Filter out
            # remaining
            n_cnt = len(swel)

            # Filter based on SWEL
            ids_w = np.where(swel > -100)
            swel = swel[ids_w]
            height = height[ids_w]
            period = period[ids_w]
            time = time[ids_w]

            # Filter based on height
            ids_h = np.where(height > -100)
            swel = swel[ids_h]
            height = height[ids_h]
            period = period[ids_h]
            time = time[ids_h]

            # Filter based on period
            ids_t = np.where(period > -100)
            swel = swel[ids_t]
            height = height[ids_t]
            period = period[ids_t]
            time = time[ids_t]

            # Find total dataseries length after filtering
            filt_cnt = len(swel)

            # If filtering has removed any data, print this in the log file
            if filt_cnt < n_cnt:
                tnow = localtime()
                now = strftime("%Y-%m-%d %H:%M:%S", tnow)
                log.write(logline.format(now,
                                         transect_id,
                                         storms[ii],
                                         n_cnt,
                                         len(ids_w[0]),
                                         len(ids_h[0]),
                                         len(ids_t[0]),
                                         filt_cnt))

            # If any valid time steps remain, write CSHORE input file
            if filt_cnt > 0:
                # Ensure first timestep is time=0 (required for CSHORE)
                time[0] = 0
                
                # SWEL data for CSHORE
                cswel = np.vstack((time, swel)).T

                # Move the wave data into variables in the format needed for CSHORE,
                # timestep, wave period, wave height, wave direction (zeros)
                cwave = np.vstack((time, period, height, height*0)).T

                # Assign NSURGE, it is the length of the surge record ###minus 1.
                nsurge = len(swel) -1

                # Assign NWAVE, it is the length of the wave record ###minus 1.
                nwave = len(cwave) -1

                # Assign NBINP, it is the length of the profile record.
                nbinp = len(profile)

                # Write out some bits of the file header
                str1 = '4\n'
                str2 = '---------------------------------------------------------------------\n'
                str3 = 'CSHORE input file for Transect{0}\n'.format(transect_id)
                str4 = 'Storm: {0}, TR={1}\n'.format(int(storms[ii]), transect_id)

                # assign standard heading
                s01 = '{0:<42}->ILINE\n'.format(ILINE)
                s02 = '{0:<42}->IPROFL\n'.format(erod) # Movable bottom
                s03 = '{0:<42}->ISEDAV\n'.format(ISEDAV) # unlimited sediment availability, if IPROFL = 1, ISEDAV must be specified.
                s04 = '{0:<42}->IPERM \n'.format(IPERM)   # Impermeable bottom
                s05 = '{0:<42}->IOVER\n'.format(IOVER)   # wave overtopping allowed
                s06 = '{0:<42}->IWTRAN\n'.format(IWTRAN) # no standing water or wave transmission in a bay landward of dune. must be specified if IOVER = 1, although not applicable.
                s07 = '{0:<42}->IPOND\n'.format(IPOND)   #
                s08 = '{0:<42}->INFILT\n'.format(INFILT)
                s09 = '{0:<42}->IWCINT\n'.format(IWCINT) # wave and current interactions
                s10 = '{0:<42}->IROLL\n'.format(IROLL)   # roller effects in wet zone
                s11 = '{0:<42}->IWIND\n'.format(IWIND)   # No wind effects
                s12 = '{0:<42}->ITIDE\n'.format(ITIDE)
                s13 = '{0}{1:<37.3f}->DX\n'.format(' '*5, DX)  # Constant nodal spacing
                s14 = '{0}{1:<37.4f}->GAMMA\n'.format(' '*5, GAMMA)  # empirical breaker ration.
                s15 = '{0}{1:.1f}{0}{2:.6f}{0}{3:.4f}{4}->D50 WF SG\n'.format(' '*5, d50, wf, SG, ' '*9) # mean sediment diameter, sediment fall velocity, sediment specific gravity.
                s16 = '{0}{1:.4f}{0}{2:.4f}{0}{3:.4f}{0}{4:.4f}{5}->EFFB EFFF SLP\n'.format(' '*5, EFFB, EFFF, SLP, 0.1, ' '*14) #suspension efficiency due to wave breaking, suspension efficiency due to btm friction, suspension load parameter
                s17 = '{0}{1:.4f}{0}{2:.4f}{3}->TANPHI BLP\n'.format(' '*5, TANPHI, BLP, ' '*20) # sediment limiting (maximum) slope, bedload parameter. needed if IPROFL = 1.
                s18 = '{0}{1:.3f}{2}->RWH \n'.format(' '*5, RWH, ' '*32) # runup wire height
                s19 = '{0:<42}->ILAB \n'.format(ILAB) # reading the input wave and water level data separately.

                # Create directory and infile for storm
                tran_direct = os.path.join(outpth, 'TR{}'.format(transect_id))
                if os.path.exists(tran_direct) is False:
                    os.mkdir(tran_direct)
                directory = os.path.join(outpth, 'TR{}'.format(transect_id), str(int(storms[ii])))
                if os.path.exists(directory) is False:
                    os.mkdir(directory)
                with open(os.path.join(directory, 'infile'), 'w') as fid:
                    # Start writing out header to infile
                    fid.write(str1+str2+str3+str4+str2)

                    # Write standard heading
                    if erod == 1:
                        fid.write(s01+s02+s03+s04+s05+s06+s07+s08+s09+s10+s11+s12+s13+s14+s15+s16+s17+s18+s19)
                    else:
                        fid.write(s01+s02+s04+s05+s06+s07+s09+s10+s11+s12+s13+s14+s18+s19)
                    fid.write('{0:<42.0f}->NWAVE\n'.format(nwave))
                    fid.write('{0:<42.0f}->NSURGE\n'.format(nsurge))

                    # Print wave data
                    for j in range(len(cwave)):
                        fid.write('{0:>11.1f}{1:>11.2f}{2:>11.2f}{3:>11.2f}\n'.format(cwave[j, 0],
                                                                                      cwave[j, 1],
                                                                                      cwave[j, 2],
                                                                                      cwave[j, 3]))

                    # Print surge data
                    for j in range(len(cswel)):
                        fid.write('{0:.1f}{1:>11.2f} \n'.format(cswel[j, 0],
                                                                cswel[j, 1]))

                    # Print number of pts in transect file
                    fid.write('{0:>6.0f}      -> NBINP \n'.format(nbinp))

                    # Print profile
                    for j in range(len(profile)):
                        fid.write('{0:.2f}{1:>15.2f}{2:>12.4f}   \n'.format(profile[j, 0],
                                                                            profile[j, 1],
                                                                            profile[j, 2]))
            # Increment counter
            ii += 1

def main(argv):
    """ main function """
    from cshore_transects import TRANSECTS
    for transect_id in TRANSECTS:
        d50 = TRANSECTS[transect_id]['d50']
        erod = TRANSECTS[transect_id]['erod']
        makeCSHOREinput(inpth1, inpth2, outpth, transect_id, erod, d50, dconv)

if __name__ == '__main__':
    main(sys.argv[1:])
