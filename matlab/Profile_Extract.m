function err = profile_extract(inpth1,inpth2,outpth,id,shrline,lgth)
%function err = profile_extract(inpth1,inpth2,outpth,id,shrline,lgth)
%--------------------------------------------------------------------------
%This function pulls the eroded profile from the CSHORE output for a
%specified transect and formats for input into CHAMP.  Also produces a
%figure showing the profile change for QC purposes and pulls wave data at
%the start of the overland transect
%MFS 08-08-2014
%MFS- 12-17-2014 updated to accept the offshore transect length as a parameter
%   - This will be used for determining the shoreline location.
%--------------------------------------------------------------------------
%INPUT
%   inpth1      - input file path for CSHORE output
%   inpth2      - input file path for storm/scenario list file (stormlist.txt))
%   outpth      - output file path
%   id          - transect ID (hydroid)
%   shrline     - shoreline elevation in feet
%   lgth        - offshore transect length in feet
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
% inpth1='\\surly.mcs.local\flood\Temp\yz\ErieTest\CSHORE_Infile_Creater\output';
% inpth2='\\surly.mcs.local\flood\Temp\yz\ErieTest\Hydrograph_stretching\output';
% outpth='\\surly.mcs.local\flood\Temp\yz\ErieTest\Profile_extract\output';
% id='63';
% shrline='569.4';
% lgth='2146.826';

shrline = str2double(shrline)*0.3048;   %convert to meters
lgth = str2double(lgth)*0.3048;         %convert to meters
err=0;

%Load in storm/scenario list
storms = load(strcat(inpth2,'\stormlist.txt'));

%for each transect and scenario
for ii=1:length(storms)
    path=strcat(inpth1,'\TR',id, '\', num2str(storms(ii)));
    
    %------------------------------------------------
    %open CSHORE output profile
    fid = fopen(strcat(path,'\OBPROF'));
    if (fid == -1)  %Flag if OBPROF cannot open.... indicates error in running CSHORE, review input file
        err=-1; %error opening file/making directory
    else
        
        cnt=0;
        out=[];
        while 1
            tline = fgetl(fid);
            if ~ischar(tline), break, end
            cnt = cnt+1;
            tline = str2num(tline);
            if length(tline)==3;
                N = tline(2);
                tme = tline(3);
            elseif length(tline)==2;
                N = tline(1);
                tme=tline(2);
            end
            [tot]=fscanf(fid,'%f %f \n',[2,N])';
            out(cnt).time = tme;
            out(cnt).x = tot(:,1);
            out(cnt).zb = tot(:,2);
%             out(cnt).total_zb = (out(cnt).x(2)-out(cnt).x(1))*sum(out(cnt).zb);
%             out(cnt).total_zb_trap = (out(cnt).x(2)-out(cnt).x(1))*trapz(out(cnt).zb);
        end
        fclose(fid);
        num_output = cnt;
        
        %assuming linearity, solve for shoreline intercept, and reorder so shoreline
        %is zero zero.
        
        %         [xplus_ind] = find(out(1,1).zb > 0,1);
%         [xplus_ind] = find(out(1,1).zb > shrline,1);
        [xplus_ind] = find(out(1,1).x >= lgth,1);
        xminus_ind = xplus_ind -1;
        
        x1 = out(1,1).x(xplus_ind);
        x2 = out(1,1).x(xminus_ind);
        y1 = out(1,1).zb(xplus_ind);
        y2 = out(1,1).zb(xminus_ind);
        
%         slope = (y1 - y2)/(x1-x2);
%         p = (y1-shrline) - slope*x1;
%         %since, y0 = shrline...
%         x0 = -p/slope;
        x0 = lgth;
%         y0 = shrline;
        
        %find maximum eroded profile (not always at the end of the
        %simulation)
        minVol=1.0e+09;
        for jj=1:num_output
            %get volume landward of shoreline
            onshore_vol(jj) = (out(1,jj).x(2)-out(1,jj).x(1))*trapz(out(1,jj).zb(xplus_ind:end));
            
            if onshore_vol(jj) < minVol
               maxErod_ind=jj; 
            end
        end
%         figure;plot(onshore_vol);
            
        %reorder so shoreline is zero zero.        
        x3 = out(1,maxErod_ind).x(xplus_ind);
        x4 = out(1,maxErod_ind).x(xminus_ind);
        y3 = out(1,maxErod_ind).zb(xplus_ind);
        y4 = out(1,maxErod_ind).zb(xminus_ind);
        
        slope2 = (y3 - y4)/(x3-x4);
        p2 = y3 - slope2*x3;
        x5 = x0;  %create a new point in the final profile that is in the same place as the initial shoreline.
        y5 = x5*slope2 + p2;
        
        %new final profile
        xnew = [((out(1,1).x(1:xminus_ind) - x0)/0.3048); 0; ((out(1,1).x(xplus_ind:end)-x0))/0.3048];
        zbnew = [(out(1,maxErod_ind).zb(1:xminus_ind))/0.3048; y5/0.3048; (out(1,maxErod_ind).zb(xplus_ind:end))/0.3048];
        
        %write to output folder
        directory = strcat(outpth,'\TR', id, '\', num2str(storms(ii)));
        [errmk,msg,msgID] = mkdir(directory); 
        
        fid_temp = fopen(strcat(directory,'\eroded_profile_ft.txt'), 'w');
        if errmk==0 || fid_temp <0
            err=-1; %error opening infile/making directory
        else
            for mm = 1:length(out(1,maxErod_ind).zb)
                fprintf(fid_temp, '%s\t%f\t%f\n', id,xnew(mm), zbnew(mm));
            end
            fclose(fid_temp);                      
        end
        
        %------------------------------------------------
        %open CSHORE output to get input wave information
        fid = fopen(strcat(path,'\ODOC'));
        if (fid == -1)  %Flag if ODOC cannot open.... indicates error in running CSHORE, review input file
            err=-1; %error opening file/making directory
        else
            tot = textscan(fid,'%s','delimiter','\n');
            tot = tot{:};
            fclose(fid);
            %get wave conditions at SB
            dum =strfind(tot,'INPUT WAVE');
            row_ind = find(~cellfun('isempty',dum));
            ind_begin =  row_ind+3;
            dum =strfind(tot,'INPUT BEACH AND STRUCTURE');
            row_ind = find(~cellfun('isempty',dum));
            ind_end = row_ind-2;
            cnt = 0;
            wave_cond = [];
            for ij = ind_begin:ind_end
                cnt = cnt+1;
                %             str2num(cell2mat(tot(i,:)));
                wave_cond=[wave_cond;str2num(cell2mat(tot(ij,:)))];
            end
            Tp_offshore=wave_cond(:,2);
            swel_offshore=wave_cond(:,5);
            %------------------------------------------------
            %open CSHORE output to get output wave and setup information
            fid = fopen(strcat(path,'\OSETUP'));
            if (fid == -1)  %Flag if OSETUP cannot open.... indicates error in running CSHORE, review input file
                err=-1; %error opening file/making directory
            else
                cnt=0;
                x=[];
                setup = [];
                depth = [];
                sigma = [];
                Hrms = [];
                while 1
                    tline = fgetl(fid);
                    if ~ischar(tline), break, end
                    cnt = cnt+1;
                    tline = str2num(tline);
                    if tline(1)==1
                        N = tline(2);tme=tline(end);
                    else
                        N = tline(1);
                    end
                    [tot]=fscanf(fid,'%f %f %f %f \n',[4,N])';
                    x(:,cnt)     = [tot(:,1); NaN(length(out(1,1).x)-size(tot,1),1)];
                    setup(:,cnt) = [tot(:,2); NaN(length(out(1,1).x)-size(tot,1),1)];
                    depth(:,cnt) = [tot(:,3); NaN(length(out(1,1).x)-size(tot,1),1)];
                    sigma(:,cnt) = [tot(:,4); NaN(length(out(1,1).x)-size(tot,1),1)];
                    Hrms(:,cnt) = sqrt(8)*sigma(:,cnt);
                    
                end
                fclose(fid);
                
                % find maximum wave height at LWD
                if ~isempty(Hrms)
                    Hs_lwd = sqrt(2)*Hrms(xplus_ind,:);
                    maxHs_lwd = max(Hs_lwd);
                    maxHs_id = find(Hs_lwd==maxHs_lwd,1);
                    
                    if ~isempty(maxHs_id)
                        %find associated wave setup and period
                        Tp_maxHs_lwd = Tp_offshore(maxHs_id);
                        set_maxHs_lwd = setup(xplus_ind,maxHs_id) - swel_offshore(maxHs_id);
                        
                        % if wave setup is negative (set down), set to zero
                        if set_maxHs_lwd<0
                            set_maxHs_lwd=0;
                        end
                        
                        outpar = [maxHs_lwd/0.3048 Tp_maxHs_lwd set_maxHs_lwd/0.3048 swel_offshore(maxHs_id)/0.3048];
                        dlmwrite(strcat(directory,'\wave_HsTpSetupSwel_ft.txt'),outpar,'delimiter','\t','precision','%.6f')
                    else
                        err=-1; %error finding max wave height at LWD
                    end
                else
                    err=-1; %no wave output, error running CSHORE
                end
            end
        end
        %Plot Change in profile
        fig = figure('color', [1 1 1], 'Visible', 'off');
        hold on
%         ylim([shrline-3 shrline+3])
        plot(out(1,1).x/0.3048, out(1,1).zb/0.3048, 'k', 'linewidth', 2);
        plot(out(1,maxErod_ind).x/0.3048, out(1,maxErod_ind).zb/0.3048, 'g--', 'linewidth', 2);
        title(strcat('Bottom Position: Initial vs Max Erosion - ',num2str(id)),'fontname','times','fontsize',14,'fontangle','italic')
        ylabel('z[ft]','fontname','times','fontsize',14,'fontangle','italic')
        xlabel('x[ft]','fontname','times','fontsize',14,'fontangle','italic')
        legend('Initial Profile', strcat('Profile at timestep=',num2str(maxErod_ind),'/',num2str(num_output)));
        
        pos_y=shrline/0.3048;
        text(300,pos_y,strcat('Hs @ LWD= ',num2str(maxHs_lwd/0.3048),' ft'));
        text(300,pos_y-2,strcat('Tp= ',num2str(Tp_maxHs_lwd),' sec'));
        text(300,pos_y-4,strcat('Wave setup= ',num2str(set_maxHs_lwd/0.3048),' ft'));
        text(300,pos_y-6,strcat('SWEL= ',num2str(swel_offshore(maxHs_id)/0.3048),' ft'));
        grid on;
        print(gcf,strcat(directory,'\ProfileChange'),'-djpeg');
        close all;
    end
end

if err~=-1
    err=1;
end

