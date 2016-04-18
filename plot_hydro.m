clear all;
close all;

%Load in storm/scenario list
storms = load('stormlist.txt');

count = length(storms);

for ii = 1:count
    files = dir(strcat(num2str(storms(ii)),'*.txt'));
    for jj=1:length(files)
        file_nm  = files(jj).name;
        t_series = load(file_nm);               %time, WSE, Hs, Tp
        t_series(:,1) = t_series(:,1)/86400;    %convert time to days
        t_series(t_series(:,2)<-100,2) = nan;    %no data from -99999 to nan
        t_series(t_series(:,3)<-100,3) = nan; 
        t_series(t_series(:,4)<-100,4) = nan; 
        hydro_nm = file_nm(1:length(file_nm)-4);
        
        hFig=figure();
        set(hFig, 'Visible', 'off');
        hold on;
        grid on;
        plot(t_series(:,1),t_series(:,2)/0.3048,'k','linewidth',2); %feet
        plot(t_series(:,1),t_series(:,3)/0.3048,'ro');              %feet
        plot(t_series(:,1),t_series(:,4),'b.');
        legend('WSE','Hs','Tp');
        title(hydro_nm,'FontSize', 16,'Interpreter','none');
        xlabel({'Simulation Days'}, 'FontSize',14);
        ylabel({'Feet/Seconds'},'FontSize',14);
        print(hFig,hydro_nm,'-djpeg');
        close(hFig);
        
    end
end