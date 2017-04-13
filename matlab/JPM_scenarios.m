function err = JPM_scenarios(inpth1,inpth2,outpth,id,node,dconv)
%function err = JPM_scenarios(inpth1,inpth2,outpth,id,node,dconv)
%--------------------------------------------------------------------------
%INPUT
%   inpth1      - input file path for maxele.mat, maxHS.mat, and maxTps.mat files
%   inpth2      - input file path for storm list file (stormlist.txt)
%   outpth      - output file path
%   id          - transect ID (hydroid)
%   node        - node associated with transect
%   dconv       - conversion factor in meters added to storm water levels
%OUTPUT
%   err         - error code (=1 if successful)
%--------------------------------------------------------------------------
%% JointProbability_LM.m
%  By: Norberto C. Nadal-Caraballo, PhD
%  May 5, 2011 (20110505)
%  Revised:  Scott Banjavcic
%  June 26, 2013
%  Revised: Lauren Klonsky, Frannie Bui 03/04/2014
% - added Lambda
%  Revised:  NCNC - April 28, 2014
% a. Deleted lambda
% b. Expanded the length of the extracted contour to include cumulative
%    probability down to mean plus one standard deviation (0.841344746)
% c. Added QQoptimization code for SWL data
% d. Added QQoptimization code for Hs data
% e. Correlation between SWL and Hs is now computed after executing
%    QQoptimization for both data sets
%
%  Revised: M Shultz 10/22/2014 to incorporate the above revisions
%% ************************************************************************
%  JOINT PROBABILITY
%  This script computes joint probability and conditional probability
%  between waves and water levels. The code can be modified to compute jp
%  between waves and surge elevation.
%
%  Recommendation: Evaluate at least five (5) different parameter
%  combinations for each Return Period (e.g., 100 years, 500 years)
%  Three (3) combinations from JP (iso-probability countours)
%  Two (2) combinations from marginal distribution and expected value, E(X),
%  of secondary parameter (from conditional distribution).
%
% Example: for RP = 100 yr (1.0% exceedance probability)
% Case (1) = maximum Hs and expected value of SWL (from joint probability)
% Case (2) = maximum SWL and expected value of Hs (from joint probability)
% Case (3) = intermediate SWL & Hs values (from joint probability)
% Case (4) = 100 yr SWL and expected value of Hs (from conditional prob)
% Case (5) = 100 yr Hs and expected value of SWL (from conditional prob)

% Example: for RP = 500 yr (0.2% exceedance probability)
% Case (1) = maximum Hs and expected value of SWL (from joint probability)
% Case (2) = maximum SWL and expected value of Hs (from joint probability)
% Case (3) = intermediate SWL & Hs values (from joint probability)
% Case (4) = 500 yr SWL and expected value of Hs (from conditional prob)
% Case (5) = 500 yr Hs and expected value of SWL (from conditional prob)
%--------------------------------------------------------------------------
% inpth1='\\surly.mcs.local\flood\05\LakeErie_General\Coastal_Methodology\Read_full_grids\output\';
% inpth2='\\surly.mcs.local\flood\05\LakeErie_General\Coastal_Methodology\Read_full_grids\input\';
% outpth='\\wolftrap\mcs\FederalPrograms\Dept62\Coastal Group\Coastal GeoFIRM\CShore\MATLAB\JPM_test_output\';
% clear all; close all;
% inpth1='\\surly.mcs.local\flood\02\NY\Erie_Co_36029C\STUDY__TO90\TECHNICAL\ENG_FLOOD_HAZ_DEV\COASTAL\WAVE_MODELING\CSHORE\Storm_archive_Max\';
% inpth2='\\surly.mcs.local\flood\02\NY\Erie_Co_36029C\STUDY__TO90\TECHNICAL\ENG_FLOOD_HAZ_DEV\COASTAL\WAVE_MODELING\CSHORE\Hydrographs\output\test\';
% outpth='\\surly.mcs.local\flood\02\NY\Erie_Co_36029C\STUDY__TO90\TECHNICAL\ENG_FLOOD_HAZ_DEV\COASTAL\WAVE_MODELING\CSHORE\JPM_scenarios\output\test\';
% 
% id='56';
% node='41585';
% dconv='174';

err=0;
dconv = str2double(dconv);   
load(strcat(inpth1,'maxHS'));
load(strcat(inpth1,'maxele'));
load(strcat(inpth1,'maxTps'));

time = load(strcat(inpth2,'stormlist.txt'));
Nyrs = time(1); %# of years now inlcuded as first line in stormlist.txt - updated 3/9/15 -MFS
time = time(2:end);

nodes = 1:length(HS_POT);
% nodes_for_JPM = load(strcat(inpth3,'transect_nodes_jpm.txt'));

% %need to sort by nodes acsending for the lookup by node
% nodes_for_JPM = sortrows(nodes_for_JPM,2);

%obtain needed data for each node
ids = ismember(nodes,str2num(node)); %#ok<ST2NM>
Surge_POT = Surge_POT(ids,:)';
HS_POT = HS_POT(ids,:)';
Tps_POT = Tps_POT(ids,:)';

%set any "no data" values to NAN and convert to FEET NAVD88
ids = Tps_POT<0;
Tps_POT(ids)=nan;
Surge_POT(ids) = nan;
HS_POT(ids) = nan;

ids = HS_POT<0;
Tps_POT(ids)=nan;
Surge_POT(ids) = nan;
HS_POT(ids) = nan;

Surge_POT = (Surge_POT+dconv)/0.3048;
HS_POT = HS_POT/0.3048;

%****** SWL ************************************************************
%Extract storn peak water level values from CSS file

for ii = 1:1    %modified loop to only handle on node (being passed as argument)
    X = time(Surge_POT(:,ii)>0,1); %This is done at each node, during the loop
    str1 = X(end,1);
    str2 = X(1,1);
%     Nyrs = 1+ max(datevec(datenum(num2str(str1), 'yyyymmdd'))) -max(datevec(datenum(num2str(str2), 'yyyymmdd'))); %c
    
    PEAKS_SWL = Surge_POT(Surge_POT(:,ii)>0,ii);
    
    %% SWL Q-Q OPTIMIZATION
    PEAKS_SWL = sort(PEAKS_SWL,'descend');
    %     PEAKS_SWL = PEAKS_SWL(PEAKS_SWL>0,1);
    SWL_th = min(PEAKS_SWL)*0.999999;
    Nstm = size(PEAKS_SWL,1);
    
    for j = 1:Nstm
        PEAKS_SWL(j,2) = j;
        PEAKS_SWL(j,3) = 1-(PEAKS_SWL(j,2)/(Nstm+1));
        PEAKS_SWL(j,4) = (1/(Nstm/Nyrs))/(1-PEAKS_SWL(j,3));
    end%for
    SWL = PEAKS_SWL(:,1);
    emp = PEAKS_SWL(:,3);
    SWL_th = min(SWL)*0.999999;
    
    gpPar_SWL = gpfit(SWL - SWL_th);
    par1 = gpPar_SWL(1,1); par2 = gpPar_SWL(1,2); par3 = SWL_th;
    
    for j = 1:Nstm
        PEAKS_SWL(j,5) = gpinv(PEAKS_SWL(j,3),gpPar_SWL(1,1),gpPar_SWL(1,2),SWL_th);
    end%for
    
    Tail(1:6,1:5)=NaN;
    Tail(1:6,4) = [1000;750;500;250;150;100];
    Tail(:,3) = 1-Nyrs./(Nstm*Tail(:,4));
    for kk = 1:size(Tail,1)
        Tail(kk,5) = gpinv(Tail(kk,3),gpPar_SWL(1,1),gpPar_SWL(1,2),SWL_th);
    end%for kk
    PEAKS_SWL = vertcat(Tail,PEAKS_SWL);
    
    %%
    [qq_th, qq_eps, eps] = qq_optim(PEAKS_SWL,Nyrs);
    
    RP_th1 = qq_th;
    
    SWL_rp = PEAKS_SWL(PEAKS_SWL(:,4)>RP_th1,1);
    SWL_rp(isnan(SWL_rp)==1,:)=[];
    
    PEAKS_SWL = sort(SWL_rp(isnan(SWL_rp(:,1))==0,1),'descend');
    PEAKS_SWL = PEAKS_SWL(PEAKS_SWL>0,1);
    SWL_th = min(PEAKS_SWL)*0.999999;
    gpPar_SWL = gpfit(PEAKS_SWL(:,1) - SWL_th);
    Nstm = size(PEAKS_SWL,1);
    
    %GPD parameters
    a1 = SWL_th; b1 = gpPar_SWL(1,2); c1 = gpPar_SWL(1,1);
    Surge_POT(Surge_POT(:,ii)<a1,ii)=NaN;
    
    for j = 1:Nstm
        PEAKS_SWL(j,2) = j;
        PEAKS_SWL(j,3) = 1-(PEAKS_SWL(j,2)/(Nstm+1));
        PEAKS_SWL(j,4) = (1/(Nstm/Nyrs))/(1-PEAKS_SWL(j,3));
        PEAKS_SWL(j,5) = gpinv(PEAKS_SWL(j,3),gpPar_SWL(1,1),gpPar_SWL(1,2),SWL_th);
    end%for
    
    Tail(1:6,1:5)=NaN;
    Tail(1:6,4) = [1000;750;500;250;150;100];
    Tail(:,3) = 1-Nyrs./(Nstm*Tail(:,4));
    for kk = 1:size(Tail,1)
        Tail(kk,5) = gpinv(Tail(kk,3),gpPar_SWL(1,1),gpPar_SWL(1,2),SWL_th);
    end%for kk
    PEAKS_SWL = vertcat(Tail,PEAKS_SWL);
    
    %% SWL GPD Plot
    clear plotY; clear plotX;
    plotY = PEAKS_SWL(7:end,1);
    for kk = 7:size(PEAKS_SWL,1)
        plotX(kk-6,1) = gpcdf(PEAKS_SWL(kk,1),gpPar_SWL(1,1),gpPar_SWL(1,2),SWL_th);
        plotX(kk-6,2) = (1/(Nstm/Nyrs))/(1-plotX(kk-6,1));
    end%for kk
    
    % Figure 2
    Figure2 = figure('Color',[1 1 1],'visible','off');
    axes('XScale','log','XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on','FontSize',16);
    %xlim([1 1000]); ylim([3 6]);
    hold on
    
    semilogx(PEAKS_SWL(:,4),PEAKS_SWL(:,1),'MarkerSize',5,'Marker','o',...
        'LineStyle','none','Color','k');
    
    semilogx(PEAKS_SWL(:,4),PEAKS_SWL(:,5),'LineWidth',2,'Color','b');
    semilogx(plotX(:,2),plotY(:,1),'MarkerSize',5,'Marker','o',...
        'LineStyle','none','MarkerFaceColor','r','MarkerEdgeColor','r');
    
    xlabel({'Average Recurrence Interval (years)'},'FontSize',16);
    ylabel({'SWL (ft)'},'FontSize',16);
    h_legend=legend('Empirical Data','GPD Fit','Maximum Likelihood','Location','SouthEast');
    set(h_legend,'FontSize',14);
    hold off
    %save figure
    SV1 = 'SWL_';
    SV2 = 'QQoptim';
%     SV3 = char(num2str(nodes_for_JPM(ii,1)));
    figura2 = strcat(outpth,id,'_',SV1,SV2);
    saveas(Figure2,figura2,'png')
    % Figure 2
    
    %****** Hs ************************************************************
    %Extract storn peak wave height values from CSS file
    PEAKS_Hs = HS_POT(HS_POT(:,ii)>0,ii);
    
    %     %Compute Hs threshold for GPD
    %     Hs_th = min(PEAKS_Hs(:,1))*0.99999;
    %
    %     %Fit GPD to Hs data
    %     gpPar_Hs = gpfit(PEAKS_Hs(:,1) - Hs_th);
    %
    %     %GPD parameters
    %     a2 = Hs_th; b2 = gpPar_Hs(1,2); c2 = gpPar_Hs(1,1);
    %% Hs Q-Q OPTIMIZATION
    
    PEAKS_Hs = sort(PEAKS_Hs,'descend');
    PEAKS_Hs = PEAKS_Hs(PEAKS_Hs>0,1);
    SWL_th = min(PEAKS_Hs)*0.999999;
    Nstm = size(PEAKS_Hs,1);
    
    for j = 1:Nstm
        PEAKS_Hs(j,2) = j;
        PEAKS_Hs(j,3) = 1-(PEAKS_Hs(j,2)/(Nstm+1));
        PEAKS_Hs(j,4) = (1/(Nstm/Nyrs))/(1-PEAKS_Hs(j,3));
    end%for
    Hs = PEAKS_Hs(:,1);
    emp = PEAKS_Hs(:,3);
    Hs_th = min(Hs)*0.999999;
    
    gpPar_Hs = gpfit(Hs - Hs_th);
    par1 = gpPar_Hs(1,1); par2 = gpPar_Hs(1,2); par3 = Hs_th;
    
    for j = 1:Nstm
        PEAKS_Hs(j,5) = gpinv(PEAKS_Hs(j,3),gpPar_Hs(1,1),gpPar_Hs(1,2),Hs_th);
    end%for
    
    Tail(1:6,1:5)=NaN;
    Tail(1:6,4) = [1000;750;500;250;150;100];
    Tail(:,3) = 1-Nyrs./(Nstm*Tail(:,4));
    for kk = 1:size(Tail,1)
        Tail(kk,5) = gpinv(Tail(kk,3),gpPar_Hs(1,1),gpPar_Hs(1,2),Hs_th);
    end%for kk
    PEAKS_Hs = vertcat(Tail,PEAKS_Hs);
    
    %%
    [qq_th, qq_eps, eps] = qq_optim(PEAKS_Hs,Nyrs);
    
    RP_th1 = qq_th;
    
    Hs_rp = PEAKS_Hs(PEAKS_Hs(:,4)>RP_th1,1);
    Hs_rp(isnan(Hs_rp)==1,:)=[];
    
    PEAKS_Hs = sort(Hs_rp(isnan(Hs_rp(:,1))==0,1),'descend');
    PEAKS_Hs = PEAKS_Hs(PEAKS_Hs>0,1);
    Hs_th = min(PEAKS_Hs)*0.999999;
    gpPar_Hs = gpfit(PEAKS_Hs(:,1) - Hs_th);
    Nstm = size(PEAKS_Hs,1);
    
    %GPD parameters
    a2 = Hs_th; b2 = gpPar_Hs(1,2); c2 = gpPar_Hs(1,1);
    HS_POT(HS_POT(:,ii)<a2,ii)=NaN;
    
    for j = 1:Nstm
        PEAKS_Hs(j,2) = j;
        PEAKS_Hs(j,3) = 1-(PEAKS_Hs(j,2)/(Nstm+1));
        PEAKS_Hs(j,4) = (1/(Nstm/Nyrs))/(1-PEAKS_Hs(j,3));
        PEAKS_Hs(j,5) = gpinv(PEAKS_Hs(j,3),gpPar_Hs(1,1),gpPar_Hs(1,2),Hs_th);
    end%for
    
    Tail(1:6,1:5)=NaN;
    Tail(1:6,4) = [1000;750;500;250;150;100];
    Tail(:,3) = 1-Nyrs./(Nstm*Tail(:,4));
    for kk = 1:size(Tail,1)
        Tail(kk,5) = gpinv(Tail(kk,3),gpPar_Hs(1,1),gpPar_Hs(1,2),Hs_th);
    end%for kk
    PEAKS_Hs = vertcat(Tail,PEAKS_Hs);
    
    %% Hs GPD Plot
    
    clear plotY; clear plotX;
    plotY = PEAKS_Hs(7:end,1);
    for kk = 7:size(PEAKS_Hs,1)
        plotX(kk-6,1) = gpcdf(PEAKS_Hs(kk,1),gpPar_Hs(1,1),gpPar_Hs(1,2),Hs_th);
        plotX(kk-6,2) = (1/(Nstm/Nyrs))/(1-plotX(kk-6,1));
    end%for kk
    
    % Figure 3
    Figure3 = figure('Color',[1 1 1],'visible','off');
    axes('XScale','log','XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on','FontSize',16);
    %xlim([1 1000]); ylim([3 6]);
    hold on
    
    semilogx(PEAKS_Hs(:,4),PEAKS_Hs(:,1),'MarkerSize',5,'Marker','o',...
        'LineStyle','none','Color','k');
    
    semilogx(PEAKS_Hs(:,4),PEAKS_Hs(:,5),'LineWidth',2,'Color','b');
    semilogx(plotX(:,2),plotY(:,1),'MarkerSize',5,'Marker','o',...
        'LineStyle','none','MarkerFaceColor','r','MarkerEdgeColor','r');
    
    xlabel({'Average Recurrence Interval (years)'},'FontSize',16);
    ylabel({'Hs (ft)'},'FontSize',16);
    h_legend=legend('Empirical Data','GPD Fit','Maximum Likelihood','Location','SouthEast');
    set(h_legend,'FontSize',14);
    hold off
    %save figure
    SV1 = 'Hs_';
    SV2 = 'QQoptim';
%     SV3 = char(num2str(nodes_for_JPM(ii,1)));
    figura3 = strcat(outpth,id,'_',SV1,SV2);
    saveas(Figure3,figura3,'png')
    
    %****** Tp ************************************************************
    PEAKS_Tp = Tps_POT(Tps_POT(:,ii)>0,ii);
    
    %Compute Tp threshold for GPD
    Tp_th = min(PEAKS_Tp(:,1))*0.99999;
    
    %Fit GPD to Tp data
    gpPar_Tp = gpfit(PEAKS_Tp(:,1) - Tp_th);
    
    %GPD parameters
    a3 = Tp_th; b3 = gpPar_Tp(1,2); c3 = gpPar_Tp(1,1);
    
    %**********************************************************************
    % Compute normal probabilities based on BIVARIATE Standard Normal Distribution
    
    %Correlation coefficients
    corr1 = corr(Surge_POT(:,ii),HS_POT(:,ii),'row','pairwise');
    corr2 = corr(HS_POT(:,ii),Tps_POT(:,ii),'row','pairwise');
    
    %SND (mean = 0)
    means_SWL_Hs = [0 0];
    
    %Compute covariance matrix for Bivariate Normal Distribution
    cov_SWL_Hs = [1 corr1; corr1 1];
    
    %% Creates Bivariate Normal PDF, 3D surface
    
    %Y-axis normal probability
    Ya1 = linspace(norminv(0.841344746,0,1),norminv(0.999999999,0,1),50);
    %X-axis normal probability
    Xa1 = linspace(norminv(0.841344746,0,1),norminv(0.999999999,0,1),50);
    
    %Create grid surface
    [Xb1,Yb1] =  meshgrid(Xa1',Ya1') ;
    XY1 = [Xb1(:) Yb1(:)];
    PDF1 = reshape(mvnpdf(XY1, means_SWL_Hs, cov_SWL_Hs),50,50);
    
    %Y-axis of 3D surface using the general pareto inverse transform
    Yplot1 = gpinv(normcdf(Yb1,0,1),c1,b1,a1);
    
    %X-axis of 3D surface using the general pareto inverse transform
    Xplot1 = gpinv(normcdf(Xb1,0,1),c2,b2,a2);
    
    % Plot contours of probability from joint distribution
    Figure1 = figure('Color',[1 1 1],'visible','off');
    axes('XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on','FontSize',14);
    %xlim([10 30]); ylim([578 586]);
    hold on
    [C2,h2] = contour(Xplot1,Yplot1,PDF1,[0.002],'LineWidth',2,'LineColor','r');
    hold on
    [C1,h1] = contour(Xplot1,Yplot1,PDF1,[0.010],'LineWidth',2,'LineColor','b');
    maxY1 = max(C2(2,2:end));
    minY1 = min(C2(2,2:end));
    maxX1 = max(C2(1,2:end));
    minX1 = min(C2(1,2:end));
    axis([0.99*minX1 1.01*maxX1 0.9999*minY1 1.0001*maxY1 ]);
    title({['Lake Erie Transect Number: ', id]});
    xlabel({'Wave Height (feet)'},'FontSize',14);
    ylabel({'Water Level (feet, NAVD88)'},'FontSize',14);
    legend('0.2% Exceedance Prob.','1% Exceedance Prob.','Location','SouthWest');
    hold off
    %save figure
    SV1 = 'JointProb';
%     SV2 = char(num2str(nodes_for_JPM(ii,1)));
    figura1 = [outpth,id,'_',SV1];
    saveas(Figure1,figura1,'png')
    
    contsize=size(C1);
    mid=round((contsize(1,2)-1)/2);
    
%     %% Plot All Parameter Combinations from Iso-Probability Contours to
%     %  Identify: Case (1) Max SWL and corresponding Hs
%     %            Case (2) Max Hs and corresponding SWL
%     %            Case (3) Intermediate SWL & Hs values (intersection of both curves)
%     
%     Ya1 = linspace(norminv(1-0.999999,0,1),norminv(0.999999,0,1),50);
%     Xa1 = linspace(norminv(1-0.999999,0,1),norminv(0.999999,0,1),50);
% %     Ya1 = linspace(norminv(0.841344746,0,1),norminv(0.999999999,0,1),50);
% %     Xa1 = linspace(norminv(0.841344746,0,1),norminv(0.999999999,0,1),50);
%     
%     % Creates a PDF, 3D surface
%     [Xb1,Yb1] =  meshgrid(Xa1',Ya1') ;
%     XY1 = [Xb1(:) Yb1(:)];
%     PDF1 = reshape(mvnpdf(XY1, means_SWL_Hs, cov_SWL_Hs),50,50);
%     
%     % compute axis of 3D surface
%     % then go back to marginal values for the axis using the general pareto inverse transform
%     Yplot1 = gpinv(normcdf(Yb1,0,1),c1,b1,a1);
%     
%     %do same for Y axis
%     Xplot1 = gpinv(normcdf(Xb1,0,1),c2,b2,a2);
%     
%     %RP = 100 years (1%)
%     
%     [C1,h1] = contour(Xplot1,Yplot1,PDF1,[0.010],'LineWidth',2,'LineColor','b');
%     ix100 = find(C1(1,:)==0.01);
%     C_100 = C1(1:2,ix100+1:end)';
%     
%     C_100(1:end-1,3) = diff(C_100(:,2));
%     C_100(C_100(:,3)>0,:)=[];
%     C_100(:,3)=[];
%     C_100(end,:)=[];
%     
%     Figure2 = figure('Color',[1 1 1],'visible','off');
%     axes('XGrid','off','XMinorTick','off','YGrid','on','YMinorTick','on','FontSize',14);
%     %xlim([10 30]); ylim([578 586]);
%     
%     hold on
%     [AX,Ha1,Ha2] = plotyy(1:size(C_100,1),C_100(:,2),1:size(C_100,1),C_100(:,1));
%     set(Ha1,'color','b','LineWidth',2);
%     set(Ha2,'color',[0 0.5 0],'LineWidth',2);
%     set(AX, 'xTickLabel','','YColor','k','XColor','k','XTick',[]) % delete the x-tick labels
%     %set(AX(1), 'ylim',[574 586],'ytick',[574 576 578 580 582 584 586],'FontSize',14)
%     %set(AX(2), 'ylim',[0 30],'ytick',[0 5 10 15 20 25 30],'FontSize',14)
%     
%     title({['Lake Erie Transect Number : ', id]});
%     set(get(AX(1),'Ylabel'),'String','Water Level (feet, NAVD88)','color','b','FontSize',14)
%     set(get(AX(2),'Ylabel'),'String','Wave Height (feet)','color',[0 0.5 0],'FontSize',14)
%     
%     xlabel({'1% Exceedance Probability'},'FontSize',14);
%     %ylabel({'Water Level (feet, IGLD-85)'},'FontSize',14);
%     %legend('0.2% Exceedance Prob.','1% Exceedance Prob.','Location','SoutHsest');
%     hold off
%     %save figure
%     SV1 = 'JointProb_';
% %     SV2 = char(num2str(nodes_for_JPM(ii,1)));
%     SV3 = '100yr';
%     figura2 = [outpth,id,'_',SV1,SV3];
%     saveas(Figure2,figura2,'png')
%     
%     %RP = 500 years (0.2%)
%     
%     [C2,h2] = contour(Xplot1,Yplot1,PDF1,[0.002],'LineWidth',2,'LineColor','r');
%     ix500 = find(C2(1,:)==0.002);
%     C_500 = C2(1:2,ix500+1:end)';
%     
%     C_500(1:end-1,3) = diff(C_500(:,2));
%     C_500(C_500(:,3)>0,:)=[];
%     C_500(:,3)=[];
%     C_500(end,:)=[];
%     
%     Figure3 = figure('Color',[1 1 1],'visible','off');
%     axes('XGrid','off','XMinorTick','off','YGrid','on','YMinorTick','on','FontSize',14);
%     %xlim([10 30]); ylim([578 586]);
%     
%     hold on
%     [BX,Hb1,Hb2] = plotyy(1:size(C_500,1),C_500(:,2),1:size(C_500,1),C_500(:,1));
%     set(Hb1,'color','b','LineWidth',2);
%     set(Hb2,'color',[0 0.5 0],'LineWidth',2);
%     set(BX, 'xTickLabel','','YColor','k','XColor','k','XTick',[]) % delete the x-tick labels
%     % set(BX(1), 'ylim',[574 586],'ytick',[574 576 578 580 582 584 586],'FontSize',14)
%     %set(BX(2), 'ylim',[0 30],'ytick',[0 5 10 15 20 25 30],'FontSize',14)
%     
%     title({['Lake Erie Transect Number: ', id]});
%     set(get(BX(1),'Ylabel'),'String','Water Level (feet, NAVD88)','color','b','FontSize',14)
%     set(get(BX(2),'Ylabel'),'String','Wave Height (feet)','color',[0 0.5 0],'FontSize',14)
%     
%     xlabel({'0.2% Exceedance Probability'},'FontSize',14);
%     ylabel({'Water Level (feet, NAVD88)'},'FontSize',14);
%     %legend('0.2% Exceedance Prob.','1% Exceedance Prob.','Location','SoutHsest');
%     hold off
%     %save figure
%     SV1 = 'JointProb_';
% %     SV2 = char(num2str(nodes_for_JPM(ii,1)));
%     SV3 = '500yr';
%     figura3 = [outpth,id,'_',SV1,SV3];
%     saveas(Figure3,figura3,'png')
    
    %% ********************************************************************
    %  CONDITIONAL PROBABILITY
    %  ********************************************************************
    
    % Case (4): Water Level & associated Wave Height
    
    %100-year SWL (marginal distribution)
    SWL_100 = gpinv(1-0.01,c1,b1,a1);
    Zo1 = norminv(1-0.01,0,1);
    mu1 = corr1*Zo1;
    sg1 = sqrt(1-(corr1^2));
    %Expected Hs associated to 100-year SWL (conditional distribution)
    cond_Hs_100 = mean(gpinv(normcdf(norminv(0.5,mu1,sg1),0,1),c2,b2,a2));
    
    %500-year SWL (marginal distribution)
    SWL_500 = gpinv(1-0.002,c1,b1,a1);
    Zo2 = norminv(1-0.002,0,1);
    mu2 = corr1*Zo2;
    sg2 = sqrt(1-(corr1^2));
    %Expected Hs associated to 500-year SWL (conditional distribution)
    cond_Hs_500 = mean(gpinv(normcdf(norminv(0.5,mu2,sg2),0,1),c2,b2,a2));
    
    % Case (5): Wave Height & associated Water Level
    
    %100-year Hs (marginal distribution)
    Hs_100 = gpinv(1-0.01,c2,b2,a2);
    Zo1 = norminv(1-0.01,0,1);
    mu1 = corr1*Zo1;
    sg1 = sqrt(1-(corr1^2));
    %Expected SWL associated to 100-year Hs (conditional distribution)
    cond_SWL_100 = mean(gpinv(normcdf(norminv(0.5,mu1,sg1),0,1),c1,b1,a1));
    
    %500-year Hs (marginal distribution)
    Hs_500 = gpinv(1-0.002,c2,b2,a2);
    Zo2 = norminv(1-0.002,0,1);
    mu2 = corr1*Zo2;
    sg2 = sqrt(1-(corr1^2));
    %Expected SWL associated to 500-year Hs (conditional distribution)
    cond_SWL_500 = mean(gpinv(normcdf(norminv(0.5,mu2,sg2),0,1),c1,b1,a1));
    
    % Wave Period
    
    %Hs_100 = gpinv(1-0.01,c2,b2,a2);
    Zo3 = norminv(1-0.01,0,1);
    mu3 = corr2*Zo3;
    sg3 = sqrt(1-(corr2^2));
    %Expected Tp associated to 100-year Hs (conditional distribution)
    cond_Tp_100 = mean(gpinv(normcdf(norminv(0.5,mu3,sg3),0,1),c3,b3,a3));
    
    %Hs_500 = gpinv(1-0.002,c2,b2,a2);
    Zo4 = norminv(1-0.002,0,1);
    mu4 = corr2*Zo4;
    sg4 = sqrt(1-(corr2^2));
    %Expected Tp associated to 500-year Hs (conditional distribution)
    cond_Tp_500 = mean(gpinv(normcdf(norminv(0.5,mu4,sg4),0,1),c3,b3,a3));
    
%     eval(['scenario4_', num2str(nodes_for_JPM(ii,1)), ' = [SWL_100 cond_Hs_100 cond_Tp_100]']);
%     eval(['scenario5_', num2str(nodes_for_JPM(ii,1)), '= [cond_SWL_100 Hs_100 cond_Tp_100]']);
    
    %% ********************************************************************
    % Start Compiling Results
    % Calculate Cumulative Water Level
    Joint_100 = C1';
    Joint_100size = size(Joint_100);
    Joint_100(:,3) = Joint_100(:,1) + Joint_100(:,2);
    
    % Save Cases 1 - 3 for 100 yr storm
    for j = 2:Joint_100size(1,1)
        if Joint_100(j,1)== max(Joint_100(:,1))    %row 1: max wave height, corr. surge
            JPM_Results(1,1) = 1;
            JPM_Results(1,3) = Joint_100(j,1); %wave
            JPM_Results(1,2) = Joint_100(j,2);   %surge
            JPM_Results(1,4) = 1-gpcdf(Joint_100(j,2),c1,b1,a1);   %Q of surge
            JPM_Results(1,5) = 1-gpcdf(Joint_100(j,1),c2,b2,a2);   %Q of wave
        end
        if Joint_100(j,2)== max(Joint_100(:,2))    %row 2: max surge, corr. wave height
            JPM_Results(2,1) = 2;
            JPM_Results(2,3) = Joint_100(j,1); %wave
            JPM_Results(2,2) = Joint_100(j,2);   %surge
            JPM_Results(2,4) = 1-gpcdf(Joint_100(j,2),c1,b1,a1);   %Q of surge
            JPM_Results(2,5) = 1-gpcdf(Joint_100(j,1),c2,b2,a2);   %Q of wave
        end
    end
    JPM_Results(3,1) = 3;
    JPM_Results(3,3) = Joint_100(mid,1); %wave
    JPM_Results(3,2) = Joint_100(mid,2);   %surge
    JPM_Results(3,4) = 1-gpcdf(Joint_100(mid,2),c1,b1,a1);   %Q of surge
    JPM_Results(3,5) = 1-gpcdf(Joint_100(mid,1),c2,b2,a2);   %Q of wave
    
    % Save JPM_Results Case 4 and 5
    JPM_Results(4,1) = 4;
    JPM_Results(4,2) = SWL_100;
    JPM_Results(4,3) = cond_Hs_100;
    JPM_Results(4,4) = 1-gpcdf(SWL_100,c1,b1,a1);   %Q of surge
    JPM_Results(4,5) = 1-gpcdf(cond_Hs_100,c2,b2,a2);   %Q of wave
    %JPM_Results(4,4)
    JPM_Results(5,1) = 5;
    JPM_Results(5,3) = Hs_100;
    JPM_Results(5,2) = cond_SWL_100;
    JPM_Results(5,6) = cond_Tp_100;
    JPM_Results(5,4) = 1-gpcdf(cond_SWL_100,c1,b1,a1);   %Q of surge
    JPM_Results(5,5) = 1-gpcdf(Hs_100,c2,b2,a2);   %Q of wave
    
    %  Calculate Conditional Probability for Wave Period
    %  and Save Results Cases 1-3
    for j = 1:4
        P(j,1) = gpcdf(JPM_Results(j,3),c2,b2,a2);
        Zo5(j,1) = norminv(P(j,1),0,1);
        mu5(j,1) = corr2*Zo5(j,1);
        sg5(j,1) = sqrt(1-(corr2^2));
        %Expected Tp associated to Hs (conditional distribution)
        cond_Tp(j,1) = mean(gpinv(normcdf(norminv(0.5,mu5(j,1),sg5(j,1)),0,1),c3,b3,a3));
        JPM_Results(j,6) = cond_Tp(j,1);
    end
    
    %--------Compile Theoretical Storm Events------------------
    % Label
    LabelCol = {'Case','WaterLevelft','Waveft','QSurge','QWave','CorrTP'};
    LabelRow  = {' ';'MaxWave';'MaxWaterLevel';'Combined';'CondWave';'CondSurge'};
%     JPMR_Cell = num2cell(JPM_Results);
%     JPM_ResultSave = vertcat(LabelCol,JPMR_Cell);
%     JPM_ResultSave = horzcat(LabelRow,JPM_ResultSave);
    
    SV1 = 'JPM_scenarios_';
%     SV2 = char(num2str(nodes_for_JPM(ii,1)));
    file1 = strcat(outpth,SV1,id,'.txt');
    fid = fopen(file1,'w');
    fprintf(fid, 'Case\tWaterLevelft\tWaveft\tQSurge\tQWave\tCorrTP \n');
    fprintf(fid,'%d\t%f\t%f\t%f\t%f\t%f\n', JPM_Results');
    fclose(fid);
end

err=1;

%-------------PLOT THEORETICAL STORM RESULTS---------------------
% %hold off
% %save figure
% axis([min(JPM_Results(:,3))*0.9999 max(JPM_Results(:,3))*1.001 min(JPM_Results(:,2))*0.9999 max(JPM_Results(:,2))*1.001]);
% plot(JPM_Results(:,3),(JPM_Results(:,2)),'ro');
%
% title({['Lake Erie Transect Number: ', id]});
% xlabel({'Wave Height (feet)'},'FontSize',10);
% ylabel({'Water Level (feet, NAVD88)'},'FontSize',10);
% % legstr2={['JPM WSE node:',num2str(ADCIRC_node(i,1)),' & Wave node:',num2str(wavenode(i,1))]};
% legstr3={'Theoretical Storm Events'};
% legend([legstr2,legstr3,'Location','NorthEast']);

% mkdir(['Transect_',num2str(i)]);
% cd1 = strcat(['../Info/Transect_',num2str(i)]);
% cd(cd1);
% figura2 = [county,'_Transect_',num2str(i),'_JPM_84'];
% saveas(Figure2,figura2,'tif')

% set(0,'DefaultAxesFontSize',10)
% Figure3 = figure('Color',[1 1 1],'visible','on');
% plot(HMOmax_clean(:,1),WSEmax_clean(:,1),'k+');
% hold on
% plot(JPM_Results(:,3),JPM_Results(:,2),'ro');
% hold on
% [C1,h1] = contour(Xplot1,Yplot1,PDF1,[0.01],'LineWidth',2,'LineColor','b'); %added Lambda
% hold on
% title({['Lake Michigan Input Max Storm Data: ',county,' Transect ',num2str(i),]},'FontSize',10);
% xlabel({'Wave Height (feet)'},'FontSize',10);
% ylabel({'Water Level (feet) IGLD85'},'FontSize',10);
% legend([legstr1,legstr3,legstr2]);
% legend('Location','Best');
% hold off
% cd1 = strcat(['../../Info']);
% oldFolder = cd(cd1);
% mkdir(['Transect_',num2str(i)]);
% cd1 = strcat(['../Info/Transect_',num2str(i)]);
% cd(cd1);
% figura3 = [county,'_Transect_',num2str(i),'_JPM_AllData_84'];
% saveas(Figure3,figura3,'tif')
%
% close all;
% cd2 = strcat(['../']);
% cd(cd2);

% close all
% clearvars -except cd2 data transects ADCIRC_node STWAVE_node WAM_node Transect county

%%

% fid = fopen('Scenarios4and5.txt', 'w');
% for ii = 1:length(nodes_for_JPM)
%     SV1 = 'Transect ';
%     SV2 = char(num2str(nodes_for_JPM(ii,1)));
%     SV3 = '  Scenario4 ';
%     var1 = [SV1,SV2, SV3];
%     sv1 = 'Transect ';
%     sv2 = char(num2str(nodes_for_JPM(ii,1)));
%     sv3 = '  Scenario5 ';
%     var2 = [sv1, sv2, sv3];
%     fprintf(fid, '%s \n', var1);
%     fprintf(fid, 'Water Level Wave Height Wave Period \n');
%     fprintf(fid,'%f %f %f \n\n', eval(['scenario4_', num2str(nodes_for_JPM(ii))]));
%     fprintf(fid, '%s \n', var2);
%     fprintf(fid, 'Water Level Wave Height Wave Period \n');
%     fprintf(fid,'%f %f %f \n \n \n', eval(['scenario5_', num2str(nodes_for_JPM(ii))]));
% end
% fclose all
