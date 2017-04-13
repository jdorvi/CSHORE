function err = makeCSHOREinput(inpth1,inpth2,outpth,id,erod,d50,fb,dconv)
%function err = makeCSHOREinput(inpth1,inpth2,outpth,id,erod,d50,fb,dconv)
%--------------------------------------------------------------------------
%This code creates the CSHORE infile for the set of storms specified in the
%input folder 
%infile:        This file will be the input file for CSHORE. This script
%               will write out the infile, along with creating folders for
%               each transect.
%MFS    08-12-2014
%MFS    09-24-2014 - Modified CSHORE input params: GAMMA, SLP, BLP
%                  - Modified to not include sed params for non-eroding cases
%       10-02-2014 - Remove first day of storm for ramping period
%       11-17-2014 - Modified to filter out timesteps with ice or when dry
%--------------------------------------------------------------------------
%INPUT
%   inpth1      - input file path for transect (req units in input file: meters)
%   inpth2      - input file path for storms
%   outpth      - output file path
%   id          - transect ID (hydroid)
%   erod        - indicator if erodible profile (1=true, 0=false)
%   d50         - mean sediment grain size diameter D50 (mm)
%   fb          - bottom friction factor (used if>0, otherwise default is 0.002) 
%   dconv       - conversion factor in meters added to storm water levels 
%OUTPUT
%   err         - error code (=1 if successful)
%--------------------------------------------------------------------------
%Inputs/Files needed
%--------------------------------------------------------------------------
%profile*.txt:   Profile file for transect with specified id. Profile
%(inpth1)        starting from Station 0 (offshore) and go to the most
%                inland point. The Stations and Elevations are in meteres.
%                The elevations have been normalized so the shoreline has
%                the elevation 0 m.
%
%stormlist.txt   List of storms for which input files will be created
%(inpth2)
%StormName_ID.txt: This file was created using the hydrograph extraction process,
%(inpth2)        and has the time series of water elevation, Hs, and Tp
%                for the storm duration 
%                Format: |Time (s) |Water ele(m) | Hs (m) | Tp(s) |
%
%--------------------------------------------------------------------------
% inpth1='\\surly.mcs.local\flood\05\OH\ERIE_CO_OH_39043(CTP)\TECHNICAL\ENG_FLOOD_HAZ_DEV\COASTAL\WAVE_MODELING\CSHORE\CSHORE_Infile_Creater\input';
% inpth2='\\surly.mcs.local\flood\05\OH\ERIE_CO_OH_39043(CTP)\TECHNICAL\ENG_FLOOD_HAZ_DEV\COASTAL\WAVE_MODELING\CSHORE\Hydrographs\output';
% outpth='\\surly.mcs.local\flood\05\OH\ERIE_CO_OH_39043(CTP)\TECHNICAL\ENG_FLOOD_HAZ_DEV\COASTAL\WAVE_MODELING\CSHORE\CSHORE_Infile_Creater\output\test';
% id='13';
% d50='0.1512';
% fb='.002';
% erod='1';
% dconv = '174';

err = 1;
dconv = str2num(dconv);

%compute fall velocity from D50 based on Soulsby's (1997) optimization.
% adopted code from Jarrell Smith, USACE CHL, Vicksburg, MS
%  w = kvis/d* [sqrt(10.36^2 + 1.049 D^3) - 10.36]
%  where w = sediment fall speed (m/s)
%        d = grain diameter (mm)
%        T = temperature (deg C)
%        S = Salinity (ppt)

g=9.81;
T=2;    %assumed average temperature for storm season (Nov-April)
S=0;    %assume freshwater
%Estimate water density from temperature and salinity
%Approximation from VanRijn, L.C. (1993) Handbook for Sediment Transport 
%                     by Currents and Waves
%  where  rho = density of water (kg/m^3)
%           T = temperature (C)
%           S = salinity (o/oo)
CL=(S-0.03)/1.805;  %VanRijn
in=CL<0;
CL(in)=0;
rho=1000 + 1.455.*CL - 6.5e-3* (T-4+0.4.*CL).^2;  %from VanRijn (1993)

%Kinematic viscosity of water approximation from 
%VanRijn, L.C. (1989) Handbook of Sediment Transport
%kvis = kinematic viscosity (m^2/sec)
%T = temperature (C)
kvis=1e-6*(1.14 - 0.031*(T-15) + 6.8E-4*(T-15).^2);
rhos=2650;
d50_m=str2num(d50)/1000; %convert mm to m
s=rhos/rho;
D=(g*(s-1)/kvis^2)^(1/3)*d50_m;
wf=kvis./d50_m.*(sqrt(10.36^2+1.049*D.^3)-10.36); %settling speed

%Load in transect profile information that has been extracted from DEM
profile = load(strcat(inpth1,'\profile',id,'.txt'));

%Load in storm/scenario list
storms = load(strcat(inpth2,'\stormlist.txt'));

%Create profile matrix,the third column is the bottom friction
%coefficent. Use default of 0.002 if not specified
fb = str2double(fb);
if isnan(fb) || fb<=0
    fb=0.002;
end ;
profile = [profile(:,1) profile(:,2) profile(:,1).*0 + fb];

log = fopen(strcat(outpth,'\makeCSHOREinput.log'),'a');
fprintf(log, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 'Datetime', 'Transect ID', 'Storm', 'Num of Timesteps', 'Valid Timesteps SWEL', 'Valid Timesteps Hs', 'Valid Timesteps Tp', 'Filtered Timesteps');
count=length(storms);
ii=0;
while ii < count && err==1
    ii=ii+1;
    
    %For every scenario/storm, create the input files.
   
    %load hydrograph data
    data = load(strcat(inpth2,'\',num2str(storms(ii)), '_', id, '.txt'));
    time = data(:,1);
    swel = data(:,2)+dconv;    %Add conversion factor
    height = data(:,3)/sqrt(2); %convert Hs to Hrms
    period = data(:,4);
    clear data;
    
    %remove first day for ramping period
    id_s = find(time==86400);
    swel = swel(id_s:end);
    height = height(id_s:end);
    period = period(id_s:end);
    time = time(id_s:end)-86400;
    
    %check for good data values (> -99999) in SWEL, Hs and Tp and filter
    %out remaining
    n_cnt = length(swel);
    ids_w = find(swel>-100);
    ids_h = find(height>-100);
    ids_t = find(period>-100);
    
    swel = swel(ids_w);
    height = height(ids_w);
    period = period(ids_w);
    time = time(ids_w);
    
    ids_h = find(height>-100);
    swel = swel(ids_h);
    height = height(ids_h);
    period = period(ids_h);
    time = time(ids_h);
    
    ids_t = find(period>-100);
    swel = swel(ids_t);
    height = height(ids_t);
    period = period(ids_t);
    time = time(ids_t);
    
    %ensure first timestep is time=0 (required for CSHORE)
    time(1) = 0;
    filt_cnt= length(swel);
    if filt_cnt<n_cnt
        fprintf(log, '%s\t%s\t%s\t%d\t%d\t%d\t%d\t%d\n', datestr(now), id, num2str(storms(ii)), n_cnt, length(ids_w), length(ids_h), length(ids_t),filt_cnt);
    end
    
    if filt_cnt>0   %continue if any valid time steps remaining
        swel = [time swel];    
    
        %move the wave data into variables in the format needed for CSHORE,
        %timestep, wave period, wave height, wave direction (zeros)
        Waves = [time period height height.*0]; %time period height directional holder
        
        %assign NSURGE, an input to CSHORE, it is the length of the surge record minus 1.
        NSURGE = length(swel(:,1))-1;
        
        %assign NWAVE, an input to CSHORE, it is the length of the wave record minus 1.
        NWAVE = length(Waves(:,1))-1;
        
        %assign NBINP, an input to CSHORE, it is the length of the profile record.
        NBINP = length(profile(:,1));
        
        %Write out some bits of the header file
        str1 = '4';
        str2 = '---------------------------------------------------------------------';
        str3 = ['CSHORE input file for Transect', id];
        str4 = ['Storm: ', num2str(storms(ii)), ', TR=' id];
        
        %assign standard heading
        s1 = '1                                         ->ILINE';
        s2 = strcat(erod,'                                         ->IPROFL'); %Movable bottom
        s3 = '0                                         ->ISEDAV'; %unlimited sediment availability, if IPROFL = 1, ISEDAV must be specified.
        s4 = '0                                         ->IPERM '; %Impermeable bottom
        s5 = '1                                         ->IOVER';  %wave overtopping allowed
        s6 = '0                                         ->IWTRAN'; %no  standing water or wave transmission in a bay landward of dune. must be specified if IOVER = 1, although not applicable.
        s7 = '0                                         ->IPOND'; %
        s8 = '0                                         ->INFILT';
        s9 = '1                                         ->IWCINT'; %  wave and current interactions
        s10 = '1                                         ->IROLL'; % roller effects in wet zone
        s11= '0                                         ->IWIND'; % No wind effects
        s12= '0                                         ->ITIDE';
        s13= '     0.500                                ->DX'; %Constant nodal spacing
        s14= '     0.5000                               ->GAMMA'; % empirical breaker ration.
        %     s15= '     0.1500     0.0448     2.6500         ->D50 WF SG'; %mean sediment diameter, sediment fall velocity, sediment specific gravity.
%         s15= strcat('     ',d50,'     0.0448     2.6500         ->D50 WF SG'); %mean sediment diameter, sediment fall velocity, sediment specific gravity.
        s15= ['     ' d50 blanks(5) num2str(wf) '     2.6500         ->D50 WF SG']; %mean sediment diameter, sediment fall velocity, sediment specific gravity.
        s16= '     0.0050     0.0100     0.4000     0.1000              ->EFFB EFFF SLP'; %suspension efficiency due to wave breaking, suspension efficiency due to btm friction, suspension load parameter
        s17= '     0.6300     0.0020                    ->TANPHI BLP'; % sediment limiting (maximum) slope, bedload parameter. needed if IPROFL = 1.
        s18= '     0.015                                ->RWH '; % runup wire height
        s19= '0                                         ->ILAB '; % reading the input wave and water level data separately.
        
        %Write header file
        directory = strcat(outpth,'\TR', id, '\', num2str(storms(ii)));
        [err,~,msgID] = mkdir(directory); %make directory structure for CSHORE runs
        
        fid = fopen(strcat(directory,'\infile'), 'w');
        if err==0 || fid <0
            err=-1; %error opening infile/making directory
        else
            %start writing out header file.
            formatSpec = '%s\n%s\n%s\n%s\n';
            fprintf(fid, formatSpec, str1, str2, str3, str4, str2);
            
            %print standard heading
            formatSpec2 = '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n';
            if str2num(erod)>0
                fprintf(fid, formatSpec2, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15, s16, s17, s18, s19);
            else
                fprintf(fid, formatSpec2, s1, s2, s4, s5, s6, s7, s9, s10, s11, s12, s13, s14, s18, s19);
            end
            
            fprintf(fid, '%3.0f                                       ->NWAVE\n', NWAVE);
            fprintf(fid, '%3.0f                                       ->NSURGE\n',  NSURGE);
            
            %print wave data
            for j = 1:length(Waves)
                fprintf(fid, '%11.1f%11.2f%11.2f%11.2f\n', Waves(j,:));
            end
            
            %print surge data
            for j = 1:length(swel)
                fprintf(fid, '%0.1f%11.2f \n', swel(j,:));
            end
            
            %print number of pts in transect file
            fprintf(fid, '%6.0f      -> NBINP \n', NBINP);
            
            %print profile
            for j = 1:length(profile)
                fprintf(fid, '%0.2f         %6.2f      %6.4f   \n', profile(j,:));
            end
            fclose(fid);
        end
    end
end


fclose all;
