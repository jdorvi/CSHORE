""" Calculate sediment fall velocity for CSHORE input file, based on a matlab
script by M. Shultz.
Author: J. Dorvinen
Email: jdorvinen@dewberry.com
Date: 3/21/2017 """

from __future__ import division

# Define constants
G = 9.81 # (m/s/s)
T = 2    # (deg C) assumed average temperature for storm season (Nov-April)
S = 0    # (salinity) assume freshwater
RHOS = 2650 # Density of sediment (kg/m**3)
D50 = 0.7 # (mm) mass median grainsize diameter

# Define functions
def getDensity(T, S):
    """ Estimate water density from temperature and salinity
        Approximation from VanRijn, L.C. (1993) Handbook for Sediment Transport
        by Currents and Waves
        where rho = density of water (kg/(m**3))
                T = temperature (deg C)
                S = salinity (o/oo) """
    _cl = (S-0.03)/1.805  #VanRijn
    if _cl < 0:
        _cl = 0.0

    rho = 1000 + 1.455*_cl - 6.5*10**(-3)*(T - 4 + (0.4*_cl))**2  # from VanRijn (1993)
    return rho

def getKinematicViscosity(T):
    """Kinematic viscosity of water approximation from
    VanRijn, L.C. (1989) Handbook of Sediment Transport
    valid range approximately 0-35 deg C - JD 3/21/2017
    kvis = kinematic viscosity (m**2/sec)
    T = temperature (C) """
    kvis = 1*10**(-6)*(1.14 - 0.031*(T-15) + 6.8*10**(-4)*(T-15)**2)
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
    print(d50)
    d50_m = d50/1000 #convert mm to m
    print(d50_m)
    s = rhos/rho
    D = (G*(s-1) / kvis**2)**(1/3) * d50_m
    w = (kvis/d50_m) * ((10.36**2 + 1.049*D**3)**0.5 - 10.36)
    return w

def main():
    """ Main function """
    rho = getDensity(T, S)
    kvis = getKinematicViscosity(T)
    wf = getFallVelocity(rho, kvis, RHOS, D50)
    print('{0:.5f}'.format(wf))

# Run main function
if __name__ == '__main__':
    main()
