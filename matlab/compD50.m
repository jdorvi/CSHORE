function d = compD50(inpth,outpth,id)
%function d = compD50(inpth,outpth,id)
%--------------------------------------------------------------------------
%smooths the profile for specified transect (using 10-m window), and using 
%equilibrum profile theory, computes the profile scale parameter A, the 
%sediment fall velocity w, and the mean sediment grain size d50 (in mm)
%finds the best A value (by minimzing RMS error) of equilibrium profile 
%z=A*x^(2/3) and plots result (.png) to specified output folder
%w      no longer computed using A=0.067*w^0.44 from (Dean, 1991)
%d50    no longer computed using w=14*d50^1.1 from (Hallermeir, 1981)
%d50    computed using relation from FEMA Great Lakes Guidelines (Jan.2014)
%       equation (6) from Section D.3.7
%--------------------------------------------------------------------------
%INPUT
%   inpth       - input file path (units used in input file: meters)
%   outpth      - output file path
%   id          - transect ID (hydroid)
%OUTPUT
%   d           - mean sediment diameter (mm)
%--------------------------------------------------------------------------

% inpth='\\surly.mcs.local\flood\05\LakeErie_General\Coastal_Methodology\Interp_Profs\input';
% outpth='\\surly.mcs.local\flood\05\LakeErie_General\Coastal_Methodology\Interp_Profs\output';
% inpth='\\surly.mcs.local\flood\02\NY\Erie_Co_36029C\STUDY__TO90\TECHNICAL\ENG_FLOOD_HAZ_DEV\COASTAL\WAVE_MODELING\CSHORE\Interp_Profs\input';
% outpth='\\surly.mcs.local\flood\02\NY\Erie_Co_36029C\STUDY__TO90\TECHNICAL\ENG_FLOOD_HAZ_DEV\COASTAL\WAVE_MODELING\CSHORE\Interp_Profs\output';
% id='12';

d=0;
prof = load(strcat(inpth,'/prof_',id));

x=prof(:,1);
z=prof(:,2);

%%%%
xint=0:0.25:max(x);
zint=interp1(x,z,xint);

%MFS 04-16-14 - replaced with filter function below
% n=5;% n is the parameter chosen for filtering
% xx=zint;
% l=length(xx);
% window(1:n/2-1/2)=xx(1:n/2-1/2);
% window(l:-1:l-(n/2-1/2)+1)=xx(l:-1:l-(n/2-1/2)+1);
% 
% for ii=n/2+1/2:l-(n/2-1/2)
%     window(ii)=sum(xx(ii-(n/2-1/2):ii+(n/2-1/2)))/n;
% end
% zint_sm=window;

windowSize = 40;    %10-meter window
zint_sm=filter(ones(1,windowSize)/windowSize,1,zint);

Er=[];
A=0.01:0.001:0.3;
for ii=1:length(A);
    z_eq=-A(ii)*xint.^(2/3);
    dif=z_eq-zint_sm;
    dif2=mean(dif.^2);
    Er=[Er dif2];
end
Err=min(Er);
A=A(Er==Err);
z_eq=A*xint.^(2/3);

%test another equation for A = mean(di*xi^(2/3))/mean(xi^(4/3)),
% A_gs = mean(zint.*xint.^(2/3))./mean(xint.^(4/3));

%compute D50
% w=nthroot(A/0.067,0.44);
% d=nthroot(w/14,1.1);
d=14.21*A^4 + 57.24*A^3 - 10.47*A^2 + 2.25*A +0.01;

hFig=figure;
set(hFig, 'Visible', 'off');
hold on
p(1)=plot(xint,zint,'k--');
p(2)=plot(xint,zint_sm,'m');
p(3)=plot(xint,-z_eq,'g');
text(100,-1,strcat('z= ',num2str(A),'x^{2/3}'));
text(100,-1.5,strcat('d50= ',num2str(d)));

xlabel('x (m)')
ylabel('z (m)')
title(strcat('Smoothed and Equilibrium Beach Profile for Transect ',id));
legend(p,'Orig','Smooth','Equilibrium')
print(hFig, '-dtiff', '-r150', strcat(outpth,'/',id,'_Equilib.png'));
close all;

