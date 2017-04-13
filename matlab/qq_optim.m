function [qq_th, qq_eps, eps] = qq_optim(PEAKS_WL,Nyrs)

%% CompositeSet_SWL_LM.m
%  By: Norberto C. Nadal-Caraballo, PhD

% %% ************************************************************************
% 
% d_th = 0.1:0.01:0.9;
% 
% clear eps epsi qq_th
% eps(1,:) = d_th;
% 
% 
% for i=1:size(d_th,2)
%     
%     clear temp_rp x y sx n m nvec pp q1x q3x q1y q3y dx dy slope pd
%     
%     temp_rp = PEAKS_WL(PEAKS_WL(:,4)>d_th(1,i),1);
%     temp_rp(isnan(temp_rp)==1,:)=[];
%     
%     x=temp_rp;
%     [y,origindy] = sort(x); %#ok<NASGU>
%     clear origindy
%     
%     %x = plotpos(y);
%     sx=y;
%     [n, m] = size(sx);
%     if n == 1
%         sx = sx';
%         n = m;
%         m = 1;
%     end
%     nvec = sum(~isnan(sx));
%     pp = repmat((1:n)', 1, m);
%     pp = (pp-.5) ./ repmat(nvec, n, 1);
%     pp(isnan(sx)) = NaN;
%     x=pp;
%     %x = plotpos(y);
%     pd = fitdist(temp_rp,'gp','theta',0.999999*min(temp_rp));
%     x = icdf(pd,x);
%     q1x = prctile(x,25);
%     q3x = prctile(x,75);
%     q1y = prctile(y,25);
%     q3y = prctile(y,75);
%     dx = q3x - q1x;
%     dy = q3y - q1y;
%     slope = dy./dx;
%     
%     eps(2,i) = slope;
%     eps(3,i) = abs(slope-1);
%     
%     %Concavity
%     WL_th = min(temp_rp)*0.999999;
%     gpPar_WL = gpfit(temp_rp(:,1) - WL_th);
%     Nstm = size(temp_rp,1);
%     
%     for j = 1:Nstm
%         temp_rp(j,2) = j;
%         temp_rp(j,3) = 1-(temp_rp(j,2)/(Nstm+1));
%         temp_rp(j,4) = (1/(Nstm/Nyrs))/(1-temp_rp(j,3));
%         temp_rp(j,5) = gpinv(temp_rp(j,3),gpPar_WL(1,1),gpPar_WL(1,2),WL_th);
%     end%for
%     
%     %RMS
%     RMS_1 = sqrt(mean((temp_rp(temp_rp(:,4)>= 1,1)-temp_rp(temp_rp(:,4)>= 1,5)).^2));
%     RMS_10 = sqrt(mean((temp_rp(temp_rp(:,4)>= 10,1)-temp_rp(temp_rp(:,4)>= 10,5)).^2));
%     
%     Tail(1:4,1:5)=NaN;
%     Tail(1:4,4) = [500;200;150;100];
%     Tail(:,3) = 1-Nyrs./(Nstm*Tail(:,4));
%     for k = 1:size(Tail,1)
%         Tail(k,5) = gpinv(Tail(k,3),gpPar_WL(1,1),gpPar_WL(1,2),WL_th);
%     end%for k
%     temp_rp = vertcat(Tail,temp_rp);
%     
%     c0 = interp1(temp_rp(:,4),temp_rp(:,5),1);
%     c1 = interp1(temp_rp(:,4),temp_rp(:,5),10);
%     m = (c1-c0)/(log10(10)-log10(1));
%     c2 = m*log10(500) + c0;
%     C = (c2 - temp_rp(1,5));
%     %Concavity
%     
%     eps(4,i) = RMS_1;
%     eps(5,i) = RMS_10;
%     eps(6,i) = C;
%     
% end%for i
% 
% idx = find(eps(6,:)<=0);
% if isempty(idx)==0
%     eps(:,idx)=NaN;
% end%if
% 
% epsi(3,:) = eps(3,:)./nanmean(eps(3,:));
% epsi(4,:) = eps(4,:)./nanmean(eps(4,:));
% epsi(5,:) = eps(5,:)./nanmean(eps(5,:));
% 
% epsi(6,:) = 0.6*epsi(3,:) + 0.2*epsi(4,:) + 0.4*epsi(5,:);
% 
% 
% qq_idx = min(find((epsi(6,:) == min(epsi(6,:)))));
% 
% qq_th = eps(1,qq_idx);
% qq_eps = eps(3,qq_idx);
% 
% %% END


%% ************************************************************************

d_th = 0.1:0.01:0.9;

clear eps qq_th
eps(1,:) = d_th;


for i=1:size(d_th,2)
    
    clear temp_rp x y sx n m nvec pp q1x q3x q1y q3y dx dy slope pd
    
    temp_rp = PEAKS_WL(PEAKS_WL(:,4)>d_th(1,i),1);
    temp_rp(isnan(temp_rp)==1,:)=[];
    
    x=temp_rp;
    [y,origindy] = sort(x); %#ok<NASGU>
    clear origindy
    
    %x = plotpos(y);
    sx=y;
    [n, m] = size(sx);
    if n == 1
        sx = sx';
        n = m;
        m = 1;
    end
    nvec = sum(~isnan(sx));
    pp = repmat((1:n)', 1, m);
    pp = (pp-.5) ./ repmat(nvec, n, 1);
    pp(isnan(sx)) = NaN;
    x=pp;
    %x = plotpos(y);
    pd = fitdist(temp_rp,'gp','theta',0.999999*min(temp_rp));
    x = icdf(pd,x);
    q1x = prctile(x,25);
    q3x = prctile(x,75);
    q1y = prctile(y,25);
    q3y = prctile(y,75);
    dx = q3x - q1x;
    dy = q3y - q1y;
    slope = dy./dx;
    
    eps(2,i) = slope;
    eps(3,i) = abs(slope-1);
    
end%for i

qq_idx = max(find((eps(3,:) == min(eps(3,:)))));

qq_th = eps(1,qq_idx);
qq_eps = eps(3,qq_idx);

%% END
    
