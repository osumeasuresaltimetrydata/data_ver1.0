%% NET CDF check

clear all; close all;

addpath 'C:\Users\coss.31\Documents\MATH\Steves_final_Toolbox\AltimetryToolbox\Dataproduct' % change this to the local directory where you have the altimetry data

% Uncomment to look at all Americas -- warning opens ~300 Matlab figure windows
NorthAmerica={'Columbia','Mackenzie','StLawrence','Susquehanna', 'Yukon','Mississippi'};
SouthAmerica={'Amazon','Tocantins','Orinoco','SaoFrancisco','Uruguay','Magdalena','Parana','Oiapoque','Essequibo','Courantyne'};
Americas=[NorthAmerica SouthAmerica];
Africa={'Congo','Nile','Niger','Zambezi'};
Eurasia={'Amur','Anabar','Ayeyarwada','Kuloy','Ob','Menzen','Lena','Yenisei','Pechora','Pyasina','Khatanga','Olenyok' ...
    ,'Indigirka','Kolyma','Anadyr','Yangtze','Mekong','Ganges','Brahmaputra','Indus','Volga'};

SingleRiv={'Yukon'};


Rivers=Eurasia ;
TS=true
SAVEPLOTS=true %save the plots

%% map
figure; lon=[]; lat=[];
for i=1:length(Rivers),
    currRiv=Rivers{i};  
    FNAME1=[currRiv '_NetCDF_List.txt'];
    FID=fopen(FNAME1,'r');
    delimiter = ',';
    startRow = 4;
 formatSpec = '%s';
    dataArray = textscan(FID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'HeaderLines' ,startRow-1, 'ReturnOnError', false);
    fclose(FID);
    VSLIST=dataArray{1};
    if ~isempty(VSLIST)
    for j=1:length(VSLIST),
        FNAME2=[VSLIST{j} '.nc'];
        lon=[lon ncread(FNAME2,'lon')];
        lat=[lat ncread(FNAME2,'lat')];
    end
    else
         FID=fopen(FNAME1,'r');
    delimiter = ',';
    startRow = 3;
 formatSpec = '%s';
    dataArray = textscan(FID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'HeaderLines' ,startRow-1, 'ReturnOnError', false);
    fclose(FID);
    VSLIST=dataArray{1};
    for j=1:length(VSLIST),
        FNAME2=[VSLIST{j} '.nc'];
        lon=[lon ncread(FNAME2,'lon')];
        lat=[lat ncread(FNAME2,'lat')];
    end
        
    end
end
hold off;
if length(lon)>1
a=axis;
ax=worldmap([min(lat) max(lat)],[min(lon) max(lon)]);
%ax=worldmap('Eurasia')
land=shaperead('landareas','UseGeoCoords',true);
geoshow(ax,land,'FaceColor',[0.5 0.7 0.5]);
rivers=shaperead('worldrivers','UseGeoCoords',true);
geoshow(ax,rivers,'Color','blue');
geoshow(lat,lon,'DisplayType','point')
title('Selected virtual station locations')
else 
    a=axis;
ax=worldmap([min(lat) max(lat)],[min(lon) max(lon)]);
land=shaperead('landareas','UseGeoCoords',true);
geoshow(ax,land,'FaceColor',[0.5 0.7 0.5]);
rivers=shaperead('worldrivers','UseGeoCoords',true);
geoshow(ax,rivers,'Color','blue');
geoshow(lat,lon,'DisplayType','point')
title('Selected virtual station locations')
   
end

%% timeseries
if TS
for i=1:length(Rivers)
    currRiv=Rivers{i};  
    FNAME1=[currRiv '_NetCDF_List.txt'];
    FID=fopen(FNAME1,'r');
    delimiter = ',';
    startRow = 4;
    formatSpec = '%s%[^\n\r]';
    dataArray = textscan(FID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'HeaderLines' ,startRow-1, 'ReturnOnError', false);
    fclose(FID);
    VSLIST=dataArray{1};
      if isempty(VSLIST)
            FID=fopen(FNAME1,'r');
    delimiter = ',';
    startRow = 3;
    formatSpec = '%s%[^\n\r]';
    dataArray = textscan(FID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'HeaderLines' ,startRow-1, 'ReturnOnError', false);
    fclose(FID);
    VSLIST=dataArray{1};
      end

    for j=1:length(VSLIST),
        figure;
        FNAME2=[VSLIST{j} '.nc'];
        t=ncread(FNAME2,'/Timeseries/time');
        h=ncread(FNAME2,'/Timeseries/hwbar');
        var3=ncread(FNAME2,'ID');
        Flow_Dist=ncread(FNAME2,'Flow_Dist');
        var4=ncread(FNAME2,'/Level3/lon');
        var5=ncread(FNAME2,'/Level3/lat');
        var6=ncread(FNAME2,'/Level3/h');
        var3=var3';
        gdat=(h>-1);
        t=t(gdat);  tv=datevec(t);
        h=h(gdat);
        x=ncread(FNAME2,'Flow_Dist');
%         ncdisp(FNAME2); %uncomment to see a list of all attributes

        %interpolated heights
        ti=t(1):t(end);
        hi=interp1(t,h,ti);

        %if exists, grab ice filter info
        tthaw=datevec(ncread(FNAME2,'/Filter/icethaw'));
        tfreeze=datevec(ncread(FNAME2,'/Filter/icefreeze'));        
        if ~isempty(tthaw),
            tvi=datevec(ti);            
            for k=1:length(tvi),
                m=find(tthaw(:,1)==tvi(k,1));
                n=find(tv(:,1)==tvi(k,1));
                
                if ti(k)<datenum(tthaw(m,:)) || ti(k)>datenum(tfreeze(m,:)) ...
                        || ti(k)<min(t(n)) || ti(k)>max(t(n)),
                    hi(k)=nan;
                end
            end
        end

        han1=plot(t,h,'ro','LineWidth',2); hold on;
        han2=plot(ti,hi,'k--');     

        if ~isempty(tthaw),
            a=axis; yplot=a(3)+.01*(a(4)-a(3));
            for k=1:length(tthaw)-1,
                if datenum(tfreeze(k,:)) > min(t) && datenum(tfreeze(k,:)) < max(t),
                    han3=plot([datenum(tfreeze(k,:)) datenum(tthaw(k+1,:))],[yplot yplot],...
                        'b-','LineWidth',2);
                end
            end
        end
        hold off;
        set(gca,'FontSize',14)
        datetick('x');
        title([var3 ' elevations at ' num2str(Flow_Dist,'%.1f') ' km'],'Interpreter', 'none');
        xlabel('Date');
        ylabel('Height above MSL, m');
        if ~isempty(tthaw),
            legend([han1 han2 han3],'Altimeter data','Interpolated','Ice cover',...
                'Location','Best')
        else
            legend([han1 han2 ],'Altimeter data','Interpolated','Location','Best')
        end
        if SAVEPLOTS
            path=fullfile('C:\Users\coss.31\Documents\MATH\Steves_final_Toolbox\AltimetryToolbox\Dataproduct\TS_Images',var3);
            print(path,'-djpeg');
        end
    end
    
end
end
