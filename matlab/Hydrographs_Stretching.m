function err = Hydrographs_Stretching(inpth1,inpth2,inpth3,outpth,id,storm,dconv)
%function err = Hydrographs_Stretching(inpth1,inpth2,inpth3,outpth,id,storm,dconv)
%--------------------------------------------------------------------------
%This function uses a specified storm hydrograph and then scales the
%hydrographs for the 5 JPM scenarios
%%MFS 11-07-2014
%--------------------------------------------------------------------------
%INPUT
%   inpth1      - input file path for JPM scenarios text file
%   inpth2      - input file path for storm hydrographs
%   inpth3      - input file path for storm lake level adjustments
%   outpth      - output file path
%   id          - transect ID (hydroid)
%   storm       - storm identifier
%   dconv       - conversion factor in meters added to storm water levels
%OUTPUT
%   err         - error code (=1 if successful)
%--------------------------------------------------------------------------
% clear all;close all;
% inpth1='\\surly.mcs.local\flood\Temp\yz\ErieTest\JPM_Scenarios\output';
% inpth2='\\surly.mcs.local\flood\Temp\yz\ErieTest\Hydrographs\output';
% inpth3='\\surly.mcs.local\flood\Temp\yz\ErieTest\Hydrograph_stretching\input';
% outpth='\\surly.mcs.local\flood\Temp\yz\ErieTest\Hydrograph_stretching\output';
% storm='20001212';
% id='6';
% dconv='174';

err=-1;
n=5;    %number of scenarios
dconv = str2double(dconv);   

%load the JPM scenario data
filename=strcat(inpth1,'\JPM_scenarios_',id,'.txt');
fid = fopen(filename);
header=fscanf(fid, '%s\t%s\t%s\t%s\t%s\t%s\n',6);
JPM_Results=fscanf(fid,'%d\t%f\t%f\t%f\t%f\t%f\n',[6,n])';
fclose(fid);

%load the hydrograph data
filename=strcat(inpth2,'\',storm,'_',id,'.txt');
[hydro]=load(filename,'ascii');

%load the storm lake level adjustments
filename=strcat(inpth3,'\stormlakelevel_adjust_m.txt');
[storm_adj]=load(filename,'ascii');

%find adjustment for specified storm
adjust_wl = storm_adj(storm_adj(:,1)==str2num(storm),2);

time=hydro(:,1)/86400;          %convert to days

%reset the storm surge hydrograph to be relative to the input datum
orig_ts=hydro(:,2)+dconv;  
hydro(:,2)=hydro(:,2)-adjust_wl+dconv;    
% hydro(:,2)=hydro(:,2)/.3048;        %convert to feet

figure1 = figure('Color', [1 1 1], 'visible', 'off');
s1 = subplot(3,1,1);
hold on; grid on;
plot(time,hydro(:,2)/0.3048,'k--');      %water level (ft)
% plot(time,orig_ts/0.3048,'g--');
title(['Scaled Storm Time Series, Transect: ', id])
ylabel('SWEL (ft)');
s2 = subplot(3,1,2);
hold on; grid on;
plotHs=hydro(:,3)/0.3048;
plotHs(plotHs<0)=nan;
plot(time,plotHs,'k--');      %wave height (Hs)
ylabel('Hs (ft)');
s3 = subplot(3,1,3);
hold on; grid on;
plotTp=hydro(:,4);
plotTp(plotTp<0)=nan;
plot(time,plotTp,'k--');      %wave period (Tp)
ylabel('Tp (s)');
xlabel('Time (Days)');

% find the maximum surge and time of max (exclude the first day)
start_id=find(hydro(:,1)>86400,1);
[max_surge, max_id] =max(hydro(start_id:end,2));
maxTime = hydro(max_id+start_id-1,1);
max_Hs =max(hydro(:,3));
max_Tp =max(hydro(:,4));

TempLeftTimeVal = maxTime - 64800;  %18-hour window around peak
TempRightTimeVal = maxTime + 64800; %18-hour window around peak
LeftTimeIndex = find(hydro(:,1) == TempLeftTimeVal );
RightTimeIndex = find(hydro(:,1) == TempRightTimeVal );

colorpl='bmycr';
%     
%%--------------------------------------------------------------------------
for ii = 1:n
    hydro_stretch = hydro;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Water Level   
    
    WaterLevel100Year = JPM_Results(ii,2)*0.3048;  %convert to meters
    WaterLevelDifference =  abs(max_surge/WaterLevel100Year);
    
    hydro_stretch(LeftTimeIndex:RightTimeIndex,2) = ...
        hydro(LeftTimeIndex:RightTimeIndex,2)/WaterLevelDifference;
    subplot(s1);
    plot(time,hydro_stretch(:,2)/0.3048,colorpl(ii),'linewidth',2);      %water level (ft)
    if ii==n
       legend(storm, 'Scenario1', 'Scenario2', 'Scenario3','Scenario4', 'Scenario5');
    end
    
    hydro_stretch(:,2)=hydro_stretch(:,2)-dconv;  %convert back to original datum

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Wave height
    WaveHeight100Year = JPM_Results(ii,3)*0.3048;  %convert to meters
    WaveHeightDifference = max_Hs/WaveHeight100Year;
    
    hydro_stretch(:,3) = hydro(:,3)/WaveHeightDifference;
    subplot(s2);
    plotHs = hydro_stretch(:,3)/0.3048;
    plotHs(plotHs<0)=nan;
    plot(time,plotHs,colorpl(ii),'linewidth',2);      %wave height (ft)

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Period - similar to wave height
    WavePeriod100Year = JPM_Results(ii,6);
	WaveTsDifference = max_Tp/WavePeriod100Year;
    
    hydro_stretch(:,4) = hydro(:,4)/WaveTsDifference;
    subplot(s3);
    plotTp = hydro_stretch(:,4);
    plotTp(plotTp<0)=nan;    
    plot(time,plotTp,colorpl(ii),'linewidth',2);      %wave period (sec)
    
    fid = fopen(strcat(outpth,'\1000000',num2str(ii),'_',id,'.txt'),'w');
    fprintf(fid,'%f\t%f\t%f\t%f\n', hydro_stretch');
    fclose(fid);
end
    
figura1 = [outpth,'\hydro_stretch_',id];
saveas(figure1,figura1,'png');

err=1;
