% cd('P:\02\NY\GREATLAKES\ERDC\UPDATE_JUNE\Storm Event Selection\SurgePDS_LM')
% Surge_LM = load('Surge_LM.mat'); 

cd('P:\05\LakeErie_General\Coastal_Methodology\JPMtest\input');

storms = load('index_of_storms.txt');

maxele_all = zeros(389752, length(storms)); %create dummy to hold all of the max data
maxHS_all = zeros(389752, length(storms)); 
maxTps_all = zeros(389752, length(storms)); 

 for i = 1:length(storms)
 i
     directory = ['P:\05\LakeErie_General\Coastal_Methodology\SWEL\Storm_archive_Max\', num2str(storms(i))];
     cd(directory)
 
     NHeaders = 3; %number of header lines to skip
     Ndatalines = 389750; %number of nodes to read in

     fid = fopen('maxele.63'); %open surge elevation
 
     for n=1:NHeaders
       s = fgetl(fid);
     end
 
     Result = [];
 
     while (~feof(fid))
         p = 1;
         Data = zeros(Ndatalines,2);
                        
         while (~feof(fid) & (p < Ndatalines))
           s = fgetl(fid);
           Data(p,:) = sscanf(s,'%f %f');
              p = p+1;
         end
          Result = [Result; Data(1:p,:)];
 
     end
 fclose(fid)
 
 
 %save to main file
 maxele_all(:,i) = Result(:,2);
 
 
 end
 
 
 save 'maxele.txt' maxele_all -ascii -tabs


%Reduce the number of nodes

%in arc, reduce number of nodes in grid to manageable amount around erie. 
%These node numbers correspond to the index in maxele_all, since the output
%was assciated by node number 1:end. 
% cd('P:\02\NY\Great Lakes Coastal\Great_Lakes_Demo\TECHNICAL\ENG_FLOOD_HAZ_DEV\COASTAL\SWEL\Storm_archive_Max\CODE');
% 
% reduce = load('Reduce_nodes.txt');
% 
% maxele_reduced = maxele_all([reduce], :);
% 
% save 'maxelereduced.txt' maxele_reduced -ascii -tabs
% 
% clear reduce maxele_reduced

% 
% 
clear Result
clear Data
clear s
for i = 1:length(storms)
i
    directory = ['P:\05\LakeErie_General\Coastal_Methodology\SWEL\Storm_archive_Max\', num2str(storms(i))];
    cd(directory)

    NHeaders = 3; %number of header lines to skip
    Ndatalines = 389750; %number of nodes to read in

    fid = fopen('swan_HS_max.63'); %open wave height 
    
    for n=1:NHeaders
      s = fgetl(fid);
    end

    Result = [];

    while (~feof(fid))
        p = 1;
        Data = zeros(Ndatalines,2);
                       
        while (~feof(fid) & (p < Ndatalines))
          s = fgetl(fid);
          Data(p,:) = sscanf(s,'%f %f');
             p = p+1;
        end
         Result = [Result; Data(1:p,:)];

    end
fclose(fid)


%save to main file
maxHS_all(:,i) = Result(:,2);


end

save 'maxHS.txt' maxHS_all -ascii -tabs

clear Result
clear Data
clear s
% 
% 
% %reduce number of nodes
% cd('P:\02\NY\Great Lakes Coastal\Great_Lakes_Demo\TECHNICAL\ENG_FLOOD_HAZ_DEV\COASTAL\SWEL\Storm_archive_Max\CODE');
% 
% reduce = load('Reduce_nodes.txt');
% 
% maxHS_reduced = maxHS_all([reduce], :);
% 
% save 'maxHSreduced.txt' maxHS_reduced -ascii -tabs
% 




clear Result
clear Data
clear s
for i = 1:length(storms)
i
    directory = ['P:\05\LakeErie_General\Coastal_Methodology\SWEL\Storm_archive_Max\', num2str(storms(i))];
    cd(directory)

    NHeaders = 3; %number of header lines to skip
    Ndatalines = 389750; %number of nodes to read in

    fid = fopen('swan_TPS_atHSmax.63'); %open wave height 
    
    for n=1:NHeaders
      s = fgetl(fid);
    end

    Result = [];

    while (~feof(fid))
        p = 1;
        Data = zeros(Ndatalines,2);
                       
        while (~feof(fid) & (p < Ndatalines))
          s = fgetl(fid);
          Data(p,:) = sscanf(s,'%f %f');
             p = p+1;
        end
         Result = [Result; Data(1:p,:)];

    end
fclose(fid)


%save to main file
maxTps_all(:,i) = Result(:,2);


end

save 'maxTps.txt' maxTps_all -ascii -tabs

% all result would be created in storm 20081228 folder


% %reduce number of nodes
% cd('P:\02\NY\Great Lakes Coastal\Great_Lakes_Demo\TECHNICAL\ENG_FLOOD_HAZ_DEV\COASTAL\SWEL\Storm_archive_Max\CODE');
% 
% reduce = load('Reduce_nodes.txt');
% 
% maxTps_reduced = maxTps_all([reduce], :);
% 
% save 'maxTPSreduced.txt' maxTps_reduced -ascii -tabs
