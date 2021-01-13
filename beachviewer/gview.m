%  Basic Viewer for Sand Survey Database NETCDF files
%
%  4/15/2020: updated to include survey type, "wheel"
%  4/15/2020: updated on github

close all
warning('off','all')

if ~exist('/Volumes/group')
    fprintf('\nPlease connect to reefbreak server (group folder) before running beach viewer.\n\n')
    return
end

disp('Connected!')
fprintf('\n\n')

global fig fig2 fig3 H xyzdata

% path to MOP transect definition text file 
mopurl='http://cdip.ucsd.edu/MOP_v1.1/CA_v1.1_transect_definitions.txt';

% set up beach viewer interface
fig=figure('Name','Guz-o-matic Beach Survey Viewer 1.0','NumberTitle','off',...
    'position',[0 790 1505 105],'ToolBar','none','MenuBar','none');
set(fig,'Color',[223 206 157]/256);

fig2=figure('NumberTitle','off',...
    'position',[305 60 1200 700],'MenuBar','none');

fig3=figure('Name','Survey Menu','NumberTitle','off',...
    'position',[0 60 300 900],'ToolBar','none','MenuBar','none');
set(fig3,'Color',[223 206 157]/256);

H=gobjects(4,1); % preallocate handle for profile map overlay pobjects;

% preallocate struct for xyz data
xyzdata = struct('x',{},'y',{},'z',{},'x2',{},'y2',{},'z2',{},'mopnum',{},...
    'F',{},'mopnum2',{},'F2',{},'name',{},'smop',{},'nmop',{});

load_surveys()
load_lidar_survey_geotiff_catalogs()
load_airborne_lidar_survey_catalogs()

load_MOP_definitions(mopurl)

launch_viewer_control_window

%------------------------------------------------------------------------
function load_surveys()
%------------------------------------------------------------------------

disp('Accessing jumbo/atv data.....')

global AreaTable AreaName AreaDefs

num_areas=17;

%---------------------------------------------------------------------
% For each survey area, make a matlab table of survey
%  dates and survey types
%---------------------------------------------------------------------

% create cell array of table names for the survey areas
AreaName=cell(num_areas,1);
AreaName{1}='NorthSDCounty';
AreaName{2}='SanOnofre';
AreaName{3}='CampPendleton';
AreaName{4}='NorthCarlsbad';
AreaName{5}='SouthCarlsbad';
AreaName{6}='Encinitas';
AreaName{7}='SanElijo';
AreaName{8}='Cardiff';
AreaName{9}='Solana';
AreaName{10}='DelMar';
AreaName{11}='TorreyPines';
AreaName{12}='Blacks';
AreaName{13}='CoronadoCity';
AreaName{14}='SilverstrandNorth';
AreaName{15}='SilverstrandSouth';
AreaName{16}='ImperialBeach';
AreaName{17}='TJRivermouth';

AreaDefs = NaN(num_areas,2);
AreaDefs(1,:) = [1143 1210];
AreaDefs(2,:) = [1102 1143];
AreaDefs(3,:) = [964 985];
AreaDefs(4,:) = [829 874];
AreaDefs(5,:) = [768 829];
AreaDefs(6,:) = [708 768];
AreaDefs(7,:) = [683 708];
AreaDefs(8,:) = [666 683];
AreaDefs(9,:) = [636 666];
AreaDefs(10,:) = [590 636];
AreaDefs(11,:) = [568 590];
AreaDefs(12,:) = [519 568];
AreaDefs(13,:) = [169 196];
AreaDefs(14,:) = [118 169];
AreaDefs(15,:) = [61 118];
AreaDefs(16,:) = [21 61];
AreaDefs(17,:) = [1 21];

% loop through areas and make tables

atvfiles = dir('/Volumes/group/topobathy/2*atv_alongshore*');
jumbofiles = dir('/Volumes/group/topobathy/2*jumbo*');
wheelfiles = dir('/Volumes/group/topobathy/2*wheel*');

totfiles = length(atvfiles)+length(jumbofiles)+length(wheelfiles);

AreaTable=cell(totfiles,1);

% loop through atv files
folder={atvfiles(:).folder};
files={atvfiles(:).name};
    
% create cell arrays to store survey info for table
SurveyDate=cell(totfiles,1);
SurveyType=cell(totfiles,1);
SurveyGroup=cell(totfiles,1);
SurveyArea=cell(totfiles,1);
SurveyName=cell(totfiles,1);
SouthMop=cell(totfiles,1);
NorthMop=cell(totfiles,1);

% loop through atv files
loc = 1;
for f = 1:length(files)
    % get fth file and folder
    filecurr = files(f);
    foldercurr = folder(f);
    
    info = split(filecurr,'_');
    
    % if ghost file
    if string(info{1}) == "." || isempty(str2num(info{2}))
        SurveyDate=SurveyDate(1:length(SurveyDate)-1);
        SurveyType=SurveyType(1:length(SurveyType)-1);
        SurveyGroup=SurveyGroup(1:length(SurveyGroup)-1);
        SurveyName=SurveyName(1:length(SurveyName)-1);
        SurveyArea=SurveyArea(1:length(SurveyName)-1);
        SouthMop=SouthMop(1:length(SouthMop)-1);
        NorthMop=NorthMop(1:length(NorthMop)-1);
        continue
    end
    
    % set survey info
    SurveyDate{loc} = info{1};
    SurveyType{loc} = 'atv';
    SurveyGroup{loc} = 'sio';
    SouthMop{loc} = info{2};
    smop = str2num(info{2});
    NorthMop{loc} = info{3};
    nmop = str2num(info{3});

    % find survey area
    ndiff = nmop-AreaDefs(:,2);
    sdiff = smop-AreaDefs(:,1);
    [nbound, northind] = min(abs(ndiff));
    [sbound, southind] = min(abs(sdiff));
    % add indices if overlaps next survey section
    if ndiff(northind) < 0 && sdiff(southind) < 0 && northind ~= southind
        SurveyArea{loc} = AreaName{end};
    elseif (northind-southind == 1) && nbound < 1
        SurveyArea{loc} = AreaName{southind};
    else
        if ndiff(northind) >= 0 && northind ~= 1
            northind = northind-1;
        end
        if sdiff(southind) <= 0 && southind ~= 17
            southind = southind+1;
        end
        SurveyArea{loc} = strjoin(flipud(AreaName(northind:southind)),'_');
    end
    
    % check if empty SurveyArea
    if isempty(SurveyArea{loc})
        SurveyArea{loc} = AreaName{end};
    end
    
    % get survey name
    SurveyName{loc} = info{4};
    
    % check if first character is '_'
    if strcmp(SurveyName{loc}(1),'_')
        SurveyName{loc} = SurveyName{loc}(2:end);
    end
    
    if isempty(SurveyName{loc}) || contains(SurveyName{loc},'ground')
        % need to pick survey name using SurveyArea
        SurveyName{loc} = SurveyArea{loc};
    end
    
    loc = loc+1;
end

% loop through jumbo files
folder={jumbofiles(:).folder};
files={jumbofiles(:).name};

for f = 1:length(files)
    % get fth file and folder
    filecurr = files(f);
    foldercurr = folder(f);
    
    info = split(filecurr,'_');
    
    % if ghost file
    if string(info{1}) == "." || isempty(str2num(info{2}))
        SurveyDate=SurveyDate(1:length(SurveyDate)-1);
        SurveyType=SurveyType(1:length(SurveyType)-1);
        SurveyGroup=SurveyGroup(1:length(SurveyGroup)-1);
        SurveyName=SurveyName(1:length(SurveyName)-1);
        SurveyArea=SurveyArea(1:length(SurveyName)-1);
        SouthMop=SouthMop(1:length(SouthMop)-1);
        NorthMop=NorthMop(1:length(NorthMop)-1);
        continue
    end
    
    % set survey info
    SurveyDate{loc} = info{1};
    SurveyType{loc} = 'jumbo';
    SurveyGroup{loc} = 'sio';
    SouthMop{loc} = info{2};
    smop = str2num(info{2});
    NorthMop{loc} = info{3};
    nmop = str2num(info{3});

    % find survey area
    ndiff = nmop-AreaDefs(:,2);
    sdiff = smop-AreaDefs(:,1);
    [nbound, northind] = min(abs(ndiff));
    [sbound, southind] = min(abs(sdiff));
    % add indices if overlaps next survey section
    if ndiff(northind) < 0 && sdiff(southind) < 0 && northind ~= southind
        SurveyArea{loc} = AreaName{end};
    elseif (northind-southind == 1) && nbound < 1
        SurveyArea{loc} = AreaName{southind};
    else
        if ndiff(northind) >= 0 && northind ~= 1
            northind = northind-1;
        end
        if sdiff(southind) <= 0 && southind ~= 17
            southind = southind+1;
        end
        SurveyArea{loc} = strjoin(flipud(AreaName(northind:southind)),'_');
    end
    
    % check if empty SurveyArea
    if isempty(SurveyArea{loc})
        SurveyArea{loc} = AreaName{end};
    end
    
    % get survey name
    SurveyName{loc} = info{4};
    
    % check if first character is '_'
    if strcmp(SurveyName{loc}(1),'_')
        SurveyName{loc} = SurveyName{loc}(2:end);
    end
    
    if isempty(SurveyName{loc}) || contains(SurveyName{loc},'ground')
        % need to pick survey name using SurveyArea
        SurveyName{loc} = SurveyArea{loc};
    end
    
    loc = loc+1;
end

% loop through wheel files
folder={wheelfiles(:).folder};
files={wheelfiles(:).name};

for f = 1:length(files)
    % get fth file and folder
    filecurr = files(f);
    foldercurr = folder(f);
    
    info = split(filecurr,'_');
    
    % if ghost file
    if string(info{1}) == "." || isempty(str2num(info{2}))
        SurveyDate=SurveyDate(1:length(SurveyDate)-1);
        SurveyType=SurveyType(1:length(SurveyType)-1);
        SurveyGroup=SurveyGroup(1:length(SurveyGroup)-1);
        SurveyName=SurveyName(1:length(SurveyName)-1);
        SurveyArea=SurveyArea(1:length(SurveyName)-1);
        SouthMop=SouthMop(1:length(SouthMop)-1);
        NorthMop=NorthMop(1:length(NorthMop)-1);
        continue
    end
    
    % set survey info
    SurveyDate{loc} = info{1};
    SurveyType{loc} = 'wheel';
    SurveyGroup{loc} = 'sio';
    SouthMop{loc} = info{2};
    smop = str2num(info{2});
    NorthMop{loc} = info{3};
    nmop = str2num(info{3});

    % find survey area
    ndiff = nmop-AreaDefs(:,2);
    sdiff = smop-AreaDefs(:,1);
    [nbound, northind] = min(abs(ndiff));
    [sbound, southind] = min(abs(sdiff));
    % add indices if overlaps next survey section
    if ndiff(northind) < 0 && sdiff(southind) < 0 && northind ~= southind
        SurveyArea{loc} = AreaName{end};
    elseif (northind-southind == 1) && nbound < 1
        SurveyArea{loc} = AreaName{southind};
    else
        if ndiff(northind) >= 0 && northind ~= 1
            northind = northind-1;
        end
        if sdiff(southind) <= 0 && southind ~= 17
            southind = southind+1;
        end
        SurveyArea{loc} = strjoin(flipud(AreaName(northind:southind)),'_');
    end
    
    % check if empty SurveyArea
    if isempty(SurveyArea{loc})
        SurveyArea{loc} = AreaName{end};
    end
    
    % get survey name
    SurveyName{loc} = info{4};
    
    % check if first character is '_'
    if strcmp(SurveyName{loc}(1),'_')
        SurveyName{loc} = SurveyName{loc}(2:end);
    end
    
    if isempty(SurveyName{loc}) || contains(SurveyName{loc},'ground')
        % need to pick survey name using SurveyArea
        SurveyName{loc} = SurveyArea{loc};
    end
    
    loc = loc+1;
end

AreaTable=table(SurveyDate,SurveyType,SurveyName,SurveyArea,SurveyGroup,SouthMop,NorthMop);

end


%------------------------------------------------------------------------
function load_lidar_survey_geotiff_catalogs()
%------------------------------------------------------------------------

disp('Accessing truck lidar data.....')
fprintf('\n\n')

global AreaTable AreaName AreaDefs files folder moprange

% loop through areas and make tables
filesd=dir('/Volumes/group/LiDAR/VMZ2000_Truck/VMZ2000_Truck/LiDAR_Processed_Level2/*/Beach_Only/*.tif');
folder={filesd(:).folder};
files={filesd(:).name};
num_files = length(files);
    
% create cell arrays to store survey info for table
SurveyDate=cell(num_files,1);
SurveyType=cell(num_files,1);
SurveyGroup=cell(num_files,1);
SurveyArea=cell(num_files,1);
SurveyName=cell(num_files,1);
SouthMop=cell(num_files,1);
NorthMop=cell(num_files,1);

% loop through files and add survey date, type and group to table cell arrays
loc = 1;
for f = 1:length(files)
    % get fth file and folder
    filecurr = files(f);
    foldercurr = folder(f);
    
    info = split(filecurr,'_');
    
    % if ghost file
    if string(info{1}) == "." || isempty(str2num(info{2}))
        SurveyDate=SurveyDate(1:length(SurveyDate)-1);
        SurveyType=SurveyType(1:length(SurveyType)-1);
        SurveyGroup=SurveyGroup(1:length(SurveyGroup)-1);
        SurveyName=SurveyName(1:length(SurveyName)-1);
        SurveyArea=SurveyArea(1:length(SurveyName)-1);
        SouthMop=SouthMop(1:length(SouthMop)-1);
        NorthMop=NorthMop(1:length(NorthMop)-1);
        continue
    end
    
    % set survey info
    SurveyDate{loc} = info{1};
    SurveyType{loc} = 'lidar';
    SurveyGroup{loc} = 'sio';
    SouthMop{loc} = info{2};
    smop = str2num(info{2});
    NorthMop{loc} = info{3};
    nmop = str2num(info{3});

    % find survey area
    ndiff = nmop-AreaDefs(:,2);
    sdiff = smop-AreaDefs(:,1);
    [nbound, northind] = min(abs(ndiff));
    [sbound, southind] = min(abs(sdiff));
    % add indices if overlaps next survey section
    if ndiff(northind) < 0 && sdiff(southind) < 0 && northind ~= southind
        SurveyArea{loc} = AreaName{end};
    elseif (northind-southind == 1) && nbound < 1
        SurveyArea{loc} = AreaName{southind};
    else
        if ndiff(northind) >= 0 && northind ~= 1
            northind = northind-1;
        end
        if sdiff(southind) <= 0 && southind ~= 17
            southind = southind+1;
        end
        SurveyArea{loc} = strjoin(flipud(AreaName(northind:southind)),'_');
    end
    
    % check if empty SurveyArea
    if isempty(SurveyArea{loc})
        SurveyArea{loc} = AreaName{end};
    end
    
    % get survey name
    sname = [sprintf('%s_',info{4:end-1}),info{end}];
    SurveyName{loc} = erase(sname,["_ground";"ground_";"_export";"export_";"_NoWaves";"NoWaves_";"NoWaves";"_beach";"beach_";"_ground";"ground_";".tif"]);
    
    % check if first character is '_'
    if strcmp(SurveyName{loc}(1),'_')
        SurveyName{loc} = SurveyName{loc}(2:end);
    end
    
    if isempty(SurveyName{loc}) || contains(SurveyName{loc},'ground')
        % need to pick survey name using SurveyArea
        SurveyName{loc} = SurveyArea{loc};
    end
    
    loc = loc+1;
end

% create table for the survey area
AreaTable=[AreaTable;table(SurveyDate,SurveyType,SurveyName,SurveyArea,SurveyGroup,SouthMop,NorthMop)];

AreaTable = sortrows(AreaTable,1,'descend');

% create mop menu options

munique = [];
for m = 1:height(AreaTable)
    minmop = str2num(AreaTable.SouthMop{m});
    maxmop = str2num(AreaTable.NorthMop{m});
    mrange = (minmop:maxmop);
    munique = unique([munique;mrange']);
end

moprange = munique;

end


%------------------------------------------------------------------------
function load_airborne_lidar_survey_catalogs()
%------------------------------------------------------------------------

disp('Accessing airborne lidar data.....')
fprintf('\n\n')

global AreaTable AreaName AreaDefs files folder moprange

% loop through areas and make tables
filesd=dir('/Volumes/group/LiDAR/VMZ2000_Truck/LiDAR_Airborne/*/Beach_Only/*.txt');
folder={filesd(:).folder};
files={filesd(:).name};
num_files = length(files);
    
% create cell arrays to store survey info for table
SurveyDate=cell(num_files,1);
SurveyType=cell(num_files,1);
SurveyGroup=cell(num_files,1);
SurveyArea=cell(num_files,1);
SurveyName=cell(num_files,1);
SouthMop=cell(num_files,1);
NorthMop=cell(num_files,1);

% loop through files and add survey date, type and group to table cell arrays
loc = 1;
for f = 1:length(files)
    % get fth file and folder
    filecurr = files(f);
    foldercurr = folder(f);
    
    info = split(filecurr,'_');
    
    % if ghost file
    if string(info{1}) == "." || isempty(str2num(info{3}))
        SurveyDate=SurveyDate(1:length(SurveyDate)-1);
        SurveyType=SurveyType(1:length(SurveyType)-1);
        SurveyGroup=SurveyGroup(1:length(SurveyGroup)-1);
        SurveyName=SurveyName(1:length(SurveyName)-1);
        SurveyArea=SurveyArea(1:length(SurveyName)-1);
        SouthMop=SouthMop(1:length(SouthMop)-1);
        NorthMop=NorthMop(1:length(NorthMop)-1);
        continue
    end
    
    % set survey info
    SurveyDate{loc} = info{1};
    SurveyType{loc} = 'lidar';
    SurveyGroup{loc} = 'sio';
    SouthMop{loc} = info{3};
    smop = str2num(info{3});
    NorthMop{loc} = info{4};
    nmop = str2num(info{4});

    % find survey area
    ndiff = nmop-AreaDefs(:,2);
    sdiff = smop-AreaDefs(:,1);
    [nbound, northind] = min(abs(ndiff));
    [sbound, southind] = min(abs(sdiff));
    % add indices if overlaps next survey section
    if ndiff(northind) < 0 && sdiff(southind) < 0 && northind ~= southind
        SurveyArea{loc} = AreaName{end};
    elseif (northind-southind == 1) && nbound < 1
        SurveyArea{loc} = AreaName{southind};
    else
        if ndiff(northind) >= 0 && northind ~= 1
            northind = northind-1;
        end
        if sdiff(southind) <= 0 && southind ~= 17
            southind = southind+1;
        end
        SurveyArea{loc} = strjoin(flipud(AreaName(northind:southind)),'_');
    end
    
    % check if empty SurveyArea
    if isempty(SurveyArea{loc})
        SurveyArea{loc} = AreaName{end};
    end
    
    % get survey name
    sname = [sprintf('%s_',info{4:end-1}),info{end}];
    SurveyName{loc} = erase(sname,["_ground";"ground_";"_export";"export_";"_NoWaves";"NoWaves_";"NoWaves";"_beach";"beach_";"_ground";"ground_";".txt"]);
    
    % check if first character is '_'
    if strcmp(SurveyName{loc}(1),'_')
        SurveyName{loc} = SurveyName{loc}(2:end);
    end
    
    if isempty(SurveyName{loc}) || contains(SurveyName{loc},'ground')
        % need to pick survey name using SurveyArea
        SurveyName{loc} = SurveyArea{loc};
    end
    
    loc = loc+1;
end

% create table for the survey area
AreaTable=[AreaTable;table(SurveyDate,SurveyType,SurveyName,SurveyArea,SurveyGroup,SouthMop,NorthMop)];

AreaTable = sortrows(AreaTable,1,'descend');

% create mop menu options

munique = [];
for m = 1:height(AreaTable)
    minmop = str2num(AreaTable.SouthMop{m});
    maxmop = str2num(AreaTable.NorthMop{m});
    mrange = (minmop:maxmop);
    munique = unique([munique;mrange']);
end

moprange = munique;

end

%------------------------------------------------------------------------
function load_MOP_definitions(mopurl)
%------------------------------------------------------------------------

disp('Loading MOP lines...')
fprintf('\n\n')

global Mop 

mopdef=webread(mopurl);
i=strfind(mopdef,'--');   % find beginning of mop transect table
mopdef=regexp(mopdef(i(end)+2:end),'\S*','match');
mopdef=reshape(mopdef,[9 11594]);
Name=mopdef(2,:)';
BackLon=str2double(mopdef(3,:))';
BackLat=str2double(mopdef(4,:))';
OffLon=str2double(mopdef(5,:))';
OffLat=str2double(mopdef(6,:))';
Depth=str2double(mopdef(7,:))';
Normal=str2double(mopdef(8,:))';
Complex=str2double(mopdef(9,:))';
Mop=table(Name,BackLon,BackLat,OffLon,OffLat,...
   Depth,Normal,Complex); 

end

%------------------------------------------------------------------------
function launch_viewer_control_window

% initial launch with choose by mop

%------------------------------------------------------------------------

global AreaTable AreaDefs AreaName moprange plotit rsurvey rmops rdiff atable 
global areamenu survmenus survhead mopmenu numsmenu checkmenu profilemenu
global areanum aprev sprev sprev2 fig fig2 fig3

aprev=0;
sprev=0;
sprev2=0;

set(0,'DefaultUicontrolFontSize',20);
set(0,'DefaultUicontrolFontWeight','normal');

bc=([223 206 157]/256);

% Launch Menu Toggle
cg = uibuttongroup('Visible','off',...
                  'Position',[0 0 1.1 0.18],...
                  'SelectionChangedFcn',@switch_selection);
              
% Create two radio buttons in the button group.
rmops = uicontrol(cg,'Style',...
                  'radiobutton',...
                  'String','Choose by MOP',...
                  'Position',[50 110 290 25],...
                  'HandleVisibility','off');
              
rsurvey = uicontrol(cg,'Style','radiobutton',...
                  'String','Choose by survey',...
                  'Position',[50 60 290 30],...
                  'HandleVisibility','off');
              
rdiff = uicontrol(cg,'Style','radiobutton',...
                  'String','Difference map',...
                  'Position',[50 10 290 30],...
                  'HandleVisibility','off');
              
cg.Visible = 'on';

% Mop Number Menu
mophead=uicontrol(fig,'style','text','position',[1155 50 150 40],...
    'string','MOP #',...
    'foregroundcolor','b','backgroundcolor',bc);
mopstrings = flipud(split(sprintf('D%04d ',moprange),' '));
mopstrings = mopstrings(2:end);
mopmenu=uicontrol(fig,'style','popup','position',[1155 25 150 40],...
    'string',mopstrings,'value',length(mopstrings)-floor(length(mopstrings)/35),...
    'callback',@update_sselection);

% Number of Surveys Menu, defaults to 2
numshead=uicontrol(fig3,'style','text','position',[10 805 290 30],...
    'string','Number of Surveys: ','foregroundcolor','b','backgroundcolor',bc);
numsmenu=uicontrol(fig3,'style','popup','position',[10 800 100 10],...
    'string',(1:15),'callback',{@launch_smenu,numsmenu});

% Area Menu
areahead=uicontrol(fig3,'style','text','position',[10 865 290 30],...
    'string','SURVEY AREA','foregroundcolor','b','backgroundcolor',bc);
areamenu=uicontrol(fig3,'style','popup','position',[10 840 290 30],...
   'string','--','value',1,'callback',{@launch_smenu,numsmenu});

% Survey Menu
numsurveys = numsmenu.Value;
survhead = gobjects(numsurveys,1);
survmenus = gobjects(numsurveys,1);

% Survey Checkbox Menu
checkmenu = gobjects(numsurveys,1);

% update to survey menu with surveys that contain current mop
mopstr = mopmenu.String{mopmenu.Value,:};
mopval = str2num(mopstr(2:end));
allsmop = str2num(cell2mat(AreaTable.SouthMop));
allnmop = str2num(cell2mat(AreaTable.NorthMop));

sinds = [];

ctr = 1;
for i = 1:height(AreaTable)
    if mopval >= allsmop(i) && mopval <= allnmop(i)
        sinds(ctr) = i;
        ctr = ctr+1;
    end
end

atable=AreaTable(sinds,:);
        
% find areanum
[minm, minind] = min(abs(mopval-AreaDefs(1:end-1,1)));
[maxm, maxind] = min(abs(mopval-AreaDefs(1:end-1,2)));
areainds = unique([minind;maxind]);

if length(areainds) == 1
    areanum = areainds;
else
    a1 = strfind([atable.SurveyArea{:}],AreaName{areainds(1)});
    a2 = strfind([atable.SurveyArea{:}],AreaName{areainds(2)});
    if length(a1) > length(a2)
        areanum = areainds(1);
    else
        areanum = areainds(2);
    end
end

% Fill Survey menus
for s = 1:numsurveys

    % Survey Menu
    survhead(s) = uicontrol(fig3,'style','text','position',[2 728-(s-1)*40 25 40],...
        'string',s,'foregroundcolor','b','backgroundcolor',bc);
    survmenus(s)=uicontrol(fig3,'style','popup','position',[30 760-(s-1)*40 270 10],'userdata',s,...
            'value',1,'callback',@update_checkbox);
    survmenus(s).String=join(cat(2,atable{:,1:3},atable{:,6:7})," : ");
    
    % Checkbox Menu
    stringvals = char(string(survmenus(s).String{survmenus(s).Value}).split(' : '));
    sdate = stringvals(1,1:8);
    stype = strip(stringvals(2,:),' ');
    chkname = sprintf('%d: %s/%s/%s %s',1,sdate(5:6),sdate(7:8),sdate(1:4),stype);
    checkmenu(s) = uicontrol(fig,'style','checkbox','position',[10 72 210 30],'Value',1,...
        'userdata',s,'backgroundcolor',bc,'string',chkname,'callback',{@show_survey,s});

end

% Create profile options menu
profilemenu = gobjects(2,1);
profilemenu(1) = uicontrol(fig2,'style','checkbox','position',[600 5 150 50],...
    'Value',1,'string','Data Points','callback',@change_profile);
profilemenu(2) = uicontrol(fig2,'style','checkbox','position',[735 5 215 50],...
    'Value',0,'string','Interpolated profiles','callback',@change_profile);

% Save button for current map/profile plot as .png and .fig
saveit1=uicontrol(fig2,'style','pushbutton','position',[945 10 115 40],...
    'string','Save Plot','foregroundcolor','k','backgroundcolor',...
    [187/255,121/255,245/255],'callback',{@save_plot});
% Save button for current profile info (x, y, z, d)
saveit2=uicontrol(fig2,'style','pushbutton','position',[1075 10 115 40],...
    'string','Save Data','foregroundcolor','k','backgroundcolor',...
    [187/255,121/255,245/255],'callback',{@save_data});

% Plotting Menus
plotit=uicontrol(fig,'style','pushbutton','position',[1335 30 150 50],...
    'string','Plot It','foregroundcolor','k','backgroundcolor','g',...
    'callback',{@plot_survey,plotit});

end

%------------------------------------------------------------------------
function save_plot(varargin)

% saves current map and plot as both .png and .fig in current directory

%------------------------------------------------------------------------

global survmenus mopmenu rdiff fig2

mopname = mopmenu.String(mopmenu.Value);

if rdiff.Value == 1
    sname1 = split(survmenus(1).String(survmenus(1).Value),' : ');
    sname2 = split(survmenus(2).String(survmenus(2).Value),' : ');
    fname = sprintf('%s_%s%s_%s%s_diffplot.png',mopname{1},sname1{1},sname1{2},...
        sname2{1},sname2{2});
    fname2 = sprintf('%s_%s%s_%s%s_diffplot.fig',mopname{1},sname1{1},sname1{2},...
        sname2{1},sname2{2});
else
    fname = sprintf('%s_profiles.png',mopname{1});
    fname2 = sprintf('%s_profiles.fig',mopname{1});
end

fpath = sprintf('%s/%s',pwd,fname);
fpath2 = sprintf('%s/%s',pwd,fname2);

print(fig2,fpath,'-dpng','-r100')
savefig(fig2,fpath2)

fprintf('\n%s figure saved to %s!\n\n',fname(1:end-4),pwd)

end

%------------------------------------------------------------------------
function save_data(varargin)

% saves transect data from all surveys plotted or full lidar surveys and 
% elevation difference if difference plot
% x,y,z,d

%------------------------------------------------------------------------

global survmenus mopmenu rdiff xyzdata survlocs Mop diffz koverlap1 koverlap2

sdata = struct('x',{},'y',{},'z',{},'mopnum',{},...
        'smop',{},'nmop',{},'name',{});
for s = 1:length(survlocs)
    sdata(s).smop = xyzdata(survlocs(s)).smop;
    sdata(s).nmop = xyzdata(survlocs(s)).nmop;
    sdata(s).name = xyzdata(survlocs(s)).name;
end

mopp = mopmenu.String(mopmenu.Value);
mopp = str2num(mopp{1}(2:end));
mopname = mopmenu.String(mopmenu.Value);

if rdiff.Value == 1
    
    koverlap = [koverlap1,koverlap2];
    for s = 1:2
        
        % all lidar data pts
        sdata(s).x = xyzdata(survlocs(s)).x2(koverlap(:,s));
        sdata(s).y = xyzdata(survlocs(s)).y2(koverlap(:,s));
        sdata(s).z = xyzdata(survlocs(s)).z2(koverlap(:,s));
        sdata(s).mopnum = xyzdata(survlocs(s)).mopnum2(koverlap(:,s));
        
        m=find(xyzdata(survlocs(s)).mopnum == mopp);

        % get distance for current mop transect
        hf=double(cosd(33));
        mopvector=[Mop.OffLon(mopp)*hf,Mop.OffLat(mopp);...
            Mop.BackLon(mopp)*hf,Mop.BackLat(mopp)];
        pxy=ones(length(m),2);
        for n=1:length(m)
            p1=proj_points(mopvector,[xyzdata(survlocs(s)).x(m(n))*hf,xyzdata(survlocs(s)).y(m(n))]);
            pxy(n,1)=p1(1)/hf;
            pxy(n,2)=p1(2);
        end
        [d,az]=distance(Mop.BackLat(mopp)*ones(length(m),1),...
            Mop.BackLon(mopp)*ones(length(m),1),...
            pxy(:,2),pxy(:,1));
        d=d*111139; %distance along mop line from MOP back beach pt in meters
        d(az < 135)=-d(az < 135); 
                
        sdata(s).mopx = xyzdata(survlocs(s)).x(m);
        sdata(s).mopy = xyzdata(survlocs(s)).y(m);
        sdata(s).mopz = xyzdata(survlocs(s)).z(m);
        sdata(s).mopd = d;
        
        sdata(s).zdiff = diffz;

    end
    
    sname1 = split(survmenus(1).String(survmenus(1).Value),' : ');
    sname2 = split(survmenus(2).String(survmenus(2).Value),' : ');
    fname = sprintf('%s_%s%s_%s%s_diffplot.mat',mopname{1},sname1{1},sname1{2},...
        sname2{1},sname2{2});
    
else
    
    for s = 1:length(survlocs)
        m=find(xyzdata(survlocs(s)).mopnum == mopp);
        sdata(s).x = xyzdata(survlocs(s)).x(m);
        sdata(s).y = xyzdata(survlocs(s)).y(m);
        sdata(s).z = xyzdata(survlocs(s)).z(m);
        sdata(s).mopnum = xyzdata(survlocs(s)).mopnum(m);

        % get distance for current mop transect
        hf=double(cosd(33));
        mopvector=[Mop.OffLon(mopp)*hf,Mop.OffLat(mopp);...
            Mop.BackLon(mopp)*hf,Mop.BackLat(mopp)];
        pxy=ones(length(m),2);
        for n=1:length(m)
            p1=proj_points(mopvector,[xyzdata(survlocs(s)).x(m(n))*hf,xyzdata(survlocs(s)).y(m(n))]);
            pxy(n,1)=p1(1)/hf;
            pxy(n,2)=p1(2);
        end
        [d,az]=distance(Mop.BackLat(mopp)*ones(length(m),1),...
            Mop.BackLon(mopp)*ones(length(m),1),...
            pxy(:,2),pxy(:,1));
        d=d*111139; %distance along mop line from MOP back beach pt in meters
        d(az < 135)=-d(az < 135); 
        sdata(s).d = d;
    end
    
    fname = sprintf('%s_profiles.mat',mopname{1});
    
end

save(fname,'sdata')
fprintf('\n%s data saved to %s!\n\n',fname(1:end-4),pwd)

end

%------------------------------------------------------------------------
function switch_selection(varargin)
%------------------------------------------------------------------------

global mopmenu moprange rmops rsurvey AreaName AreaTable atable 
global areamenu survmenus checkmenu numsmenu survhead resetsurvs fig fig3 plotit2
global sprev sprev2 aprev areanum firstmap

if(exist('resetsurvs','var') > 0);delete(resetsurvs);end;
if(exist('plotit2','var') > 0);delete(plotit2);end;

aprev=0;
sprev=0;
sprev2=0;

if rmops.Value == 1
    % update numsmenu to 1 survey only
    numsmenu.Value = 1;
    numsmenu.String = (1:15);
    
    % update areamenu
    areamenu.Value = 1;
    areamenu.String = '--';
    if length(survmenus) >= 2 % need to remove a survey menu selection
        
        currnum = length(survmenus);
        for d = 2:currnum
            toDeleteS = survmenus(d); % delete survey menu
            delete(toDeleteS);
            toDeleteH = survhead(d); % delete survey head
            delete(toDeleteH);
            toDeleteC = checkmenu(d); % delete survey checkbox
            delete(toDeleteC);
        end
        
        survmenus = survmenus(1);
        survhead = survhead(1);
        checkmenu = checkmenu(1);
    end
    
    % update mopmenu
    mopstrings = flipud(split(sprintf('D%04d ',moprange),' '));
    mopmenu.String = mopstrings(2:end);
    mopmenu.Value = length(mopstrings)-floor(length(mopstrings)/35);
    
    % update survmenus & checkmenu
    s=1;
    mopstr = mopmenu.String{mopmenu.Value,:};
    mopval = str2num(mopstr(2:end));
    allsmop = str2num(cell2mat(AreaTable.SouthMop));
    allnmop = str2num(cell2mat(AreaTable.NorthMop));

    sinds = [];

    ctr = 1;
    for i = 1:height(AreaTable)
        if mopval >= allsmop(i) && mopval <= allnmop(i)
            sinds(ctr) = i;
            ctr = ctr+1;
        end
    end

    atable=AreaTable(sinds,:);
    survmenus(s).Value = 1;
    survmenus(s).String=join(cat(2,atable{:,1:3},atable{:,6:7})," : ");

    stringvals = char(string(survmenus(s).String{survmenus(s).Value}).split(' : '));
    sdate = stringvals(1,1:8);
    stype = strip(stringvals(2,:),' ');
    chkname = sprintf('%d: %s/%s/%s %s',s,sdate(5:6),sdate(7:8),sdate(1:4),stype);
    checkmenu(s).String = chkname;
        
elseif rsurvey.Value == 1
    % update numsmenu to 1 survey only
    numsmenu.Value = 1;
    numsmenu.String = (1:15);
    
    % update mopmenu
    mopmenu.Value = 1;
    mopmenu.String = 'TBD';
    
    % update areamenu
    areamenu.String = upper(AreaName);    
    
    if length(survmenus) >= 2 % need to remove a survey menu selection
        
        currnum = length(survmenus);
        for d = 2:currnum
            toDeleteS = survmenus(d); % delete survey menu
            delete(toDeleteS);
            toDeleteH = survhead(d); % delete survey head
            delete(toDeleteH);
            toDeleteC = checkmenu(d); % delete survey checkbox
            delete(toDeleteC);
        end
        
        survmenus = survmenus(1);
        survhead = survhead(1);
        checkmenu = checkmenu(1);
    end
    
    % update survmenus and checkmenu
    s = 1;
    survmenus(s).Value = 1;
    
    % find surveys in first area (SanOnofre)
    areanum = areamenu.Value;
    ainds = find(contains(AreaTable.SurveyArea,AreaName{areanum},...
        'IgnoreCase',true));
    atable = AreaTable(ainds,:);
    
    survmenus(s).String = join(cat(2,atable{:,1:3},atable{:,6:7})," : ");

    stringvals = char(string(survmenus(s).String{survmenus(s).Value}).split(' : '));
    sdate = stringvals(1,1:8);
    stype = strip(stringvals(2,:),' ');
    chkname = sprintf('%d: %s/%s/%s %s',s,sdate(5:6),sdate(7:8),sdate(1:4),stype);
    checkmenu(s).String = chkname;
        
else % lidar difference map
    % update numsmenu to 2 surveys only
    numsmenu.Value = 1;
    numsmenu.String = '2';
    
    % update areamenu
    areamenu.Value = 1;
    areamenu.String = '--';
    
    % update mopmenu
    mopstrings = flipud(split(sprintf('D%04d ',moprange),' '));
    mopmenu.String = mopstrings(2:end);
    mopmenu.Value = length(mopstrings)-floor(length(mopstrings)/35);
    
    % update survmenus & checkmenu
    if length(survmenus) > 2 % need to remove a survey menu selection
        
        currnum = length(survmenus);
        for d = 3:currnum
            toDeleteS = survmenus(d); % delete survey menu
            delete(toDeleteS);
            toDeleteH = survhead(d); % delete survey head
            delete(toDeleteH);
            toDeleteC = checkmenu(d); % delete survey checkbox
            delete(toDeleteC);
        end
        
        survmenus = survmenus(1:2);
        survhead = survhead(1:2);
        checkmenu = checkmenu(1:2);
    elseif length(survmenus) == 1 % need to add survey menu selection
        s = 2;
        survmenus(s) = uicontrol(fig3,'style','popup','position',[30 760-(40*(s-1)) 270 10],...
            'string',join(atable{:,1:4}," : "),'userdata',s,...
            'callback',@update_checkbox);
        survhead(s) = uicontrol(fig3,'style','text','position',[2 728-(40*(s-1)) 25 40],...
            'string',s,'foregroundcolor','b','backgroundcolor',[223 206 157]/256);
        
        % checkbox bottom position
        if mod(s,2) == 0
            pbottom = 40;
        else
            pbottom = 70;
        end
        
        stringvals = char(string(survmenus(s).String{survmenus(s).Value}).split(' : '));
        sdate = stringvals(1,1:8);
        stype = strip(stringvals(2,:),' ');
        chkname = sprintf('%d: %s/%s/%s %s',s,sdate(5:6),sdate(7:8),sdate(1:4),stype);
        checkmenu(s) = uicontrol(fig,'style','checkbox','position',[10 pbottom 230 30],'Value',1,...
            'userdata',s,'backgroundcolor',[223 206 157]/256,'string',chkname,'callback',{@show_survey,s});
    end
    
    s=1;
    mopstr = mopmenu.String{mopmenu.Value,:};
    mopval = str2num(mopstr(2:end));
    allsmop = str2num(cell2mat(AreaTable.SouthMop));
    allnmop = str2num(cell2mat(AreaTable.NorthMop));

    sinds = [];

    ctr = 1;
    for i = 1:height(AreaTable)
        if mopval >= allsmop(i) && mopval <= allnmop(i)
            sinds(ctr) = i;
            ctr = ctr+1;
        end
    end

    atable=AreaTable(sinds,:);
    
    for s = 1:length(survmenus)
        survmenus(s).Value = 1;
        % set only to lidar surveys
%         lsurvs = find(string(atable{mednum}.SurveyType) == "lidar" | string(atable{mednum}.SurveyType) == "atv");
%         survmenus(s).String=join(atable{mednum}{lsurvs,1:4}," : ");
        survmenus(s).String = join(cat(2,atable{:,1:3},atable{:,6:7})," : ");

        stringvals = char(string(survmenus(s).String{survmenus(s).Value}).split(' : '));
        sdate = stringvals(1,1:8);
        stype = strip(stringvals(2,:),' ');
        chkname = sprintf('%d: %s/%s/%s %s',s,sdate(5:6),sdate(7:8),sdate(1:4),stype);
        checkmenu(s).String = chkname;
    end
    
    % add another plotit button
    plotit2=uicontrol(fig3,'style','pushbutton','position',[165 630 115 40],...
    'string','Plot It','foregroundcolor','k','backgroundcolor','g',...
    'callback',{@plot_survey,plotit2});

    % add reset surveys button
    resetsurvs=uicontrol(fig3,'style','pushbutton','position',[20 630 115 40],...
        'string','Reset Surveys','foregroundcolor','k','backgroundcolor',...
        [0.5 0.5 0.5],'FontSize',14,'callback',@switch_selection);
    
    firstmap = 1;
end

end

%------------------------------------------------------------------------
function update_sselection(varargin)

% if mop number is changed when under choose by mop, update surveys
% available

%------------------------------------------------------------------------

global mopmenu survmenus checkmenu AreaTable AreaDefs AreaName
global rsurvey rdiff atable areanum firstmap survlocs

if rdiff.Value == 1 && ~firstmap
    return
elseif rsurvey.Value ~= 1
    
    % find surveys that include chosen mop 
    mopstr = mopmenu.String{mopmenu.Value,:};
    mopval = str2num(mopstr(2:end));
    allsmop = str2num(cell2mat(AreaTable.SouthMop));
    allnmop = str2num(cell2mat(AreaTable.NorthMop));

    sinds = [];

    ctr = 1;
    for i = 1:height(AreaTable)
        if mopval >= allsmop(i) && mopval <= allnmop(i)
            sinds(ctr) = i;
            ctr = ctr+1;
        end
    end

    atable=AreaTable(sinds,:);
    
    % previous survey menu values
    prevvals = [survmenus.Value];
    prevnames = {survmenus(1).String{prevvals}};
    
    for s = 1:length(survmenus)
        survmenus(s).Value=1;
        survmenus(s).String=join(cat(2,atable{:,1:3},atable{:,6:7})," : ");
        
        kval = find(contains(survmenus(s).String,prevnames(s)));
        if ~isempty(kval)
            survmenus(s).Value = kval;
        end
        
        survlocs(s) = survmenus(s).Value;
        
        stringvals = char(string(survmenus(s).String{survmenus(s).Value}).split(' : '));
        sdate = stringvals(1,1:8);
        stype = strip(stringvals(2,:),' ');
        chkname = sprintf('%d: %s/%s/%s %s',s,sdate(5:6),sdate(7:8),sdate(1:4),stype);
        checkmenu(s).String = chkname;
    end
    
    % find areanum
    [minm, minind] = min(abs(mopval-AreaDefs(1:end-1,1)));
    [maxm, maxind] = min(abs(mopval-AreaDefs(1:end-1,2)));
    areainds = unique([minind;maxind]);

    if length(areainds) == 1
        areanum = areainds;
    else
        a1 = strfind([atable.SurveyArea{:}],AreaName{areainds(1)});
        a2 = strfind([atable.SurveyArea{:}],AreaName{areainds(2)});
        if length(a1) > length(a2)
            areanum = areainds(1);
        else
            areanum = areainds(2);
        end
    end
end

end

%------------------------------------------------------------------------
function launch_smenu(varargin)
%------------------------------------------------------------------------

global numsmenu survmenus areamenu checkmenu survhead
global fig fig3 AreaTable AreaName atable rmops areanum

numsurveys = numsmenu.Value;

if numsurveys == length(survmenus)
    return
    
elseif numsurveys > length(survmenus) % need to add a survey menu selection

    startnum = length(survmenus)+1;
    pleft = [10,10,10,230,230,230,450,450,450,670,670,670,895,895,895]; % checkbox left position
    
    for s = startnum:numsurveys
        
        survmenus(s) = uicontrol(fig3,'style','popup','position',[30 760-(40*(s-1)) 270 10],...
             'string',join(cat(2,atable{:,1:3},atable{:,6:7})," : "),'userdata',s,...
             'callback',@update_checkbox);
         if rmops.Value == 1
             survmenus(s).String = survmenus(s-1).String;
         end
        survhead(s) = uicontrol(fig3,'style','text','position',[2 728-(40*(s-1)) 25 40],...
            'string',s,'foregroundcolor','b','backgroundcolor',[223 206 157]/256);
        
        % checkbox bottom position
        if mod(s,3) == 1
            pbottom = 72.5;
        elseif mod(s,3) == 2
            pbottom = 37.5;
        else
            pbottom = 2.5;
        end
            
        stringvals = char(string(survmenus(s).String{survmenus(s).Value}).split(' : '));
        sdate = stringvals(1,1:8);
        stype = strip(stringvals(2,:),' ');
        chkname = sprintf('%d: %s/%s/%s %s',s,sdate(5:6),sdate(7:8),sdate(1:4),stype);

        checkmenu(s) = uicontrol(fig,'style','checkbox','position',[pleft(s) pbottom 230 30],'Value',1,...
            'userdata',s,'backgroundcolor',[223 206 157]/256,'string',chkname,'callback',{@show_survey,s});
    end
    
elseif numsurveys < length(survmenus) % need to remove a survey menu selection
        
    currnum = length(survmenus);
    
    for d = numsurveys+1:currnum
        toDeleteS = survmenus(d); % delete survey menu
        delete(toDeleteS);
        toDeleteH = survhead(d); % delete survey head
        delete(toDeleteH);
        toDeleteC = checkmenu(d); % delete survey checkbox
        delete(toDeleteC);
    end
    survmenus = survmenus(1:numsurveys);
    survhead = survhead(1:numsurveys);
    checkmenu = checkmenu(1:numsurveys);

else % need to update survey menus to new location and checkmenu
    
    % find surveys in new area
    areanum = areamenu.Value;
    ainds = find(contains(AreaTable.SurveyArea,AreaName{areanum},...
        'IgnoreCase',true));
    atable = AreaTable(ainds,:);
    
    % just change String of survey menus
    for s = 1:numsurveys
        survmenus(s).String=join(cat(2,atable{:,1:3},atable{:,6:7})," : ");
                
        stringvals = char(string(survmenus(s).String{survmenus(s).Value}).split(' : '));
        sdate = stringvals(1,1:8);
        stype = strip(stringvals(2,:),' ');
        chkname = sprintf('%d: %s/%s/%s %s',s,sdate(5:6),sdate(7:8),sdate(1:4),stype);
        checkmenu(s).String = chkname;
    end
    
end

end

%------------------------------------------------------------------------
function update_checkbox(hObject,eventdata)
%------------------------------------------------------------------------

global survmenus mopmenu checkmenu rsurvey
    
s = hObject.UserData;

if rsurvey.Value == 1
    mopmenu.Value=1;mopmenu.String='TBD';
end

stringvals = char(string(survmenus(s).String{survmenus(s).Value}).split(' : '));
sdate = stringvals(1,1:8);stype = strip(stringvals(2,:),' ');
chkname = sprintf('%d: %s/%s/%s %s',s,sdate(5:6),sdate(7:8),sdate(1:4),stype);
checkmenu(s).String = chkname;

end

%------------------------------------------------------------------------
function plot_survey(varargin)
%------------------------------------------------------------------------

global areamenu survmenus fig2  firstmap
global aprev sprev sprev2 xyzdata survlocs rsurvey rdiff areanum

figure(fig2) % plotting figure
delete(findall(gcf,'type','annotation'))

% check if first plot
if isempty(xyzdata)
    survlocs = 1:length(survmenus);
else
    survlocs = NaN(size(survmenus)); % if zero, need to load, if not, index of location in xyzdata
end

for s = 1:length(survmenus)
    if isempty(xyzdata)
        stemp = load_XYZ(s);
        if isnan(stemp)
            return
        else
            survlocs(s) = stemp;
        end
        continue
    end
    currsurvey = split(char(survmenus(s).String(survmenus(s).Value)),' : ');
    currdate = currsurvey{1};
    currtype = currsurvey{2};
    currsmop = str2num(currsurvey{4});
    currnmop = str2num(currsurvey{5});
    
    loadedi = strfind({xyzdata.name},currdate);
    loadedi2 = strfind({xyzdata.type},currtype);
    loadedi3 = find([xyzdata.smop]==currsmop);
    loadedi4 = find([xyzdata.nmop]==currnmop);
    
    kloaded = find(not(cellfun('isempty',loadedi)));
    kloaded2 = find(not(cellfun('isempty',loadedi2)));
    
    koverlap = intersect(kloaded,kloaded2);
    koverlap = intersect(koverlap,loadedi3);
    koverlap = intersect(koverlap,loadedi4);

    if isempty(koverlap)
        stemp = load_XYZ(s);
        if isnan(stemp)
            continue
        else
            survlocs(s) = stemp;
        end
        continue
    else
        koverlap = koverlap(1); % just in case survey was loaded more than once
        survlocs(s) = koverlap;
    end
end

if rsurvey.Value == 1
    avalue = areamenu.Value;
else
    avalue = areanum;
end

% check if lidar difference map
if rdiff.Value == 1 && sprev~=survlocs(1) && sprev2~=survlocs(2)
    aprev = avalue;
    sprev = survlocs(1);
    sprev2 = survlocs(2);

    % set survey menus to just include surveys selected
    s1 = survmenus(1).Value;
    survmenus(1).Value = 1;
    survmenus(1).String = survmenus(1).String(s1);
    s2 = survmenus(2).Value;
    survmenus(2).Value = 1;
    survmenus(2).String = survmenus(2).String(s2);

    plot_diff_map
    firstmap = 0;
elseif aprev ~= avalue || sprev~=survlocs(1)
    % plot survey as a color map (only first survey...for now)
    aprev = avalue;
    sprev = survlocs(1);
    show_survey_map
end

% plot selected mop profile
show_profiles 

end

%-------------------------------------------------------------
function [xatv,yatv,zatv] = grid_data(s)
%-------------------------------------------------------------

global xyzdata

x = xyzdata(s).x;
y = xyzdata(s).y;
z = xyzdata(s).z;

[xutm, yutm, zone] = deg2utm(y,x);

XY = [xutm yutm];
DX = [1 1];
[Xi,Xc,zi,zm,si,ni,Ji,Jmax,XY0] = grid_las_data(XY,z,DX);

[XX,YY] = meshgrid([1:Jmax(1)]*DX(1)+XY0(1),[1:Jmax(2)]*DX(2)+XY0(2));
ZZ = nan(Jmax(1),Jmax(2)); % careful, read in flipped
ZZ(Ji) = zi; ZZ = ZZ'; % flip to usual orientation for matlab

zatv = ZZ(find(~isnan(ZZ)));
eatv = XX(find(~isnan(ZZ)));
natv = YY(find(~isnan(ZZ)));

% utm back to lat/lon
[yatv,xatv]=utm2deg(eatv,natv,repmat('11 S',[length(natv) 1]));

end

%-------------------------------------------------------------
function sindex = load_XYZ(s)
%-------------------------------------------------------------

global atable Mop fig2 survmenus xyzdata

% status update: loading in survey
sname = split(survmenus(s).String{survmenus(s).Value});
status = fprintf('Loading %s %s survey...\n',sname{1},sname{3});
fprintf('\n\n')

% loading status bar
waittext = sprintf('Loading %s %s survey...\n',sname{1},sname{3});
figpos = fig2.Position;
wleft = (figpos(1)+figpos(3))/2;
wbottom = (figpos(2)+figpos(4)+50)/2;
wbar = waitbar(0,'1','Name',waittext,'Position',[wleft wbottom 360 75]);

% dbox = dialog('Position',[700 400 300 80],'Name','My Dialog');

snum = survmenus(s).Value;

if strcmp(atable.SurveyType{snum},'lidar')

    if contains(sname{5},'Airborne')
            
        fdir1=atable.SurveyDate{snum};
        fdir2=strcat(atable.SouthMop{snum},'_D_',...
            atable.NorthMop{snum});

        % load survey variables
        waitbar(.1,wbar,'Accessing data...')

        fpath=strcat('/Volumes/group/LiDAR/VMZ2000_Truck/LiDAR_Airborne/',fdir1,'*',fdir2,'*/Beach_Only/*.txt');

        file = dir(fpath);

        txtfile = strcat(file.folder,'/',file.name);

        xyzdata(end+1).name = file.name(1:end-4);
        xyzdata(end).smop = str2num(atable.SouthMop{snum});
        xyzdata(end).nmop = str2num(atable.NorthMop{snum});

        waitbar(.2,wbar,'Accessing data...')
        
        % read in survey data
        formatSpec = '%f %f %f%[^\n\r]';
        fileID = fopen(txtfile,'r');
        dataArray = textscan(fileID, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'TextType', 'string', 'EmptyValue', NaN,  'ReturnOnError', false);
        fclose(fileID);
        
        waitbar(.4,wbar,'Accessing data...')

        xyzdata(end).x = dataArray{:, 1};
        xyzdata(end).y = dataArray{:, 2};
        xyzdata(end).z = dataArray{:, 3};

        clearvars filename formatSpec fileID dataArray ans;
        
    else
            
        fdir=strcat(atable.SurveyDate{snum},'_',...
            atable.SouthMop{snum},'_',...
            atable.NorthMop{snum},'_');

        % load survey variables
        waitbar(.1,wbar,'Accessing data...')

        % get path name
        fpath=strcat('/Volumes/group/LiDAR/VMZ2000_Truck/LiDAR_Processed_Level2/',fdir,'*/Beach_Only/*.tif');

        file = dir(fpath);
        if file(1).name(1) == '.'
            file = file(2);
        else
            file = file(1);
        end
        tiffile = strcat(file.folder,'/',file.name);

        xyzdata(end+1).name = file.name(1:end-4);
        xyzdata(end).smop = str2num(atable.SouthMop{snum});
        xyzdata(end).nmop = str2num(atable.NorthMop{snum});

        waitbar(.2,wbar,'Accessing data...')
        % read in survey data and bound info
        [surv,R]=geotiffread(tiffile);
        waitbar(.35,wbar,'Accessing data...')
        surv=double(surv);
        % extract data array indices with elevations
        [i,j,sinds]=find(surv > -9999);
        xyzdata(end).z=surv(surv > -9999);
        % assign utm coordinates to each elevation
        % (there may be a small offset error here, have
        %  Adam check if this is correct conversion)
        Eutm=R.XWorldLimits(1)+j;
        Nutm=R.YWorldLimits(2)-i;
        % convert utm coords to lat lons
        waitbar(.4,wbar,'Processing xyz points...')
        [xyzdata(end).y,xyzdata(end).x]=utm2deg(Eutm,Nutm,repmat('11 S',[length(Eutm) 1]));
    end
    
    xyzdata(end).type = 'lidar';
else
    fdir=strcat(atable.SurveyDate{snum},'_',...
        atable.SouthMop{snum},'_',...
        atable.NorthMop{snum},'_',...
        atable.SurveyName{snum},'_',...
        atable.SurveyType{snum});

    if atable.SurveyType{snum} == "atv"
        fdir = strcat(fdir,'_alongshore');
        stype = 'atv';
    elseif atable.SurveyType{snum} == "wheel"
        stype = 'wheel';
    else
        stype = 'jumbo';
    end

    % load survey variables
    waitbar(.15,wbar,'Accessing data...')
    % get path name, special case for TJ rivermouth
    if contains(fdir,'tjrivermouth')
        fpath = strcat('/Volumes/group/topobathy/',fdir,'/*.llzts*');
    elseif str2num(atable.SurveyDate{snum}(1:4)) > 2018
        fpath=strcat('/Volumes/group/topobathy/',fdir,'/filtered*.ll*.navd88');
        if isempty(dir(fpath))
            fpath=strcat('/Volumes/group/topobathy/',fdir,'/jumbo/filtered*.ll*.navd88');
        end
    else
        fpath=strcat('/Volumes/group/topobathy/',fdir,'/*.llz*.navd88');
    end

    file = dir(fpath);
    if isempty(file)
        sindex = NaN;
        close(wbar)
        errordlg('Survey not available.')
        return
    elseif file(1).name(1) == '.'
        file = file(2);
    else
        file = file(1);
    end
    filename = strcat(file.folder,'/',file.name);

    xyzdata(end+1).name = fdir;
    xyzdata(end).smop = str2num(atable.SouthMop{snum});
    xyzdata(end).nmop = str2num(atable.NorthMop{snum});
    
    waitbar(.25,wbar,'Accessing data...')
    
    formatSpec = '%f%f%f%f%f%[^\n\r]';
    fileID = fopen(filename,'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'TextType', 'string', 'EmptyValue', NaN,  'ReturnOnError', false);
    fclose(fileID);
    
    waitbar(.4,wbar,'Processing xyz points...')
    
    xyzdata(end).x = dataArray{:, 2};
    xyzdata(end).y = dataArray{:, 1};
    if nanmean(dataArray{3} > 100)
        xyzdata(end).z = dataArray{:, 5};
    else
        xyzdata(end).z = dataArray{:, 3};
    end
    clearvars filename formatSpec fileID dataArray fdir fpath file filename;
    
    xyzdata(end).type = stype;
end
    
% isolate mops in the survey area
amop=fliplr(xyzdata(end).smop:xyzdata(end).nmop)';
%mopnum2=ncread(ncurl2,'profileNumber');
% assign survey points to the nearest mop line based on closest
%  mop backbeach point, use survey #1 y value with cosine latitude
%  for consistent local scaling
waitbar(.5,wbar,'Calculating distances...')
[dp,imop]=pdist2([Mop.BackLon(amop)*cosd(xyzdata(1).y(1)),Mop.BackLat(amop)],...
    [xyzdata(end).x*cosd(xyzdata(1).y(1)),xyzdata(end).y],'euclidean','Smallest',1);

% get all distances from survey points to closest mop
distall = NaN(size(xyzdata(end).x));
xlen = length(xyzdata(end).x);
for d = 1:length(xyzdata(end).x)
    if mod(d,100) == 0
        waitbar(.5+(d/xlen)*.4,wbar,'Calculating distances...')
    end
    v1 = [Mop.BackLon(amop(imop(d))),Mop.BackLat(amop(imop(d))),0];
    v2 = [Mop.OffLon(amop(imop(d))),Mop.OffLat(amop(imop(d))),0];
    pt = [xyzdata(end).x(d),xyzdata(end).y(d),0];
    a = v1 - v2;
    b = pt - v2;
    dist = norm(cross(a,b)) / norm(a);
    distall(d) = dist;
end

% if jumbo or atv, points within 4.5m of mop lines (almost halfway)
if strcmp(xyzdata(end).type,'jumbo')
    kless = find(distall < 0.00027);
% if lidar, find points within 2.5m of mop lines
else
    kless = find(distall < 0.0000225);
end

waitbar(.92,wbar,'Finding mop line data...')

if strcmp(atable.SurveyType{snum},'lidar') 
    xyzdata(end).x2 = xyzdata(end).x;
    xyzdata(end).y2 = xyzdata(end).y;
    xyzdata(end).z2 = xyzdata(end).z;
    xyzdata(end).mopnum = amop(imop);
    xyzdata(end).mopnum2 = amop(imop);
    hf=double(cosd(33));
    xyzdata(end).F2 = scatteredInterpolant(double(xyzdata(end).x)*hf,...
        double(xyzdata(end).y),double(xyzdata(end).z));
else
    [xyzdata(end).x2, xyzdata(end).y2,xyzdata(end).z2] = grid_data(length(xyzdata));
    xyzdata(end).mopnum = amop(imop);
    xyzdata(end).mopnum2 = amop(imop);
    hf=double(cosd(33));
    xyzdata(end).F2 = scatteredInterpolant(double(xyzdata(end).x)*hf,...
        double(xyzdata(end).y),double(xyzdata(end).z));
end
xyzdata(end).mopnum = amop(imop);

xyzdata(end).x = xyzdata(end).x(kless);
xyzdata(end).y = xyzdata(end).y(kless);
xyzdata(end).z = xyzdata(end).z(kless);
xyzdata(end).mopnum = xyzdata(end).mopnum(kless);

% place x y z data in a scattered data class variable
%hf=double(cosd(y2(1)))% horizontal scale correction for longitude
hf=double(cosd(33));
xyzdata(end).F = scatteredInterpolant(double(xyzdata(end).x)*hf,...
    double(xyzdata(end).y),double(xyzdata(end).z));

if strcmp(atable.SurveyType{snum},'lidar')
    xyzdata(end).F2 = xyzdata(end).F;
end

sindex = length(xyzdata);

close(wbar)

end

%------------------------------------------------------------------------
function show_survey(hObject,eventdata,chkID)
%------------------------------------------------------------------------

global s1 s1i wpts H profilemenu lgd

if ~isgraphics(s1(chkID))
    return
elseif hObject.Value == 1
    if profilemenu(1).Value == 1
        set(s1(chkID),'visible','on')
    end
    if profilemenu(2).Value == 1
        set(s1i(chkID),'visible','on')
        set(wpts(chkID),'visible','on')
    end
    set(H(chkID+2),'visible','on')
else
    set(s1(chkID),'visible','off')
    set(s1i(chkID),'visible','off')
    set(wpts(chkID),'visible','off')
    set(H(chkID+2),'visible','off')
end

for l = 1:length(lgd.String)/2
    hLegendEntry = lgd.EntryContainer.NodeChildren(l);
    hLegendIconLine = hLegendEntry.Icon.Transform.Children.Children;
    hLegendIconLine.LineWidth = 4;
end

for l = (length(lgd.String)/2)+1:length(lgd.String)
    hLegendEntry = lgd.EntryContainer.NodeChildren(l);
    hLegendIconLine = hLegendEntry.Icon.Transform.Children.Children;
    hLegendIconLine.Size = 35;
end

end

%-------------------------------------------------------------
function show_survey_map
%-------------------------------------------------------------

global ax1 Mop areamenu rmops xyzdata survlocs survmenus
global AreaTable atable areanum mapscatter fig2

% get figure position
figpos = fig2.Position;
wleft = (figpos(1)+figpos(3))/2;
wbottom = figpos(2)+figpos(4)+50;
wbar = waitbar(0,'1','Name','Loading survey map...','Position',[wleft wbottom 360 75]);

if rmops.Value == 1
    anum = areanum;
else
    anum = areamenu.Value;
end
svalue = survlocs(1);

if length(survlocs) == 1
    zscaled = 1+(xyzdata(svalue).z2-min(xyzdata(svalue).z2))*10;
    
else
    zscaled = 1+(xyzdata(svalue).z-min(xyzdata(svalue).z))*10; 
end
cn = ceil(max(zscaled));                                       
cm = colormap(jet(cn));

waitbar(.2,wbar,'Computing distances...')

if(exist('ax1') > 0);delete(ax1);end;
ax1=axes(fig2,'position',[.05 .05 .4 .89]);

axes(ax1)
daspect([1 cosd(xyzdata(svalue).y(svalue)) 1]);
set(gca,'fontsize',14);grid;box on;
set(gca,'color',[.5 .5 .5]);
sdate = xyzdata(svalue).name;
sdate = sdate(1:8);
sname = strrep(atable.SurveyName{survmenus(1).Value},'_','/');
twords = sprintf('%d/%d/%d %s %s survey',...w
    str2num(sdate(5:6)),str2num(sdate(7:8)),str2num(sdate(1:4)),...
    sname,xyzdata(svalue).type);
title(twords,'fontsize',16);

% get mop range on plot
smop = min([xyzdata(svalue).smop]);
nmop = max([xyzdata(svalue).nmop]);
amop = fliplr(smop:nmop)';

hold on;
for j=1:length(amop)
    i=amop(j);
plot([Mop.BackLon(i) Mop.OffLon(i)],...
    [Mop.BackLat(i) Mop.OffLat(i)],'w-');
plot([Mop.BackLon(i) Mop.OffLon(i)],...
    [Mop.BackLat(i) Mop.OffLat(i)],'k.',...
    'markersize',15);
end

xlims = xlim;
ylims = ylim;
% label every 3rd MOP line
for j=1:3:length(amop)
    waitbar(.2+(j/length(amop))*0.4,wbar,'Labeling MOPs...')
    i=amop(j);
mlabel = text(Mop.OffLon(i),Mop.OffLat(i),Mop.Name(i),'horizontalalign','right',...
    'rotation',270-Mop.Normal(i),'color','c','fontweight','bold',...
    'fontsize',16,'clipping','on');

set(ax1,'Clipping','on','ClippingStyle','rectangle')

end

waitbar(.8,wbar,'Plotting survey coverage...')

if length(survlocs) == 1
    mapscatter = scatter(xyzdata(svalue).x2, xyzdata(svalue).y2,18,xyzdata(svalue).z2,'o','filled');
    kgood = find(isoutlier(xyzdata(svalue).z2,'grubbs')==0);
    c1=colorbar('location','southoutside');set(gca,'clim',[min(xyzdata(svalue).z2(kgood)) max(xyzdata(svalue).z2(kgood))]);
else
    mapscatter = scatter(xyzdata(svalue).x, xyzdata(svalue).y,18,xyzdata(svalue).z,'o','filled');
    c1=colorbar('location','southoutside');set(gca,'clim',[min(xyzdata(svalue).z) max(xyzdata(svalue).z)]);
end
c1.Label.String = 'Elev (m, NAVD88)';c1.Label.FontSize = 14;

zoom on;
waitbar(.9,wbar,'Importing google maps...')
plot_google_map('MapType', 'satellite','Alpha', 1,'axis',ax1)

close(wbar)

end

%-------------------------------------------------------------
function plot_diff_map
%-------------------------------------------------------------

global ax1 xyzdata survlocs Mop mopmenu diffz koverlap1 koverlap2 fig2

% get figure position
figpos = fig2.Position;
wleft = (figpos(1)+figpos(3))/2;
wbottom = figpos(2)+figpos(4)+50;
wbar = waitbar(0,'1','Name','Plotting difference map...','Position',[wleft wbottom 360 75]);

x1 = xyzdata(survlocs(1)).x2;
y1 = xyzdata(survlocs(1)).y2;
z1 = xyzdata(survlocs(1)).z2;
x2 = xyzdata(survlocs(2)).x2;
y2 = xyzdata(survlocs(2)).y2;
z2 = xyzdata(survlocs(2)).z2;

mop1 = xyzdata(survlocs(1)).mopnum2;
mop2 = xyzdata(survlocs(2)).mopnum2;

waitbar(.15,wbar,'Finding overlapping data...')

% find intersection of (x,y) pairs of two surveys
[vals, koverlap1, koverlap2] = intersect(x1+y1,x2+y2);

% new struct with only overlapping points
xyzdata2 = struct('x',{},'y',{},'z',{},'mopnum',{});

xyzdata2(1).x = x1(koverlap1);
xyzdata2(1).y = y1(koverlap1);
xyzdata2(1).z = z1(koverlap1);
xyzdata2(1).mopnum = mop1(koverlap1);

xyzdata2(2).x = x2(koverlap2);
xyzdata2(2).y = y2(koverlap2);
xyzdata2(2).z = z2(koverlap2);
xyzdata2(2).mopnum = mop2(koverlap2);

waitbar(.3,wbar,'Finding overlapping data...')

% get difference in elevation values
diffz = xyzdata2(1).z-xyzdata2(2).z;

if(exist('ax1') > 0);delete(ax1);end;
ax1=axes(fig2,'position',[.05 .05 .4 .89]);

waitbar(.5,wbar,'Plotting...')

daspect(ax1,[1 cosd(xyzdata2(1).y(1)) 1]);
set(ax1,'fontsize',14);grid;box on;
set(ax1,'color',[.5 .5 .5]);

sdate = xyzdata(survlocs(1)).name;
sdate = sdate(1:8);
sdate2 = xyzdata(survlocs(2)).name;
sdate2 = sdate2(1:8);
figtitle = sprintf('%d/%d/%d - %d/%d/%d LiDAR Difference Plot',...
    str2num(sdate(5:6)),str2num(sdate(7:8)),str2num(sdate(1:4)),...
    str2num(sdate2(5:6)),str2num(sdate2(7:8)),str2num(sdate2(1:4)));
title(ax1,figtitle,'fontsize',16);

% get mop range on plot
smop = min([xyzdata2(1).mopnum;xyzdata2(2).mopnum]);
nmop = max([xyzdata2(1).mopnum;xyzdata2(2).mopnum]);
amop = fliplr(smop:nmop)';

hold(ax1,'on');
for j=1:length(amop)
    i=amop(j);
plot(ax1,[Mop.BackLon(i) Mop.OffLon(i)],...
    [Mop.BackLat(i) Mop.OffLat(i)],'w-');
plot(ax1,[Mop.BackLon(i) Mop.OffLon(i)],...
    [Mop.BackLat(i) Mop.OffLat(i)],'k.',...
    'markersize',15);
end

xlims = xlim;
ylims = ylim;
% label every 3rd MOP line
moplen = length(amop);
for j=1:3:length(amop)
    if mod(j,10) == 0
        waitbar(.5+(j/moplen)*0.3,wbar,'Plotting...')
    end
    i=amop(j);
    mlabel = text(ax1,Mop.OffLon(i),Mop.OffLat(i),Mop.Name(i),'horizontalalign','right',...
        'rotation',270-Mop.Normal(i),'color','c','fontweight','bold',...
        'fontsize',16,'clipping','on');

    set(ax1,'Clipping','on','ClippingStyle','rectangle')
end

waitbar(.8,wbar,'Plotting...')

scatter(ax1,xyzdata2(1).x,xyzdata2(1).y,18,diffz,'o','filled')
c1=colorbar(ax1,'location','southoutside');
colormap(flipud(colormap))
% TODO: Figure out better way!!
kgood = find(isoutlier(diffz,'grubbs')==0);
set(ax1,'clim',[min(diffz(kgood)) max(diffz(kgood))]);
c1.Label.String = 'Elev (m, NAVD88)';c1.Label.FontSize = 14;

zoom on;
plot_google_map('MapType', 'satellite','Alpha', 1,'axis',ax1)

waitbar(.9,wbar,'Plotting...')

% update mops to current survey mops
currmops = flipud(amop);
mopstrings = flipud(split(sprintf('D%04d ',currmops),' '));
currvalue = find(string(mopstrings) == string(mopmenu.String(mopmenu.Value)));
mopmenu.Value = currvalue-1;
mopmenu.String = mopstrings(2:end);

close(wbar)

end

%------------------------------------------------------------------------
function change_profile(varargin)
%------------------------------------------------------------------------

global profilemenu checkmenu s1 s1i wpts lgd

for s = 1:length(checkmenu)
    if checkmenu(s).Value == 0 || ~isgraphics(s1(s))
        continue
    else
        if profilemenu(1).Value == 1 % show points
            set(s1(s),'visible','on')
        end
        if profilemenu(1).Value == 0 % remove points
            set(s1(s),'visible','off')
        end
        if profilemenu(2).Value == 1 % show interpolated profiles
            set(s1i(s),'visible','on')
            set(wpts(s),'visible','on')
        end
        if profilemenu(2).Value == 0 % remove interpolated profiles
            set(s1i(s),'visible','off')
            set(wpts(s),'visible','off')
        end
    end
end

for l = 1:length(lgd.String)/2
    hLegendEntry = lgd.EntryContainer.NodeChildren(l);
    hLegendIconLine = hLegendEntry.Icon.Transform.Children.Children;
    hLegendIconLine.LineWidth = 4;
end

for l = (length(lgd.String)/2)+1:length(lgd.String)
    hLegendEntry = lgd.EntryContainer.NodeChildren(l);
    hLegendIconLine = hLegendEntry.Icon.Transform.Children.Children;
    hLegendIconLine.Size = 35;
end

end

function show_profiles
%------------------------------------------------------------------------

global fig2 ax1 ax2 H Mop amop mopp rsurvey areanum rmops
global checkmenu areamenu survmenus mopmenu profilemenu
global AreaTable xyzdata d s1 s1i wpts survlocs atable lgd

% get figure position
figpos = fig2.Position;
wleft = (figpos(1)+figpos(3))/2;
wbottom = figpos(2)+figpos(4)+50;
wbar = waitbar(0,'1','Name','Plotting survey profiles...','Position',[wleft wbottom 360 75]);

waitbar(.1,wbar,'Setting up plot...')


colors = [211, 47, 47;251, 192, 45;0, 172, 193;120, 144, 156;255, 111, 0;...
        56, 142, 60;175, 180, 43;106, 27, 154;240, 98, 146;149, 117, 205;...
        30, 136, 229;38, 166, 154;156, 204, 101;48, 63, 159;121, 85, 72]/255;

if rsurvey.Value == 1
    AreaNum=areamenu.Value;
else
    AreaNum=areanum;
end

% create subset of xyzdata with current surveys
xyzcurr = xyzdata(survlocs);

% create temp graphics objects array for interpolated profile
s1 = gobjects(length(survmenus),1);
s1i = gobjects(length(survmenus),1);

axes(ax1);
% temp graphics objects highlighting current MOP profile on map
if(exist('H'))
    delete(H)
end
if(exist('ax2'))
    delete(ax2)
end

% isolate mops in the survey area if choose by survey
if rsurvey.Value == 1 && ischar(mopmenu.String) % when mop is 'TBD'
    % isolate mops in the survey area, get max/min mop of both surveys
    % pick median of plotted survey
    smop = min([xyzcurr.smop]);
    nmop = max([xyzcurr.nmop]);
    amop = fliplr(smop:nmop)';
    mopmenu.String=Mop.Name(amop);
    mopp=round((xyzcurr(1).smop+xyzcurr(1).nmop)/2);
    mopmenu.Value=find(amop == mopp);
else
    mopp = str2num(mopmenu.String{mopmenu.Value}(2:end));
end

waitbar(.15,wbar,'Finding overlapping data...')

% check if any survey overlap at all
% TODO: need to make applicable to all surveys, not just 1 and 2
if length(survlocs) > 1
    mopoverlap = intersect(xyzcurr(1).mopnum,xyzcurr(2).mopnum);
    if isempty(mopoverlap) % no survey overlap
        err = errordlg(sprintf('Warning: Surveys have no\noverlapping data.'),'Warning!');
            set(err,'position',[700 400 300 100]);
            errtext = findobj(err,'Type','Text');
            errtext.FontSize = 16;
            errtext.Margin = 10;
        close(wbar)
        return
    end
end

waitbar(.3,wbar,'Plotting mop lines...')

axes(ax1);
H(1)=plot([Mop.BackLon(mopp) Mop.OffLon(mopp)],...
    [Mop.BackLat(mopp) Mop.OffLat(mopp)],'m-');
H(2)=text(Mop.OffLon(mopp),Mop.OffLat(mopp),[Mop.Name(mopp)],...
    'horizontalalign','right',...
    'rotation',270-Mop.Normal(mopp),'color','m','fontweight','bold',...
    'fontsize',16,'clipping','on');

% keep track of what to put in legend
legendinds = [];
lgdnames = cell(length(survmenus),1);

ax2=axes('position',[.55 .15 .4 .79]);
ax2.ColorOrderIndex = 1;

waitbar(.5,wbar,'Plotting transects...')

cctr = 1;
for s = 1:length(survmenus)
    
    waitbar(.5+(s/length(survmenus))*0.4,wbar,sprintf('Plotting profile %d...',s))
    
    lname = split(survmenus(s).String{survmenus(s).Value});
    % if survey has already been plotted once, don't plot again
    if ~isempty([lgdnames{1:s}]) && contains([lgdnames{1:s}],[lname{1},' ',lname{3}])
        lgdnames{s}=[lname{1},' ',lname{3}];
        if s == length(survmenus)
            axes(ax2)
            yl=get(ax2,'ylim');set(ax2,'ylim',[yl(1) 0.1*diff(yl)+yl(2)]);
            
            xl=get(ax2,'xlim');p1=plot(xl,[.832-0.06 .832-0.06],'k--');
            text(xl(1),.77,'MSL','fontsize',14,'fontweight','bold');
            xl=get(ax2,'xlim');p2=plot(xl,[1.62-0.06 1.62-0.06],'k--');
            text(xl(1),1.56,'MHHW','fontsize',14,'fontweight','bold');
            xl=get(ax2,'xlim');p3=plot(xl,[-0.06 -0.06],'k--');
            text(xl(1),-0.07,'MLLW','fontsize',14,'fontweight','bold');
            set(gca,'fontsize',14);grid on;box on;
            yl=get(ax2,'ylim');
            if(diff(yl) > 5);yticks(ax2,[ceil(yl(1)):1:floor(yl(2))]);end
            xlabel('Crosshore Distance (m) from MOP Backbeach Point');
            ylabel('Elevation (m, NAVD88)');title(Mop.Name(mopp),'fontsize',16);
            
            zoom on;
            
            set(gca,'clim',[0 50]);
            set(gca,'xdir','reverse');grid on;box on;hold on;
        end
        continue
    end
    
    lgdnames{s}=[lname{1},' ',lname{3}];
    
    % check legend
%     if s > 1
%         axes(ax2)
%         noplot = find(contains(lgd.String,lgdnames{s}));
%         if noplot ~= 0 & s == length(survmenus)
%             yl=get(ax2,'ylim');set(ax2,'ylim',[yl(1) 0.1*diff(yl)+yl(2)]);
%             
%             xl=get(ax2,'xlim');p1=plot(xl,[.832-0.06 .832-0.06],'k--');
%             text(xl(1),.825,'MSL','fontsize',14,'fontweight','bold');
%             xl=get(ax2,'xlim');p2=plot(xl,[1.62-0.06 1.62-0.06],'k--');
%             text(xl(1),1.58,'MHHW','fontsize',14,'fontweight','bold');
%             xl=get(ax2,'xlim');p3=plot(xl,[-0.06 -0.06],'k--');
%             text(xl(1),-0.05,'MLLW','fontsize',14,'fontweight','bold');
%             set(gca,'fontsize',14);grid on;box on;
%             yl=get(ax2,'ylim');
%             if(diff(yl) > 5);yticks(ax2,[ceil(yl(1)):1:floor(yl(2))]);end
%             xlabel('Crosshore Distance (m) from MOP Backbeach Point');
%             ylabel('Elevation (m, NAVD88)');title(Mop.Name(mopp),'fontsize',16);
% 
%             zoom on;
%             
%             s1(s) = s1(noplot(s));
%             wpts(s) = wpts(noplot(s));
%             s1i(s) = s1i(noplot(s));
% 
%             continue
%             
%         elseif noplot ~= 0
%             s1(s) = s1(noplot(s));
%             wpts(s) = wpts(noplot(s));
%             s1i(s) = s1i(noplot(s));
%             continue
%         end
%     end
    
    m=find(xyzcurr(s).mopnum == mopp);
    
    % add to legend
    legendinds = [legendinds;s];

    if(~isempty(m))
        % longitude distance adjustment for transect projection
        hf=double(cosd(33));
        % define mop line to project survey points onto
        mopvector=[Mop.OffLon(mopp)*hf,Mop.OffLat(mopp);...
            Mop.BackLon(mopp)*hf,Mop.BackLat(mopp)];
        
        % create projected survey point array using function proj_points
        pxy=ones(length(m),2);
        for n=1:length(m)
            p1=proj_points(mopvector,[xyzcurr(s).x(m(n))*hf,xyzcurr(s).y(m(n))]);
            pxy(n,1)=p1(1)/hf;
            pxy(n,2)=p1(2);
        end
        % calculate distance (m) projected points are from original locations
        dp=distance(xyzcurr(s).y(m),xyzcurr(s).x(m),pxy(:,2),pxy(:,1));dp=dp*111139;

        % calculate projected point distance along MOP transect,
        % relative to back beach mop point
        [d,az]=distance(Mop.BackLat(mopp)*ones(length(m),1),...
            Mop.BackLon(mopp)*ones(length(m),1),...
            pxy(:,2),pxy(:,1));
        d=d*111139; %distance along mop line from MOP back beach pt in meters
        d(az < 135)=-d(az < 135); % flip distance sign if point behind backbeach pt
        
        % make transect profile plot of projected points
        axes(ax2)
        dp(dp > 50)=50;
        dp(dp < 1) = 1;
        cn = ceil(max(50));
        
        if rsurvey.Value == 0 && rmops.Value == 0
            cm = colormap(flipud(jet(cn)));
        else
            cm = colormap(jet(cn));
        end
        
        s1(s)=scatter(d, xyzcurr(s).z(m),[], cm(ceil(dp),:), '.','MarkerFaceColor','none','MarkerEdgeColor','none');
        hold on
        
        if s == length(survmenus)
            yl=get(ax2,'ylim');set(ax2,'ylim',[yl(1) 0.1*diff(yl)+yl(2)]);
            
            xl=get(ax2,'xlim');p1=plot(xl,[.832-0.06 .832-0.06],'k--');
            text(xl(1),.825,'MSL','fontsize',14,'fontweight','bold');
            xl=get(ax2,'xlim');p2=plot(xl,[1.62-0.06 1.62-0.06],'k--');
            text(xl(1),1.58,'MHHW','fontsize',14,'fontweight','bold');
            xl=get(ax2,'xlim');p3=plot(xl,[-0.06 -0.06],'k--');
            text(xl(1),-0.05,'MLLW','fontsize',14,'fontweight','bold');
            set(gca,'fontsize',14);grid on;box on;
            yl=get(ax2,'ylim');
            if(diff(yl) > 5);yticks(ax2,[ceil(yl(1)):1:floor(yl(2))]);end
            xlabel('Crosshore Distance (m) from MOP Backbeach Point');
            ylabel('Elevation (m, NAVD88)');title(Mop.Name(mopp),'fontsize',16);

            zoom on;
            
            set(gca,'clim',[0 50]);
            set(gca,'xdir','reverse');grid on;box on;hold on;
        else
            set(gca,'clim',[0 50]);
            set(gca,'xdir','reverse');grid on;box on;hold on;
        end

        %----- interpolated mop line profile -------
        [dmin,imin]=min(d);[dmax,imax]=max(d);
        % get round length in meters of mop line that has data
        n=round(abs(dmax-dmin));
        % make a vector of mop line points approx 1 meter apart
        ix=linspace(pxy(imin,1),pxy(imax,1),n);
        iy=linspace(pxy(imin,2),pxy(imax,2),n);
        
        % place x y z data in a scattered data class variable
        %hf=double(cosd(y(1)));% horizontal scale correction for longitude
        hf=double(cosd(33));
        %F = scatteredInterpolant(double(x)*hf,double(y),double(z));
        
        % get interpolated z values
        iz=xyzcurr(s).F(ix*hf,iy);
        
        % convert interpolated ix iy locations back to distance along the mop line
        % relative to the back beach point
        [di,az]=distance(Mop.BackLat(mopp)*ones(length(iy),1),...
            Mop.BackLon(mopp)*ones(length(iy),1),...
            iy',ix');
        di=di*111139; %distance along mop line from MOP back beach pt in meters
        di(az < 135)=-di(az < 135); % flip distance sign if point behind backbeach pt
        
        axes(ax2)
        wpts(s)=plot(di,iz,'w-','linewidth',5);
        if mod(s,3) == 0
            s1i(s)=plot(di,iz,'--','Color',colors(cctr,:),'linewidth',2);
        elseif mod(s,3) == 2
            s1i(s)=plot(di,iz,'-.','Color',colors(cctr,:),'linewidth',2);
        else
            s1i(s)=plot(di,iz,'-','Color',colors(cctr,:),'linewidth',2);                
        end
        s1(s)=scatter(d, xyzcurr(s).z(m),'.','MarkerFaceColor',colors(cctr,:),'MarkerEdgeColor',colors(cctr,:));
        
        % highlighted project survey points on survey map
        axes(ax1);
        H(s+2)=plot(xyzcurr(s).x(m),xyzcurr(s).y(m),'.','Color',colors(cctr,:),'markersize',5);
        cctr = cctr+1;
           
        if profilemenu(1).Value == 0
            set(s1(s),'visible','off')
        elseif profilemenu(2).Value == 0
            set(s1i(s),'visible','off')
        end

        % check if survey box is checked
        if checkmenu(s).Value == 0
            set(s1(s),'visible','off')
            set(s1i(s),'visible','off')
            set(wpts(s),'visible','off')
            set(H(s+2),'visible','off')
        end

        legend(vertcat(s1(legendinds),s1i(legendinds)),[lgdnames(legendinds),lgdnames(legendinds)],'location','northwest');

    else
        axes(ax1)
        % print error message, first survey has no data for mop #
        err = errordlg(sprintf('Warning: %s has no\ndata associated with MOP #%d',...
            lgdnames{s},mopp),'Warning!');
        set(err,'position',[700 400 300 100]);
        errtext = findobj(err,'Type','Text');
        errtext.FontSize = 16;
        errtext.Margin = 10;
        waitfor(err);
        legendinds = legendinds(1:end-1);
        
        if s == length(survmenus)
            axes(ax2);
            yl=get(ax2,'ylim');set(ax2,'ylim',[yl(1) 0.1*diff(yl)+yl(2)]);
            
            xl=get(ax2,'xlim');p1=plot(xl,[.832-0.06 .832-0.06],'k--');
            text(xl(1),.825,'MSL','fontsize',14,'fontweight','bold');
            xl=get(ax2,'xlim');p2=plot(xl,[1.62-0.06 1.62-0.06],'k--');
            text(xl(1),1.58,'MHHW','fontsize',14,'fontweight','bold');
            xl=get(ax2,'xlim');p3=plot(xl,[-0.06 -0.06],'k--');
            text(xl(1),-0.05,'MLLW','fontsize',14,'fontweight','bold');
            set(gca,'fontsize',14);grid on;box on;
            yl=get(ax2,'ylim');
            if(diff(yl) > 5);yticks(ax2,[ceil(yl(1)):1:floor(yl(2))]);end
            xlabel('Crosshore Distance (m) from MOP Backbeach Point');
            ylabel('Elevation (m, NAVD88)');title(Mop.Name(mopp),'fontsize',16);

            zoom on;
            close(wbar)

            return
        end
        
    end
end

waitbar(.95,wbar,'Adding legend...')
lgd = legend(vertcat(s1(legendinds),s1i(legendinds)),[lgdnames(legendinds),lgdnames(legendinds)],'location','northwest');

change_profile()

close(wbar)

end

%-----------------------------------------------------------------
function [ProjPoint] = proj_points(vector, q)
%-----------------------------------------------------------------

p0 = vector(1,:);
p1 = vector(2,:);
a = [-q(1)*(p1(1)-p0(1)) - q(2)*(p1(2)-p0(2)); ...
    -p0(2)*(p1(1)-p0(1)) + p0(1)*(p1(2)-p0(2))]; 
b = [p1(1) - p0(1), p1(2) - p0(2);...
    p0(2) - p1(2), p1(1) - p0(1)];
ProjPoint = -(b\a);

end

%----------------------Plot Google Map----------------------------

% Coordinate transformation functions

function [lon,lat] = metersToLatLon(x,y)
% Converts XY point from Spherical Mercator EPSG:900913 to lat/lon in WGS84 Datum
originShift = 2 * pi * 6378137 / 2.0; % 20037508.342789244
lon = (x ./ originShift) * 180;
lat = (y ./ originShift) * 180;
lat = 180 / pi * (2 * atan( exp( lat * pi / 180)) - pi / 2);
end

function [x,y] = latLonToMeters(lat, lon )
% Converts given lat/lon in WGS84 Datum to XY in Spherical Mercator EPSG:900913"
originShift = 2 * pi * 6378137 / 2.0; % 20037508.342789244
x = lon * originShift / 180;
y = log(tan((90 + lat) * pi / 360 )) / (pi / 180);
y = y * originShift / 180;
end

function ZI = myTurboInterp2(X,Y,Z,XI,YI)
% An extremely fast nearest neighbour 2D interpolation, assuming both input
% and output grids consist only of squares, meaning:
% - uniform X for each column
% - uniform Y for each row
XI = XI(1,:);
X = X(1,:);
YI = YI(:,1);
Y = Y(:,1);

xiPos = nan*ones(size(XI));
xLen = length(X);
yiPos = nan*ones(size(YI));
yLen = length(Y);
% find x conversion
xPos = 1;
for idx = 1:length(xiPos)
    if XI(idx) >= X(1) && XI(idx) <= X(end)
        while xPos < xLen && X(xPos+1)<XI(idx)
            xPos = xPos + 1;
        end
        diffs = abs(X(xPos:xPos+1)-XI(idx));
        if diffs(1) < diffs(2)
            xiPos(idx) = xPos;
        else
            xiPos(idx) = xPos + 1;
        end
    end
end
% find y conversion
yPos = 1;
for idx = 1:length(yiPos)
    if YI(idx) <= Y(1) && YI(idx) >= Y(end)
        while yPos < yLen && Y(yPos+1)>YI(idx)
            yPos = yPos + 1;
        end
        diffs = abs(Y(yPos:yPos+1)-YI(idx));
        if diffs(1) < diffs(2)
            yiPos(idx) = yPos;
        else
            yiPos(idx) = yPos + 1;
        end
    end
end
ZI = Z(yiPos,xiPos,:);
end

function update_google_map(obj,evd)
% callback function for auto-refresh
drawnow;
try
    axHandle = evd.Axes;
catch ex
    % Event doesn't contain the correct axes. Panic!
    axHandle = gca;
end
ud = get(axHandle, 'UserData');
if isfield(ud, 'gmap_params')
    params = ud.gmap_params;
    plot_google_map(params{:});
end
end

function update_google_map_fig(obj,evd)
% callback function for auto-refresh
drawnow;
axes_objs = findobj(get(gcf,'children'),'type','axes');
for idx = 1:length(axes_objs)
    if ~isempty(findobj(get(axes_objs(idx),'children'),'tag','gmap'));
        ud = get(axes_objs(idx), 'UserData');
        if isfield(ud, 'gmap_params')
            params = ud.gmap_params;
        else
            params = {};
        end
        
        % Add axes to inputs if needed
        if ~sum(strcmpi(params, 'Axis'))
            params = [params, {'Axis', axes_objs(idx)}];
        end
        plot_google_map(params{:});
    end
end
end

function cleanupFunc(h)
ud = get(h, 'UserData');
if isstruct(ud) && isfield(ud, 'gmap_params')
    ud = rmfield(ud, 'gmap_params');
    set(h, 'UserData', ud);
end
end

function varargout = plot_google_map(varargin)
% function h = plot_google_map(varargin)
% Plots a google map on the current axes using the Google Static Maps API
%
% USAGE:
% h = plot_google_map(Property, Value,...)
% Plots the map on the given axes. Used also if no output is specified
%
% Or:
% [lonVec latVec imag] = plot_google_map(Property, Value,...)
% Returns the map without plotting it
%
% PROPERTIES:
%    Axis           - Axis handle. If not given, gca is used.
%    Height (640)   - Height of the image in pixels (max 640)
%    Width  (640)   - Width of the image in pixels (max 640)
%    Scale (2)      - (1/2) Resolution scale factor. Using Scale=2 will
%                     double the resulotion of the downloaded image (up
%                     to 1280x1280) and will result in finer rendering,
%                     but processing time will be longer.
%    Resize (1)     - (recommended 1-2) Resolution upsampling factor. 
%                     Increases image resolution using imresize(). This results
%                     in a finer image but it needs the image processing
%                     toolbox and processing time will be longer.
%    MapType        - ('roadmap') Type of map to return. Any of [roadmap, 
%                     satellite, terrain, hybrid]. See the Google Maps API for
%                     more information. 
%    Alpha (1)      - (0-1) Transparency level of the map (0 is fully
%                     transparent). While the map is always moved to the
%                     bottom of the plot (i.e. will not hide previously
%                     drawn items), this can be useful in order to increase
%                     readability if many colors are plotted 
%                     (using SCATTER for example).
%    ShowLabels (1) - (0/1) Controls whether to display city/street textual labels on the map
%    Style          - (string) A style configuration string. See:
%                     https://developers.google.com/maps/documentation/static-maps/?csw=1#StyledMaps
%                     http://instrument.github.io/styled-maps-wizard/
%    Language       - (string) A 2 letter ISO 639-1 language code for displaying labels in a 
%                     local language instead of English (where available).
%                     For example, for Chinese use:
%                     plot_google_map('language','zh')
%                     For the list of codes, see:
%                     http://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
%    Marker         - The marker argument is a text string with fields
%                     conforming to the Google Maps API. The
%                     following are valid examples:
%                     '43.0738740,-70.713993' (default midsize orange marker)
%                     '43.0738740,-70.713993,blue' (midsize blue marker)
%                     '43.0738740,-70.713993,yellowa' (midsize yellow
%                     marker with label "A")
%                     '43.0738740,-70.713993,tinyredb' (tiny red marker
%                     with label "B")
%    Refresh (1)    - (0/1) defines whether to automatically refresh the
%                     map upon zoom/pan action on the figure.
%    AutoAxis (1)   - (0/1) defines whether to automatically adjust the axis
%                     of the plot to avoid the map being stretched.
%                     This will adjust the span to be correct
%                     according to the shape of the map axes.
%    MapScale (0)  - (0/1) defines wheteher to add a scale indicator to
%                     the map.
%    ScaleWidth (0.25) - (0.1-0.9) defines the max width of the scale
%                     indicator relative to the map width.
%    ScaleLocation (sw) - (ne, n, se, s, sw, nw) defines the location of
%                     scale indicator on the map.
%    ScaleUnits (si) - (si/imp) changes the scale indicator units between 
%                     SI and imperial units.
%    FigureResizeUpdate (1) - (0/1) defines whether to automatically refresh the
%                     map upon resizing the figure. This will ensure map
%                     isn't stretched after figure resize.
%    APIKey         - (string) set your own API key which you obtained from Google: 
%                     http://developers.google.com/maps/documentation/staticmaps/#api_key
%                     This will enable up to 25,000 map requests per day, 
%                     compared to a few hundred requests without a key. 
%                     To set the key, use:
%                     plot_google_map('APIKey','SomeLongStringObtaindFromGoogle')
%                     You need to do this only once to set the key.
%                     To disable the use of a key, use:
%                     plot_google_map('APIKey','')
%
% OUTPUT:
%    h              - Handle to the plotted map
%
%    lonVect        - Vector of Longidute coordinates (WGS84) of the image 
%    latVect        - Vector of Latidute coordinates (WGS84) of the image 
%    imag           - Image matrix (height,width,3) of the map
%
% EXAMPLE - plot a map showing some capitals in Europe:
%    lat = [48.8708   51.5188   41.9260   40.4312   52.523   37.982];
%    lon = [2.4131    -0.1300    12.4951   -3.6788    13.415   23.715];
%    plot(lon, lat, '.r', 'MarkerSize', 20)
%    plot_google_map('MapScale', 1)
%
% References:
%  http://www.mathworks.com/matlabcentral/fileexchange/24113
%  http://www.maptiler.org/google-maps-coordinates-tile-bounds-projection/
%  http://developers.google.com/maps/documentation/staticmaps/
%  https://www.mathworks.com/matlabcentral/fileexchange/33545-automatic-map-scale-generation
%
% Acknowledgements:
%  Val Schmidt for the submission of get_google_map.m
%  Jonathan Sullivan for the submission of makescale.m
%
% Author:
%  Zohar Bar-Yehuda
%
% Version 2.0 - 08/04/2018
%       - Add an option to show a map scale
%       - Several bugfixes
% Version 1.8 - 25/04/2016 - By Hannes Diethelm
%       - Add resize parameter to resize image using imresize()
%       - Fix scale parameter
% Version 1.7 - 14/04/2016
%       - Add custom style support
% Version 1.6 - 12/11/2015
%       - Use system temp folder for writing image files (with fallback to current dir if missing write permissions)
% Version 1.5 - 20/11/2014
%       - Support for MATLAB R2014b
%       - several fixes for complex layouts: several maps in one figure, 
%         map inside a panel, specifying axis handle as input (thanks to Luke Plausin)
% Version 1.4 - 25/03/2014
%       - Added the language parameter for showing labels in a local language
%       - Display the URL on error to allow easier debugging of API errors
% Version 1.3 - 06/10/2013
%       - Improved functionality of AutoAxis, which now handles any shape of map axes. 
%         Now also updates the extent of the map if the figure is resized.
%       - Added the showLabels parameter which allows hiding the textual labels on the map.
% Version 1.2 - 16/06/2012
%       - Support use of the "scale=2" parameter by default for finer rendering (set scale=1 if too slow).
%       - Auto-adjust axis extent so the map isn't stretched.
%       - Set and use an API key which enables a much higher usage volume per day.
% Version 1.1 - 25/08/2011

persistent apiKey useTemp
apiKey = 'AIzaSyAV-Ny2EOqUTl5ZMpsTMTfOntlqXdDIuFo';

if isempty(useTemp)
    % first run, check if we have wrtie access to the temp folder
    try 
        tempfilename = tempname;
        fid = fopen(tempfilename, 'w');
        if fid > 0
            fclose(fid);
            useTemp = true;
            delete(tempfilename);
        else
            % Don't have write access to temp folder or it doesn't exist, fallback to current dir
            useTemp = false;
        end
    catch
        % in case tempname fails for some reason
        useTemp = false;
    end
end

hold on

% Default parametrs
axHandle = gca;
set(axHandle, 'Layer','top'); % Put axis on top of image, so it doesn't hide the axis lines and ticks
height = 640;
width = 640;
scale = 2;
resize = 1;
maptype = 'roadmap';
alphaData = 1;
autoRefresh = 1;
figureResizeUpdate = 1;
autoAxis = 1;
showLabels = 1;
language = '';
markeridx = 1;
markerlist = {};
style = '';
mapScale = 0;
scaleWidth = 0.25;
scaleLocation = 'se';
scaleUnits = 'si';

% Handle input arguments
if nargin >= 2
    for idx = 1:2:length(varargin)
        switch lower(varargin{idx})
            case 'axis'
                axHandle = varargin{idx+1};
            case 'height'
                height = varargin{idx+1};
            case 'width'
                width = varargin{idx+1};
            case 'scale'
                scale = round(varargin{idx+1});
                if scale < 1 || scale > 2
                    error('Scale must be 1 or 2');
                end
            case 'resize'
                resize = varargin{idx+1};
            case 'maptype'
                maptype = varargin{idx+1};
            case 'alpha'
                alphaData = varargin{idx+1};
            case 'refresh'
                autoRefresh = varargin{idx+1};
            case 'showlabels'
                showLabels = varargin{idx+1};
            case 'figureresizeupdate'
                figureResizeUpdate = varargin{idx+1};
            case 'language'
                language = varargin{idx+1};
            case 'marker'
                markerlist{markeridx} = varargin{idx+1};
                markeridx = markeridx + 1;
            case 'autoaxis'
                autoAxis = varargin{idx+1};
            case 'apikey'
                apiKey = varargin{idx+1}; % set new key
                % save key to file
                funcFile = which('plot_google_map.m');
                pth = fileparts(funcFile);
                keyFile = fullfile(pth,'api_key.mat');
                save(keyFile,'apiKey')
            case 'style'
                style = varargin{idx+1};
            case 'mapscale'
                mapScale = varargin{idx+1};
            case 'scalewidth'
                scaleWidth = varargin{idx+1};
            case 'scalelocation'
                scaleLocation = varargin{idx+1};
            case 'scaleunits'
                scaleUnits = varargin{idx+1};
            otherwise
                error(['Unrecognized variable: ' varargin{idx}])
        end
    end
end
if height > 640
    height = 640;
end
if width > 640
    width = 640;
end

% Store paramters in axis handle (for auto refresh callbacks)
ud = get(axHandle, 'UserData');
if isempty(ud)
    % explicitly set as struct to avoid warnings
    ud = struct;
end
ud.gmap_params = varargin;
set(axHandle, 'UserData', ud);

curAxis = axis(axHandle);
if max(abs(curAxis)) > 500 || curAxis(3) > 90 || curAxis(4) < -90
    warning('Axis limits are not reasonable for WGS1984, ignoring. Please make sure your plotted data in WGS1984 coordinates,')
    return;
end    

% Enforce Latitude constraints of EPSG:900913 
if curAxis(3) < -85
    curAxis(3) = -85;
end
if curAxis(4) > 85
    curAxis(4) = 85;
end
% Enforce longitude constrains
if curAxis(1) < -180
    curAxis(1) = -180;
end
if curAxis(1) > 180
    curAxis(1) = 0;
end
if curAxis(2) > 180
    curAxis(2) = 180;
end
if curAxis(2) < -180
    curAxis(2) = 0;
end

if isequal(curAxis,[0 1 0 1]) % probably an empty figure
    % display world map
    curAxis = [-200 200 -85 85];
    axis(curAxis)
end


if autoAxis
    % adjust current axis limit to avoid strectched maps
    [xExtent,yExtent] = latLonToMeters(curAxis(3:4), curAxis(1:2) );
    xExtent = diff(xExtent); % just the size of the span
    yExtent = diff(yExtent); 
    % get axes aspect ratio
    drawnow
    org_units = get(axHandle,'Units');
    set(axHandle,'Units','Pixels')
    ax_position = get(axHandle,'position');        
    set(axHandle,'Units',org_units)
    aspect_ratio = ax_position(4) / ax_position(3);
    
    if xExtent*aspect_ratio > yExtent        
        centerX = mean(curAxis(1:2));
        centerY = mean(curAxis(3:4));
        spanX = (curAxis(2)-curAxis(1))/2;
        spanY = (curAxis(4)-curAxis(3))/2;
       
        % enlarge the Y extent
        spanY = spanY*xExtent*aspect_ratio/yExtent; % new span
        if spanY > 85
            spanX = spanX * 85 / spanY;
            spanY = spanY * 85 / spanY;
        end
        curAxis(1) = centerX-spanX;
        curAxis(2) = centerX+spanX;
        curAxis(3) = centerY-spanY;
        curAxis(4) = centerY+spanY;
    elseif yExtent > xExtent*aspect_ratio
        
        centerX = mean(curAxis(1:2));
        centerY = mean(curAxis(3:4));
        spanX = (curAxis(2)-curAxis(1))/2;
        spanY = (curAxis(4)-curAxis(3))/2;
        % enlarge the X extent
        spanX = spanX*yExtent/(xExtent*aspect_ratio); % new span
        if spanX > 180
            spanY = spanY * 180 / spanX;
            spanX = spanX * 180 / spanX;
        end
        
        curAxis(1) = centerX-spanX;
        curAxis(2) = centerX+spanX;
        curAxis(3) = centerY-spanY;
        curAxis(4) = centerY+spanY;
    end            
    % Enforce Latitude constraints of EPSG:900913
    if curAxis(3) < -85
        curAxis(3:4) = curAxis(3:4) + (-85 - curAxis(3));
    end
    if curAxis(4) > 85
        curAxis(3:4) = curAxis(3:4) + (85 - curAxis(4));
    end
    axis(axHandle, curAxis); % update axis as quickly as possible, before downloading new image
    drawnow
end

% Delete previous map from plot (if exists)
if nargout <= 1 % only if in plotting mode
    curChildren = get(axHandle,'children');
    map_objs = findobj(curChildren,'tag','gmap');
    bd_callback = [];
    for idx = 1:length(map_objs)
        if ~isempty(get(map_objs(idx),'ButtonDownFcn'))
            % copy callback properties from current map
            bd_callback = get(map_objs(idx),'ButtonDownFcn');
        end
    end
    ud = get(axHandle, 'UserData');
    delete(map_objs);
    delete(findobj(curChildren,'tag','MapScale'));
    % Recover userdata of axis (cleared in cleanup function)
    set(axHandle, 'UserData', ud);
end

% Calculate zoom level for current axis limits
[xExtent,yExtent] = latLonToMeters(curAxis(3:4), curAxis(1:2) );
minResX = diff(xExtent) / width;
minResY = diff(yExtent) / height;
minRes = max([minResX minResY]);
tileSize = 256;
initialResolution = 2 * pi * 6378137 / tileSize; % 156543.03392804062 for tileSize 256 pixels
zoomlevel = floor(log2(initialResolution/minRes));

% Enforce valid zoom levels
if zoomlevel < 0 
    zoomlevel = 0;
end
if zoomlevel > 19 
    zoomlevel = 19;
end

% Calculate center coordinate in WGS1984
lat = (curAxis(3)+curAxis(4))/2;
lon = (curAxis(1)+curAxis(2))/2;

% Construct query URL
preamble = 'http://maps.googleapis.com/maps/api/staticmap';
location = ['?center=' num2str(lat,10) ',' num2str(lon,10)];
zoomStr = ['&zoom=' num2str(zoomlevel)];
sizeStr = ['&scale=' num2str(scale) '&size=' num2str(width) 'x' num2str(height)];
maptypeStr = ['&maptype=' maptype ];
if ~isempty(apiKey)
    keyStr = ['&key=' apiKey];
else
    keyStr = '';
end
markers = '&markers=';
for idx = 1:length(markerlist)
    if idx < length(markerlist)
        markers = [markers markerlist{idx} '%7C'];
    else
        markers = [markers markerlist{idx}];
    end
end

if showLabels == 0
    if ~isempty(style)
        style = [style '&style='];
    end
    style = [style 'feature:all|element:labels|visibility:off'];
end

if ~isempty(language)
    languageStr = ['&language=' language];
else
    languageStr = '';
end
    
if ismember(maptype,{'satellite','hybrid'})
    filename = 'tmp.jpg';
    format = '&format=jpg';
    convertNeeded = 0;
else
    filename = 'tmp.png';
    format = '&format=png';
    convertNeeded = 1;
end
sensor = '&sensor=false';

if ~isempty(style)
    styleStr = ['&style=' style];
else
    styleStr = '';
end

url = [preamble location zoomStr sizeStr maptypeStr format markers languageStr sensor keyStr styleStr];

% Get the image
if useTemp
    filepath = fullfile(tempdir, filename);
else
    filepath = filename;
end

try
    urlwrite(url,filepath);
catch % error downloading map
    warning(['Unable to download map form Google Servers.\n' ...
        'Matlab error was: %s\n\n' ...
        'Possible reasons: missing write permissions, no network connection, quota exceeded, or some other error.\n' ...
        'Consider using an API key if quota problems persist.\n\n' ...
        'To debug, try pasting the following URL in your browser, which may result in a more informative error:\n%s'], lasterr, url);
    varargout{1} = [];
    varargout{2} = [];
    varargout{3} = [];
    return
end

[M, Mcolor] = imread(filepath);
Mcolor = uint8(Mcolor * 255);
%M = cast(M,'double');
delete(filepath); % delete temp file
width = size(M,2);
height = size(M,1);

% We now want to convert the image from a colormap image with an uneven
% mesh grid, into an RGB truecolor image with a uniform grid.
% This would enable displaying it with IMAGE, instead of PCOLOR.
% Advantages are:
% 1) faster rendering
% 2) makes it possible to display together with other colormap annotations (PCOLOR, SCATTER etc.)

% Convert image from colormap type to RGB truecolor (if PNG is used)
if convertNeeded
    imag = zeros(height,width,3, 'uint8');
    for idx = 1:3
        cur_map = Mcolor(:,idx);
        imag(:,:,idx) = reshape(cur_map(M+1),height,width);
    end
else
    imag = M;
end
% Resize if needed
if resize ~= 1
    imag = imresize(imag, resize, 'bilinear');
end

% Calculate a meshgrid of pixel coordinates in EPSG:900913
width = size(imag,2);
height = size(imag,1);
centerPixelY = round(height/2);
centerPixelX = round(width/2);
[centerX,centerY] = latLonToMeters(lat, lon ); % center coordinates in EPSG:900913
curResolution = initialResolution / 2^zoomlevel / scale / resize; % meters/pixel (EPSG:900913)
xVec = centerX + ((1:width)-centerPixelX) * curResolution; % x vector
yVec = centerY + ((height:-1:1)-centerPixelY) * curResolution; % y vector
[xMesh,yMesh] = meshgrid(xVec,yVec); % construct meshgrid 

% convert meshgrid to WGS1984
[lonMesh,latMesh] = metersToLatLon(xMesh,yMesh);

% Next, project the data into a uniform WGS1984 grid
uniHeight = round(height*resize);
uniWidth = round(width*resize);
latVect = linspace(latMesh(1,1),latMesh(end,1),uniHeight);
lonVect = linspace(lonMesh(1,1),lonMesh(1,end),uniWidth);
[uniLonMesh,uniLatMesh] = meshgrid(lonVect,latVect);
uniImag = zeros(uniHeight,uniWidth,3);

% Fast Interpolation to uniform grid
uniImag =  myTurboInterp2(lonMesh,latMesh,imag,uniLonMesh,uniLatMesh);

if nargout <= 1 % plot map
    % display image
    hold(axHandle, 'on');
    cax = caxis;
    h = image(lonVect,latVect,uniImag, 'Parent', axHandle);
    caxis(cax); % Preserve caxis that is sometimes changed by the call to image()
    set(axHandle,'YDir','Normal')
    set(h,'tag','gmap')
    set(h,'AlphaData',alphaData)
    
    % add a dummy image to allow pan/zoom out to x2 of the image extent
    h_tmp = image(lonVect([1 end]),latVect([1 end]),zeros(2),'Visible','off', 'Parent', axHandle, 'CDataMapping', 'scaled');
    set(h_tmp,'tag','gmap')
   
    uistack(h,'bottom') % move map to bottom (so it doesn't hide previously drawn annotations)
    axis(axHandle, curAxis) % restore original zoom
    if nargout == 1
        varargout{1} = h;
    end
    set(h, 'UserData', onCleanup(@() cleanupFunc(axHandle)));
    
    % if auto-refresh mode - override zoom callback to allow autumatic 
    % refresh of map upon zoom actions.
    figHandle = axHandle;
    while ~strcmpi(get(figHandle, 'Type'), 'figure')
        % Recursively search for parent figure in case axes are in a panel
        figHandle = get(figHandle, 'Parent');
    end
    
    zoomHandle = zoom(axHandle);   
    panHandle = pan(figHandle); % This isn't ideal, doesn't work for contained axis    
    if autoRefresh        
        set(zoomHandle,'ActionPostCallback',@update_google_map);          
        set(panHandle, 'ActionPostCallback', @update_google_map);        
    else % disable zoom override
        set(zoomHandle,'ActionPostCallback',[]);
        set(panHandle, 'ActionPostCallback',[]);
    end
    
    % set callback for figure resize function, to update extents if figure
    % is streched.
    if figureResizeUpdate &&isempty(get(figHandle, 'ResizeFcn'))
        % set only if not already set by someone else
        set(figHandle, 'ResizeFcn', @update_google_map_fig);       
    end    
    
    % set callback properties 
    set(h,'ButtonDownFcn',bd_callback);
    
    if mapScale
       makescale(axHandle, 'set_callbacks', 0, 'units', scaleUnits, ...
                 'location', scaleLocation, 'width', scaleWidth);
    end
else % don't plot, only return map
    varargout{1} = lonVect;
    varargout{2} = latVect;
    varargout{3} = uniImag;
end
end


% -------------------------------------------------------------------------
function  [Lat,Lon] = utm2deg(xx,yy,utmzone)
% -------------------------------------------------------------------------
% [Lat,Lon] = utm2deg(x,y,utmzone)
%
% Description: Function to convert vectors of UTM coordinates into Lat/Lon vectors (WGS84).
% Some code has been extracted from deg2utm.m function by Rafael Palacios.
%
% Inputs:
%    x, y , utmzone.
%
% Outputs:
%    Lat: Latitude vector.   Degrees.  +ddd.ddddd  WGS84
%    Lon: Longitude vector.  Degrees.  +ddd.ddddd  WGS84
%
% Example 1:
% x=[ 458731;  407653;  239027;  230253;  343898;  362850];
% y=[4462881; 5126290; 4163083; 3171843; 4302285; 2772478];
% utmzone=['30 T'; '32 T'; '11 S'; '28 R'; '15 S'; '51 R'];
% [Lat, Lon]=utm2deg(x,y,utmzone);
% fprintf('%11.6f ',lat)
%    40.315430   46.283902   37.577834   28.645647   38.855552   25.061780
% fprintf('%11.6f ',lon)
%    -3.485713    7.801235 -119.955246  -17.759537  -94.799019  121.640266
%
% Example 2: If you need Lat/Lon coordinates in Degrees, Minutes and Seconds
% [Lat, Lon]=utm2deg(x,y,utmzone);
% LatDMS=dms2mat(deg2dms(Lat))
%LatDMS =
%    40.00         18.00         55.55
%    46.00         17.00          2.01
%    37.00         34.00         40.17
%    28.00         38.00         44.33
%    38.00         51.00         19.96
%    25.00          3.00         42.41
% LonDMS=dms2mat(deg2dms(Lon))
%LonDMS =
%    -3.00         29.00          8.61
%     7.00         48.00          4.40
%  -119.00         57.00         18.93
%   -17.00         45.00         34.33
%   -94.00         47.00         56.47
%   121.00         38.00         24.96
%
% Authors: 
%   Erwin Nindl, Rafael Palacious
%
% Version history by Erwin Nindl:
%   Nov/13: removed main-loop and vectorised all calculations
%
% Version history by Rafael Palacios:
%   Apr/06, Jun/06, Aug/06, Aug/06
%   Aug/06: fixed a problem (found by Rodolphe Dewarrat) related to southern 
%     hemisphere coordinates. 
%   Aug/06: corrected m-Lint warnings
%---------------------------------------------------------------------------

% Argument checking
%
error(nargchk(3, 3, nargin)); %3 arguments required
n1=length(xx);
n2=length(yy);
n3=size(utmzone,1);
if (n1~=n2 || n1~=n3)
   error('x,y and utmzone vectors should have the same number or rows');
end
c=size(utmzone,2);
if (c~=4)
   error('utmzone should be a vector of strings like "30 T"');
end

   
 
% % Memory pre-allocation
% %
% Lat=zeros(n1,1);
% Lon=zeros(n1,1);


% Avoid Main Loop
%

if(~isempty(find(utmzone(:,4)>'X',1)) || ~isempty(find(utmzone(:,4)<'C',1)))
  fprintf('utm2deg: Warning utmzone should be a vector of strings like "30 T", not "30 t"\n');
end

hemis = char(zeros(n1,1));
hemis(:) = 'S';
hemis(utmzone(:,4)>'M') = 'N'; % Northern hemisphere

x = xx(:);
y = yy(:);
zone = str2num(utmzone(:,1:2));

sa = 6378137.000000 ; sb = 6356752.314245;
  
%   e = ( ( ( sa ^ 2 ) - ( sb ^ 2 ) ) ^ 0.5 ) / sa;
e2 = ( ( ( sa .^ 2 ) - ( sb .^ 2 ) ) .^ 0.5 ) ./ sb;
e2cuadrada = e2 .^ 2;
c = ( sa .^ 2 ) ./ sb;
%   alpha = ( sa - sb ) / sa;             %f
%   ablandamiento = 1 / alpha;   % 1/f
X = x - 500000;
Y = y;
ids_south = (hemis == 'S') | (hemis == 's');
Y(ids_south) = Y(ids_south) - 10000000;

S = ( ( zone .* 6 ) - 183 ); 
lat =  Y ./ ( 6366197.724 .* 0.9996 );                                    
v = ( c ./ ( ( 1 + ( e2cuadrada .* ( cos(lat) ) .^ 2 ) ) ) .^ 0.5 ) .* 0.9996;
a = X ./ v;
a1 = sin( 2 .* lat );
a2 = a1 .* ( cos(lat) ) .^ 2;
j2 = lat + ( a1 ./ 2 );
j4 = ( ( 3 .* j2 ) + a2 ) ./ 4;
j6 = ( ( 5 .* j4 ) + ( a2 .* ( cos(lat) ) .^ 2) ) ./ 3;
alfa = ( 3 ./ 4 ) .* e2cuadrada;
beta = ( 5 ./ 3 ) .* alfa .^ 2;
gama = ( 35 ./ 27 ) .* alfa .^ 3;
Bm = 0.9996 .* c .* ( lat - alfa .* j2 + beta .* j4 - gama .* j6 );
b = ( Y - Bm ) ./ v;
Epsi = ( ( e2cuadrada .* a.^2 ) ./ 2 ) .* ( cos(lat) ).^ 2;
Eps = a .* ( 1 - ( Epsi ./ 3 ) );
nab = ( b .* ( 1 - Epsi ) ) + lat;
senoheps = ( exp(Eps) - exp(-Eps) ) ./ 2;
Delt = atan(senoheps ./ (cos(nab) ) );
TaO = atan(cos(Delt) .* tan(nab));
longitude = (Delt .* (180/pi) ) + S;

latitude = ( lat + ( 1 + e2cuadrada .* (cos(lat).^2) - ( 3/2 ) ...
  .* e2cuadrada .* sin(lat) .* cos(lat) .* ( TaO - lat ) ) ...
  .* ( TaO - lat ) ) .* (180/pi);

Lat = latitude;
Lon = longitude;
end


function  [x,y,utmzone] = deg2utm(Lat,Lon)
% -------------------------------------------------------------------------
% [x,y,utmzone] = deg2utm(Lat,Lon)
%
% Description: Function to convert lat/lon vectors into UTM coordinates (WGS84).
% Some code has been extracted from UTM.m function by Gabriel Ruiz Martinez.
%
% Inputs:
%    Lat: Latitude vector.   Degrees.  +ddd.ddddd  WGS84
%    Lon: Longitude vector.  Degrees.  +ddd.ddddd  WGS84
%
% Outputs:
%    x, y , utmzone.   See example
%
% Example 1:
%    Lat=[40.3154333; 46.283900; 37.577833; 28.645650; 38.855550; 25.061783];
%    Lon=[-3.4857166; 7.8012333; -119.95525; -17.759533; -94.7990166; 121.640266];
%    [x,y,utmzone] = deg2utm(Lat,Lon);
%    fprintf('%7.0f ',x)
%       458731  407653  239027  230253  343898  362850
%    fprintf('%7.0f ',y)
%      4462881 5126290 4163083 3171843 4302285 2772478
%    utmzone =
%       30 T
%       32 T
%       11 S
%       28 R
%       15 S
%       51 R
%
% Example 2: If you have Lat/Lon coordinates in Degrees, Minutes and Seconds
%    LatDMS=[40 18 55.56; 46 17 2.04];
%    LonDMS=[-3 29  8.58;  7 48 4.44];
%    Lat=dms2deg(mat2dms(LatDMS)); %convert into degrees
%    Lon=dms2deg(mat2dms(LonDMS)); %convert into degrees
%    [x,y,utmzone] = deg2utm(Lat,Lon)
%
% Author: 
%   Rafael Palacios
%   Universidad Pontificia Comillas
%   Madrid, Spain
% Version: Apr/06, Jun/06, Aug/06, Aug/06
% Aug/06: fixed a problem (found by Rodolphe Dewarrat) related to southern 
%    hemisphere coordinates. 
% Aug/06: corrected m-Lint warnings
%-------------------------------------------------------------------------

% Argument checking
%
narginchk(2, 2);  %2 arguments required
n1=length(Lat);
n2=length(Lon);
if (n1~=n2)
   error('Lat and Lon vectors should have the same length');
end


% Memory pre-allocation
%
x=zeros(n1,1);
y=zeros(n1,1);
utmzone(n1,:)='60 X';

% Main Loop
%
for i=1:n1
   la=Lat(i);
   lo=Lon(i);

   sa = 6378137.000000 ; sb = 6356752.314245;
         
   %e = ( ( ( sa ^ 2 ) - ( sb ^ 2 ) ) ^ 0.5 ) / sa;
   e2 = ( ( ( sa ^ 2 ) - ( sb ^ 2 ) ) ^ 0.5 ) / sb;
   e2cuadrada = e2 ^ 2;
   c = ( sa ^ 2 ) / sb;
   %alpha = ( sa - sb ) / sa;             %f
   %ablandamiento = 1 / alpha;   % 1/f

   lat = la * ( pi / 180 );
   lon = lo * ( pi / 180 );

   Huso = fix( ( lo / 6 ) + 31);
   S = ( ( Huso * 6 ) - 183 );
   deltaS = lon - ( S * ( pi / 180 ) );

   if (la<-72), Letra='C';
   elseif (la<-64), Letra='D';
   elseif (la<-56), Letra='E';
   elseif (la<-48), Letra='F';
   elseif (la<-40), Letra='G';
   elseif (la<-32), Letra='H';
   elseif (la<-24), Letra='J';
   elseif (la<-16), Letra='K';
   elseif (la<-8), Letra='L';
   elseif (la<0), Letra='M';
   elseif (la<8), Letra='N';
   elseif (la<16), Letra='P';
   elseif (la<24), Letra='Q';
   elseif (la<32), Letra='R';
   elseif (la<40), Letra='S';
   elseif (la<48), Letra='T';
   elseif (la<56), Letra='U';
   elseif (la<64), Letra='V';
   elseif (la<72), Letra='W';
   else Letra='X';
   end

   a = cos(lat) * sin(deltaS);
   epsilon = 0.5 * log( ( 1 +  a) / ( 1 - a ) );
   nu = atan( tan(lat) / cos(deltaS) ) - lat;
   v = ( c / ( ( 1 + ( e2cuadrada * ( cos(lat) ) ^ 2 ) ) ) ^ 0.5 ) * 0.9996;
   ta = ( e2cuadrada / 2 ) * epsilon ^ 2 * ( cos(lat) ) ^ 2;
   a1 = sin( 2 * lat );
   a2 = a1 * ( cos(lat) ) ^ 2;
   j2 = lat + ( a1 / 2 );
   j4 = ( ( 3 * j2 ) + a2 ) / 4;
   j6 = ( ( 5 * j4 ) + ( a2 * ( cos(lat) ) ^ 2) ) / 3;
   alfa = ( 3 / 4 ) * e2cuadrada;
   beta = ( 5 / 3 ) * alfa ^ 2;
   gama = ( 35 / 27 ) * alfa ^ 3;
   Bm = 0.9996 * c * ( lat - alfa * j2 + beta * j4 - gama * j6 );
   xx = epsilon * v * ( 1 + ( ta / 3 ) ) + 500000;
   yy = nu * v * ( 1 + ta ) + Bm;

   if (yy<0)
       yy=9999999+yy;
   end

   x(i)=xx;
   y(i)=yy;
   utmzone(i,:)=sprintf('%02d %c',Huso,Letra);
end
end

function [Xi,Xc,zi,zm,si,ni,Ji,Jmax,XY0] = grid_las_data(XY,z,DX)

% interpolate data into regular sample bins using boxcar window
%
% Input
%   XY, an NxM set of coordinates **** x,y/lat,lon ****
%   z, an Nx1 array of observations **** z ****
%   DX, an Mx1 array of scale parameters, indicating the step size in each dimension
%
% Output
%   Xi, the mean position of the data in this cell
%   Xc, the bin center
%   zi, the median value at each interp. cell
%   zm, the mean value at each interp. cell
%   si, the standard error (=std. dev./sqrt(n)) (or, if ni<3, insert average value)
%   ni, the number of observations going into this cell
%   Ji, the array of indices into each cell
%   Jmax, the array of number of cells in each dimension
%   XY0, the location of the first grid point

% Define N and M vectors as the size of X and Y, 
% N is horizontal component, M is vertical component
[N,M] = size(XY);

% Convert DX (height and width of grid cells) from column to row vector
DX = DX(:)';  

% XY0, the location of the first grid point is the minimum X and Y value (lower left corner?) 
% divided by the grid size (1 meter x 1 meter here), mult. by grid size - WHY?

% make nice integer values (round down)
% with 1 x 1m grid and UTM coordinates, grid bins are alwasys on integer values for easy comparison survey to survey
XY0 = floor(min(XY)./DX).*DX; 

% map data to scaled points
% basically this is creating a new index for the sampling grid
% J = 1,1...,1 is location XY0(1,1,...,1)
% repmat  vertically stacks the row vector XY (then DX) "N" times
% subtract XY0 origin from every XY term, add 1 to each value
% divide each term by grid size
% round to nearest integer
J = round(1+(XY-repmat(XY0,N,1))./repmat(DX,N,1)); % in scaled coords 1 = dx?

% map these to index into array of unique indices
%   Ji, the array of indices into each cell
%   Jmax, the array of number of cells in each dimension
Jmax = max(J); % finds max x and y values of adjusted array J
Ji=ones(N,1); % creates a single column vector of 1's, size N
Jprod = 1; % initialize value at 1
for i=1:M % for i = i thru size of data y values (1:2)
   Ji = Ji+(J(:,i)-1)*Jprod; % Ji is column x or y value minus 1, plus 1, times value of Jprod
   % Ji where i is 1 = x values, Ji where i is 2 = y values
   Jprod = Jprod*Jmax(i);   % starts at 1, then mult by max value for each column
end
%this would be similar to making a meshgrid and then concatenating into a
%vector and labeling each index??  (only that the data is not evenly
%spaced?)  all in new bin scaled coords...?

% initialize output arrays that are as large as the largest index
Ni = max(Ji); % number of cells?
%zi = repmat(0,Ni,1); %   zi, the mean value at each interp. cell
zcell = cell(Ni,1); 
si = zeros(Ni,1); %   si, the standard error (=std. dev./sqrt(n)) (or, if ni<3, insert average value)
ni = si; %   ni, the number of observations going into this cell
Xi = zeros(Ni,M); %   Xi, the mean position of the data in this cell
Xc = Xi; %   Xc, the bin center

% in orignal code, above section was as below. matlab suggested
% changing repmat() to zeros()
% % initialize output arrays that are as large as the largest index
% Ni = max(Ji);
% %zi = repmat(0,Ni,1);
% zcell = cell(Ni,1);
% si = repmat(0,Ni,1);
% ni = si;
% Xi = repmat(0,Ni,M);
% Xc = Xi;

% insert values
for i=1:N
   ni(Ji(i)) = ni(Ji(i))+1; %number in each bin
   %zi(Ji(i)) = zi(Ji(i))+z(i); %z sum in each bin
   zcell{Ji(i)} = [zcell{Ji(i)},z(i)];
   si(Ji(i))= si(Ji(i))+z(i).^2; %z.^2 sum in each bin
   
   % keep track of cell locations used
   Xc(Ji(i),:) = (J(i,:)-1).*DX + XY0;
   
   % keep track of mean data location within cell
   Xi(Ji(i),:) = Xi(Ji(i),:) + XY(i,:); %x sum in each bin
end

% get median and mean values at each cell
Ji = find(ni); % find bins with more than 10 points (change back to 0 if this doesn't work)
Ni = length(Ji); % Ni equals the number of bins with more than 0 pts
ni = ni(Ji); % 
%zi = zi(Ji)./ni; %avg z value in each bin
%zi was average. Now it is median. See below. zm is now the median value
%variable. -rlg 1/27/19
zi = nan(Ni,1); % creates zi variable populated by NaNs
zm = nan(Ni,1); % "       zm "
for i = 1:Ni
    zi(i) = median(zcell{Ji(i)}); % use median instead!
    zm(i) = mean(zcell{Ji(i)});
end

% find cell center and mean data location
Xc = Xc(Ji,:); % use this for cell location center
Xi = Xi(Ji,:)./repmat(ni, 1,M); % use this for mean data location in cell

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculate standard deviation %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%si = real( sqrt( (si(Ji)./ni)-(zi.^2) ) ); % real is used to deal with roundoff error 
%yes this is standard deviation: %sqrt(mean(z.^2) - mean(z).^2)

% !!!!!!!!!!!!!!!!!!!!!!!!!
%careful with std calculation because zi is now calculated as median not
%mean!!
%just fixed this. need to reprocess old stuff.
% standard error
%si = real( sqrt( (si(Ji)./ni)-(zi.^2) ) )./sqrt(ni); 
si = real( sqrt( (si(Ji)./ni)-(zm.^2) ) )./sqrt(ni); % real is used to deal with roundoff error
%standard error is standard deviation / sqrt(n)

% replace bogus std
id = find(ni<3 | si==0);
if(length(id)<Ni)
   % we will pad the error estimate with the mean value
   idg = ni>=3;
   stot = mean(si(idg));
else
   % all of them are missing estimates, put in data std.dev.
   stot = std(z)/sqrt(N);
end
si(id) = repmat(stot, length(id),1);

% original code below using find() was optimized by matlab above
%    % we will pad the error estimate with the mean value
%    idg = find(ni>=3);
%    stot = mean(si(idg));


% %%%%%%%%
% % PLOT %
% %%%%%%%%
% 
% % to make a quick grid of the data:
%      [XX,YY] = meshgrid([1:Jmax(1)]*DX(1)+XY0(1),[1:Jmax(2)]*DX(2)+XY0(2));
%      ZZ = nan(Jmax(1),Jmax(2)); % careful, read in flipped
%      EE = ZZ;
%      ZZ(Ji) = zi; ZZ = ZZ'; % flip to usual orientation for matlab
%      EE(Ji) = si; EE = EE'; 
%      surf(XX,YY,ZZ);%pcolor(XX,YY,ZZ);
%      hold on;
%      axis equal;

end
















