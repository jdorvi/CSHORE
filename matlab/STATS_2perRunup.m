function err = STATS_2perRunup(inpth1,inpth2,outpth,id,step)
%function err = STATS_2perRunup(inpth1,inpth2,outpth,id,step)
%--------------------------------------------------------------------------
%This function runs the response-based runup statistical analysis for a
%specified transect
%%MFS 06-06-2014
%%MFS 09-24-2014 added Q-Q optimization
%--------------------------------------------------------------------------
%INPUT
%   inpth1      - input file path for CSHORE output
%   inpth2      - input file path for storm list file (stormlist.txt))
%   outpth      - output file path
%   id          - transect ID (hydroid)
%   step        - step to perform (1=obtain max runup values,2=perform
%   stats)
%OUTPUT
%   err         - error code (=1 if successful)
%--------------------------------------------------------------------------
%Inputs/Files needed
%--------------------------------------------------------------------------
%ODOC               CSHORE output file for specified transect and each
%(inpth\ID\storm\)	storm in storm list
%stormlist.txt      List of storms for which output files will be read
%(inpth2)
%
%--------------------------------------------------------------------------
% clear all;
% inpth1='\\surly.mcs.local\flood\05\OH\OTTAWA_CO_OH(CTP)\TECHNICAL\ENG_FLOOD_HAZ_DEV\COASTAL\WAVE_MODELING\CSHORE\CSHORE_Infile_Creater\output';
% inpth2='\\surly.mcs.local\flood\05\OH\OTTAWA_CO_OH(CTP)\TECHNICAL\ENG_FLOOD_HAZ_DEV\COASTAL\WAVE_MODELING\CSHORE\Hydrographs\output\test';
% outpth='\\surly.mcs.local\flood\05\OH\OTTAWA_CO_OH(CTP)\TECHNICAL\ENG_FLOOD_HAZ_DEV\COASTAL\WAVE_MODELING\CSHORE\STATS_2perRunup\output\test';
% id='29';
% step='2';

id_num=str2num(id);
step_num=str2num(step);

%Load in storm/scenario list
storms = load(strcat(inpth2,'\stormlist.txt'));
Nyrs = storms(1); %# of years now inlcuded as first line in stormlist.txt - updated 3/9/15 -MFS
storms = storms(2:end);

max_runup = [];
outfile = strcat(outpth,'\',id,'_max_runup.txt');

if step_num==1
    for ii=1:length(storms)
        runup_ts=[];
        path=strcat(inpth1,'\TR', id, '\', num2str(storms(ii)));
        
        %open CSHORE output file containing 2 percent runup value
        fid = fopen(strcat(path,'\ODOC'));
        
        if (fid == -1)  %Flag if ODOC cannot open.... indicates error in running CSHORE, review input file
            err=-1; %error opening infile/making directory
            
            %         %save maximum runup values.
            %         fid2 = fopen(outfile,'w');
            %         fprintf(fid2, '%d %f %f\n', max_runup');
            %         fclose(fid2);
            %         return;
        else
            
            %read in ODOC
            tot = textscan(fid,'%s','delimiter','\n');
            tot = tot{:};
            
            % find all locations where 2% runup is identified.
            dum =strfind(tot,'2 percent runup');
            row_ind = ~cellfun('isempty',dum);
            dum = cell2mat(tot(row_ind));
            
            % find the still water elevations.
            dum2 =strfind(tot,'Still water level');
            row_ind2 = ~cellfun('isempty',dum2);
            dum2 = cell2mat(tot(row_ind2));
            
            %If 2% runup is specified,
            if ~isempty(dum)
                
                %get timeseries of 2% runup.
                col_ind = strfind(dum(1,:),'R2P=');
                runup_ts = str2num(dum(:,col_ind+4:end));
                
                %save timeseries of 2% runup to the CSHORE output folder
                tempout=strcat(path,'\runup2percent.txt');
                temp=runup_ts;
                dlmwrite(tempout, temp, '\t');
                
                %determine the maximum runup observed during that storm for this transect,
                %and write to holder matrix for that transect.
                max_runup(ii,1) = storms(ii);
                [C,I] = max(runup_ts);
                max_runup(ii,2) = C;
                max_runup(ii,5) = I*900/86400;
                
                %Get the associated SWEL
                if ~isempty(dum2)
                    %get timeseries of 2% runup.
                    col_ind = strfind(dum2(1,:),'SWL=');
                    swel_ts = str2num(dum2(:,col_ind+4:end));
                    max_runup(ii,3) = swel_ts(I);
                    max_runup(ii,4) = max_runup(ii,2)-max_runup(ii,3);%runup value
                else
                    err=-1; %error reading SWEL values
                end
            else %if 2% runup was not identifed, put a flag, and identify issue.
                err=-1; %error reading runup values
                
                %             %save maximum runup values.
                %             fid2 = fopen(outfile,'w');
                %             fprintf(fid2, '%d %f %f\n', max_runup');
                %             fclose(fid2);
                %             fclose(fid);
                %             return;
            end
            fclose(fid);
        end
    end
    
    %save maximum runup values.
    fid2 = fopen(outfile,'w');
    fprintf(fid2, '%d %f %f %f %f\n', max_runup');
    fclose(fid2);
    err=1;
end
if step_num==2
    %load max runup values
    fid2 = fopen(outfile);
    max_runup=fscanf(fid2,'%d %f %f %f %f\n',[5,length(storms)])';
    fclose(fid2);
    
    %--------------------------------------------------------------------------
    %Use generalized pareto method to determine statistical distribution of the
    %extreme return periods.
    %--------------------------------------------------------------------------
    outfile = strcat(outpth,'\',id,'_2perRunup_recurrence.txt');
    fid = fopen(outfile, 'w');
    str99999 = 'Transect   R10 R25 R50 R100    R500';
    fprintf(fid, '%s \n', str99999);
    
    RUNUP_POT = max_runup;
    time = RUNUP_POT(:,1);
    
    X=[];
    X(:,1) = time(RUNUP_POT(:,2)>0, 1);% Time vector of Max surge elevation in POT, where POT observed is greater than 0.
    X(:,2) = RUNUP_POT(RUNUP_POT(:,2)>0, 2);%Runup value of the point
    
    % if(length(X(:,1))>=0.9*length(storms)) %only analyze where have 90% of the storms returning data.
    
    %x = find(isnan(Surge_LM(:,i+5))==0); %Finding all surge indices where the surge exists for associated station.
    %Nyrs = 1+max(datevec(max(Surge_LM(x,1)))-datevec(min(Surge_LM(x,1)))); %find number of years surge exists
    str1 = X(end,1);
    
    str2 = X(1,1);
%     Nyrs = 1+ max(datevec(datenum(num2str(str1), 'yyyymmdd'))) -max(datevec(datenum(num2str(str2), 'yyyymmdd'))); %c
    
    PEAKS_RUNUP = sort(RUNUP_POT(isnan(RUNUP_POT(:,2))==0, 2),'descend'); %sorting non-NAN POT values in decending order, calling peak surge (surge only vector)
    PEAKS_RUNUP = PEAKS_RUNUP(PEAKS_RUNUP>0, 1); %Retaining non-zero peak surges.
    Surge_th = min(PEAKS_RUNUP)*0.99999; %setting surge threshold to be SLIGHTLY lower than the existing minimum value, so all results return (since POT already did pass/fail of the threshold.
    Nstm = size(PEAKS_RUNUP,1);
    
    gpPar_Surge = gpfit(PEAKS_RUNUP(:,1) - Surge_th); %using gpfit on the sorted in descending order sruge values, minus the minimum threshold value (to normalize the dataset to have one '0').
    %it is returning the maximum likelyhood estimates of the paramaters for
    %the GP distribution gpPar_Surge(1) is the tail index shape,
    %gpPar_Surge(2) is the scale paramter, sigma.
    %number of data points being analyized.
    
    
    for j = 1:Nstm %for number of surge values existing, this is calculating the
        %inverse CDF for each surge point, which can be used for return
        %period extraction.
        PEAKS_RUNUP(j,2) = j; %row index column 2 will be index
        PEAKS_RUNUP(j,3) = 1-(PEAKS_RUNUP(j,2)/(Nstm+1));   %creating CDF - row index column 3 == (1 - (index/total points+1))
        PEAKS_RUNUP(j,4) = (1/(Nstm/Nyrs))/(1-PEAKS_RUNUP(j,3)); %(1/(number of storms/number of years))/(1 - CDF value)
        PEAKS_RUNUP(j,5) = gpinv(PEAKS_RUNUP(j,3),gpPar_Surge(1,1),gpPar_Surge(1,2),Surge_th); %Calling generalized pareto inverse cumulative distribution function
        %needed because Ut = F^-1(1 -  1/lamda*T), where Ut is the largest
        %value in T years. lamda is the crossing rate, which is estimated
        %by Nu/Tdata (Tdata is the number of years where data has been
        %recorded and Nu is total number of exceedences. ) Lamda*T should
        %be the number of exceedences in T years.
        
        %gpinv returns the inverse CDF for the generalized CP distribution
        %with a tail index of gpPar_Surge(1,1), scale parameter
        %(gpPar_surge(1,2), threshold of Surge_th. It is also passing
        %PEAKS_RUNUP(j,3) which is the (1 - (1:total of points/total points+1))
        
        %
    end
    
    %     %RMS
    %     RMS = sqrt(mean((PEAKS_RUNUP(PEAKS_RUNUP(:,4)>= 25,1)-PEAKS_RUNUP(PEAKS_RUNUP(:,4)>= 25,5)).^2));
    
    Tail(1:7,1:5)=NaN;
    Tail(1:7,4) = [500;200;150;100; 50; 25; 10];
    Tail(:,3) = 1-Nyrs./(Nstm*Tail(:,4));
    for k = 1:size(Tail,1)
        Tail(k,5) = gpinv(Tail(k,3),gpPar_Surge(1,1),gpPar_Surge(1,2),Surge_th);
    end%for k
    PEAKS_RUNUP = vertcat(Tail,PEAKS_RUNUP);
    % PEAKS_RUNUP2 = sort(PEAKS_RUNUP2, 4, 'descend');
    
    %% Q-Q OPTIMIZATION %%
    [qq_th, qq_eps, eps] = qq_optim(PEAKS_RUNUP,Nyrs);
    
    RP_th1 = qq_th;
    
    Runup_rp = PEAKS_RUNUP(PEAKS_RUNUP(:,4)>RP_th1,1);
    Runup_rp(isnan(Runup_rp)==1,:)=[];
    PEAKS_RUNUP2 = sort(Runup_rp(isnan(Runup_rp(:,1))==0, 1),'descend'); %sorting non-NAN POT values in decending order, calling peak surge (surge only vector)
    
    PEAKS_RUNUP2 = PEAKS_RUNUP2(PEAKS_RUNUP2>0, 1); %Retaining non-zero peak surges.
    Surge_th = min(PEAKS_RUNUP2)*0.99999; %setting surge threshold to be SLIGHTLY lower than the existing minimum value, so all results return (since POT already did pass/fail of the threshold.
    Nstm = size(PEAKS_RUNUP2,1);
    
    gpPar_Surge = gpfit(PEAKS_RUNUP2(:,1) - Surge_th); %using gpfit on the sorted in descending order sruge values, minus the minimum threshold value (to normalize the dataset to have one '0').
    %it is returning the maximum likelyhood estimates of the paramaters for
    %the GP distribution gpPar_Surge(1) is the tail index shape,
    %gpPar_Surge(2) is the scale paramter, sigma.
    %number of data points being analyized.
    
    
    for j = 1:Nstm %for number of surge values existing, this is calculating the
        %inverse CDF for each surge point, which can be used for return
        %period extraction.
        PEAKS_RUNUP2(j,2) = j; %row index column 2 will be index
        PEAKS_RUNUP2(j,3) = 1-(PEAKS_RUNUP2(j,2)/(Nstm+1));   %creating CDF - row index column 3 == (1 - (index/total points+1))
        PEAKS_RUNUP2(j,4) = (1/(Nstm/Nyrs))/(1-PEAKS_RUNUP2(j,3)); %(1/(number of storms/number of years))/(1 - CDF value)
        PEAKS_RUNUP2(j,5) = gpinv(PEAKS_RUNUP2(j,3),gpPar_Surge(1,1),gpPar_Surge(1,2),Surge_th); %Calling generalized pareto inverse cumulative distribution function
        %needed because Ut = F^-1(1 -  1/lamda*T), where Ut is the largest
        %value in T years. lamda is the crossing rate, which is estimated
        %by Nu/Tdata (Tdata is the number of years where data has been
        %recorded and Nu is total number of exceedences. ) Lamda*T should
        %be the number of exceedences in T years.
        
        %gpinv returns the inverse CDF for the generalized CP distribution
        %with a tail index of gpPar_Surge(1,1), scale parameter
        %(gpPar_surge(1,2), threshold of Surge_th. It is also passing
        %PEAKS_RUNUP(j,3) which is the (1 - (1:total of points/total points+1))
        
        %
    end
    
    Tail(1:7,1:5)=NaN;
    Tail(1:7,4) = [500;200;150;100; 50; 25; 10];
    Tail(:,3) = 1-Nyrs./(Nstm*Tail(:,4));
    for k = 1:size(Tail,1)
        Tail(k,5) = gpinv(Tail(k,3),gpPar_Surge(1,1),gpPar_Surge(1,2),Surge_th);
    end%for k
    PEAKS_RUNUP2 = vertcat(Tail,PEAKS_RUNUP2);
    % PEAKS_RUNUP2 = sort(PEAKS_RUNUP2, 4, 'descend');
    
    %% Q-Q OPTIMIZATION END %%
    
    %print out return periods for 10, 25, 50, 100, 500.
    fprintf(fid, '%0.0f\t%0.4f\t%0.4f\t%0.4f\t%0.4f\t%0.4f\n', ...
        id_num, Tail(7,5), Tail(6,5), Tail(5,5), Tail(4,5), Tail(1,5));
    
    PEAKS_RUNUP_SORTED = sortrows(PEAKS_RUNUP2, 4);
    
    % Plot GPD distributions.
    figure('Color',[1 1 1],'visible','off');
    axes('XScale','log','XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on','FontSize',14);
    xlim([.1 1000]); ylim([floor(min(PEAKS_RUNUP_SORTED(:,1))) ceil(max(PEAKS_RUNUP_SORTED(:,1)))]);
    hold on
    semilogx(PEAKS_RUNUP_SORTED(:,4),PEAKS_RUNUP_SORTED(:,1),'MarkerSize',5,'Marker','o',...
        'LineStyle','none','MarkerFaceColor','r','MarkerEdgeColor','r');
    semilogx(PEAKS_RUNUP_SORTED(:,4),PEAKS_RUNUP_SORTED(:,5),'LineWidth',2,'Color','b');
    xlabel({'Return Period (years)'}, 'FontSize',14);
    ylabel({'2% Runup Elev (m)'},'FontSize',14);
    title(['Transect: ' id], 'FontSize', 18);
    print(gcf,strcat(outpth,'\',id,'_2perRunup_freq'),'-djpeg');
    
    % end
    
    close all;
    fclose(fid)
    err=1;
end
