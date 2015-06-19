
classdef ic_MDCKtools_data_controller < handle 
    
    % Copyright (C) 2013 Imperial College London.
    % All rights reserved.
    %
    % This program is free software; you can redistribute it and/or modify
    % it under the terms of the GNU General Public License as published by
    % the Free Software Foundation; either version 2 of the License, or
    % (at your option) any later version.
    %
    % This program is distributed in the hope that it will be useful,
    % but WITHOUT ANY WARRANTY; without even the implied warranty of
    % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    % GNU General Public License for more details.
    %
    % You should have received a copy of the GNU General Public License along
    % with this program; if not, write to the Free Software Foundation, Inc.,
    % 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
    %
    % This software tool was developed with support from the UK 
    % Engineering and Physical Sciences Council 
    % through  a studentship from the Institute of Chemical Biology 
    % and The Wellcome Trust through a grant entitled 
    % "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).
   
    properties(Constant)
        data_settings_filename = 'MDCK_tools_data_settings.xml';
    end
    
    properties(SetObservable = true)
            
        downsampling = 16;
        histogram_bins = 100;
        correlation_plot_width = 200;
        
        microns_per_pixel = 4;
        time_step = 2700; % seconds
        
        % graphics        
        scene_axes;
        globals_axes;
        corrplot_axes;
        histogram_axes;
        %
        display_tabpanel;
        lower_layout;
        
            % scene
        scene_popupmenu
        scene_channel_selector_popupmenu
            % globals
        globals_popupmenu
        globals_channel_selector_popupmenu;            
            % correlation plot        
        corrplotX_popupmenu;
        corrplotY_popupmenu;
        corrplot_channel_selector_popupmenu;
            % histogram        
        histo_popupmenu;
        histo_channel_selector_popupmenu;
                        
        % graphics
        %
        scene_popupmenu_str = {'masked 0-th image','sources','amplitude','relative amplitude','activity','distance to source'};
        scene_channel_selector_popupmenu_str = {'Ch1','Ch2'};
        globals_channel_selector_popupmenu_str = {'Ch1','Ch2','All channels'};
        corrplot_channel_selector_popupmenu_str = {'Ch1','Ch2','All channels'};
        histo_channel_selector_popupmenu_str = {'Ch1','Ch2'};        

        globals_popupmenu_str = {'average(t)','std(t)','gradmod(t)','std vs average'};            
        corrplotX_popupmenu_str = {'distance to source','amplitude','relative amplitude','activity'};            
        corrplotY_popupmenu_str = {'distance to source','amplitude','relative amplitude','activity'};            
        histo_popupmenu_str = {'masked 0-th image','amplitude','relative amplitude','activity','distance to source'};               
        % 
        object_mask = [];
        sources_mask = [];
        %
        imgdata = [];           
                               
    end                    
    
    properties(Transient)
        
        DefaultDirectory = ['C:' filesep];
        IcyDirectory = [];
                
        SrcDir = [];
        SrcFileList = [];
        DstDir = [];        
                
        file_names = [];
        omero_Image_IDs = [];
                                        
    end    
        
    properties(Transient,Hidden)
        % Properties that won't be saved to a data_settings_file etc.
        
        menu_controller;
                                               
    end
    
    events
        
    end
            
    methods
        
        function obj = ic_MDCKtools_data_controller(varargin)            
            %   
            handles = args2struct(varargin);
            assign_handles(obj,handles);            
                        
            try 
            obj.load_settings;
            catch
            end
            
            if isempty(obj.IcyDirectory)
                hw = waitbar(0,'looking for Icy directory..');
                waitbar(0.1,hw);                
                if ispc
                       prevdir = pwd;
                       cd('c:\');
                       [~,b] = dos('dir /s /b icy.exe');
                       if ~strcmp(b,'File Not Found')
                            filenames = textscan(b,'%s','delimiter',char(10));
                            s = char(filenames{1});
                            s = s(1,:);
                            s = strsplit(s,'icy.exe');
                            obj.IcyDirectory = s{1};
                       end
                       cd(prevdir);
                elseif ismac
                    % to do
                else
                    % to do
                end                
                delete(hw); drawnow;
            end
                                    
            scene_panel = handles.scene_panel;
            globals_panel = handles.globals_panel;
            corrplot_panel = handles.corrplot_panel;
            histogram_panel = handles.histogram_panel;
            
            obj.display_tabpanel = handles.display_tabpanel;
            obj.lower_layout = handles.lower_layout;
              
            obj.scene_axes = axes( 'Parent', scene_panel,'ActivePositionProperty', 'OuterPosition' );axis image;set(obj.scene_axes,'XTick',[],'YTick',[]);
            obj.globals_axes = axes( 'Parent', globals_panel,'ActivePositionProperty', 'Position' );
            obj.corrplot_axes = axes( 'Parent', corrplot_panel,'ActivePositionProperty', 'Position' );axis image;set(obj.corrplot_axes,'XTick',[],'YTick',[]);
            obj.histogram_axes = axes( 'Parent', histogram_panel,'ActivePositionProperty', 'Position' );axis image;set(obj.histogram_axes,'XTick',[],'YTick',[]);                        
            
            lower_scene_layout = uiextras.Grid( 'Parent', obj.lower_layout, 'Spacing', 10, 'Padding', 16, 'RowSizes',-1,'ColumnSizes',-1  );
            
            %image
            uicontrol( 'Style', 'text', 'String', 'Image  ','HorizontalAlignment', 'right', 'Parent', lower_scene_layout );            
            obj.scene_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', obj.scene_popupmenu_str, 'Parent', lower_scene_layout,'Callback', @obj.onSceneImageSet ); 
            obj.scene_channel_selector_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', obj.scene_channel_selector_popupmenu_str, 'Parent', lower_scene_layout,'Callback', @obj.onSceneChannelSet );    

            % globals
            uicontrol( 'Style', 'text', 'String', 'Globals  ','HorizontalAlignment', 'right', 'Parent', lower_scene_layout );            
            obj.globals_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', obj.globals_popupmenu_str, 'Parent', lower_scene_layout,'Callback', @obj.onGlobalsSet ); 
            obj.globals_channel_selector_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', obj.globals_channel_selector_popupmenu_str, 'Parent', lower_scene_layout,'Callback', @obj.onGlobalsChannelSet );                
            
            % correlation plot
            uicontrol( 'Style', 'text', 'String', 'Correlation plot  ','HorizontalAlignment', 'right', 'Parent', lower_scene_layout );            
            obj.corrplotX_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', obj.corrplotX_popupmenu_str, 'Parent', lower_scene_layout,'Callback', @obj.onCorrplotXSet ); 
            obj.corrplotY_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', obj.corrplotY_popupmenu_str, 'Parent', lower_scene_layout,'Callback', @obj.onCorrplotYSet );             
            obj.corrplot_channel_selector_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', obj.corrplot_channel_selector_popupmenu_str, 'Parent', lower_scene_layout,'Callback', @obj.onCorrplotChannelSet );                                        
            
            % histogram
            uicontrol( 'Style', 'text', 'String', 'Histogram  ','HorizontalAlignment', 'right', 'Parent', lower_scene_layout );            
            obj.histo_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', obj.histo_popupmenu_str, 'Parent', lower_scene_layout,'Callback', @obj.onHistoSet );             
            obj.histo_channel_selector_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', obj.histo_channel_selector_popupmenu_str, 'Parent', lower_scene_layout,'Callback', @obj.onHistoChannelSet );                            
                                                                                    
        end
%-------------------------------------------------------------------------%
        function delete(obj)
            obj.save_settings;
        end       
%-------------------------------------------------------------------------%                
         function clear_all(obj,~)
             obj.imgdata = [];
             obj.object_mask = [];
             obj.sources_mask = [];
             cla(obj.scene_axes,'reset');
             cla(obj.globals_axes,'reset');
             cla(obj.corrplot_axes,'reset');
             cla(obj.histogram_axes,'reset');             
         end
%-------------------------------------------------------------------------%        
        function load_native(obj,verbose,~)
            
            [filenames, pathname] = uigetfile({'*.tif'},'Select data files',obj.DefaultDirectory,'MultiSelect','on');
            if pathname == 0, return, end;

            filenames = sort_nat(cellstr(filenames));

            obj.imgdata = [];

            hw = [];
            waitmsg = 'Loading planes...';
            if verbose
                hw = waitbar(0,waitmsg);
            end            

            filenames1 = [];
            filenames2 = [];
            for k = 1:numel(filenames)
                if ~isempty(strfind(char(filenames{k}),'GFP'))
                    filenames1 = [filenames1 cellstr(char(filenames{k}))];
                elseif ~isempty(strfind(char(filenames{k}),'TOM'))    
                    filenames2 = [filenames2 cellstr(char(filenames{k}))];
                end
            end
                               
            two_channels = false;
            if ~isempty(filenames1) && ~isempty(filenames2) && numel(filenames1) == numel(filenames1)
                two_channels = true;
                filenames1 = sort_nat(filenames1);
                filenames2 = sort_nat(filenames2);
            end
            
            if two_channels
                
                nT = numel(filenames1);
                    for k = 1 : nT
                        plane1 = imresize(imread([pathname char(filenames1{k})]),1/obj.downsampling);
                        plane2 = imresize(imread([pathname char(filenames2{k})]),1/obj.downsampling);
                        if isempty(obj.imgdata)
                            [sizeX,sizeY] = size(plane1);
                            obj.imgdata = zeros(sizeX,sizeY,1,2,nT); % XYZCT
                        end
                        obj.imgdata(:,:,1,1,k) = plane1;
                        obj.imgdata(:,:,1,2,k) = plane2;
                        if ~isempty(hw), waitbar(k/nT,hw); drawnow, end;                     
                    end    
                if ~isempty(hw), delete(hw), drawnow; end;                            
                                
            else
                % Z = 1, C = 1 - first try...
                nT = numel(filenames);
                    for k = 1 : nT
                        plane = imresize(imread([pathname char(filenames{k})]),1/obj.downsampling);
                        if isempty(obj.imgdata)
                            [sizeX,sizeY] = size(plane);
                            obj.imgdata = zeros(sizeX,sizeY,1,1,nT); % XYZCT                                                 
                        end
                        obj.imgdata(:,:,1,1,k) = plane;
                        if ~isempty(hw), waitbar(k/nT,hw); drawnow, end;                     
                    end    
                if ~isempty(hw), delete(hw), drawnow; end;
            end
            
            %
            firstimg = squeeze(obj.imgdata(:,:,1,1,k));
            imagesc(firstimg,'Parent',obj.scene_axes);
            daspect(obj.scene_axes,[1 1 1]);
            set( obj.scene_axes, 'xticklabel', [], 'yticklabel', [] );
            
            %
            [sizeX,sizeY,~,~,~] = size(obj.imgdata);
            obj.sources_mask = zeros(sizeX,sizeY);
            obj.object_mask = zeros(sizeX,sizeY);
            
            obj.DefaultDirectory = pathname;
            
        end        
%-------------------------------------------------------------------------%        
        function load_mat(obj,~,~)
            %
            % to do
            %
        end        
%-------------------------------------------------------------------------%        
        function save_curent_data_mat(obj,~,~)
            %
            % to do
            %            
        end        
%-------------------------------------------------------------------------%        
        function apply_segmentation(obj,~,~)            
            set(obj.display_tabpanel, 'SelectedChild', 1); % scene
            
% % suitable for 16 downsampling, 4 microns per pixel            
%              scale = 9;
%              rel_bg_scale = 3;
%              smoothing = 2;
%              min_area  = 100;
%              close_radius = 6;

             uppix = obj.microns_per_pixel*obj.downsampling;

             %sgm options!
             Quantile = 0.6;
             threshold = 0.01;
             rel_bg_scale = 3;            
                         
             % these are in microns
             scale_um = 576;
             smoothing_um = 128;
             min_area_um = 409600;
             close_radius_um = 384;
             
             scale = fix(scale_um/uppix);
             smoothing = fix(smoothing_um/uppix);
             min_area = fix(min_area_um/uppix/uppix);
             close_radius = fix(close_radius_um/uppix);

             if scale < 2, scale = 2; end; 
             if smoothing < 1, smoothing = 1; end;
             if min_area < 1, min_area = 1; end; 
             if close_radius < 1, close_radius = 1; end;
                                      
            u = squeeze(obj.imgdata(:,:,1,1,1)); % just first image
            
            zeromask = (0==u);
            u1 = u(~zeromask);
            uq = quantile(u1(:),Quantile);
            u( u < uq ) = uq;

            z = nth_segmentation(u,scale,rel_bg_scale,threshold,smoothing,min_area);

            z(z~=0)=1;
            z = imclose(z,strel('disk',close_radius)); % 6 for 1/16            
            
            obj.object_mask = z;
            
            % visualizing - temporary, here...
            u(obj.object_mask==0)=0;
            obj.display_scene_image(u);
            %            
        end        
%-------------------------------------------------------------------------%        
        function add_source(obj,~,~)            
            set(obj.display_tabpanel, 'SelectedChild', 1); % scene

                %
                h = figure('units','normalized','outerposition',[0 0 1 1]);
                u = squeeze(obj.imgdata(:,:,1,1,1)); % just first image
                u(obj.object_mask==0)=0;
                imagesc(u);
                daspect([1 1 1]);
                [x,y] = ginput2(1);
                close(h);

                m2 = bwlabeln(obj.object_mask);
                l1 = m2(fix(y(1)),fix(x(1)));    

                sel_label_image = (m2==l1);
                
                % sources mask
                obj.sources_mask(sel_label_image==1)=1;
                obj.object_mask(sel_label_image) = 0;
               
                %
                u(obj.object_mask==0)=0;
                obj.display_scene_image(u);
                                            
        end        
%-------------------------------------------------------------------------%        
        function delete_object(obj,~,~)
            set(obj.display_tabpanel, 'SelectedChild', 1); % scene
            
                %
                u = squeeze(obj.imgdata(:,:,1,1,1)); % just first image
                u(obj.object_mask==0)=0;
                
                h = figure('units','normalized','outerposition',[0 0 1 1]);
                imagesc(u);
                daspect([1 1 1]);
                [x,y] = ginput2(1);
                close(h);
                
                m2 = bwlabeln(obj.object_mask);
                l1 = m2(fix(y(1)),fix(x(1)));    
                
                sel_label_image = (m2==l1);

                % just remove from object mask
                obj.object_mask = obj.object_mask - sel_label_image;

                % visualizing - temporary, here...
                u(obj.object_mask==0)=0;
                obj.display_scene_image(u);
                %                        
        end        
%-------------------------------------------------------------------------%        
        function select_object(obj,~,~)
            set(obj.display_tabpanel, 'SelectedChild', 1); % scene
            
                %
                h = figure('units','normalized','outerposition',[0 0 1 1]);
                u = squeeze(obj.imgdata(:,:,1,1,1)); % just first image
                u(obj.object_mask==0)=0;
                imagesc(u);
                daspect([1 1 1]);
                [x,y] = ginput2(1);
                close(h);

                m2 = bwlabeln(obj.object_mask);
                l1 = m2(fix(y(1)),fix(x(1)));    

                sel_label_image = (m2==l1);

                % just remove from object mask
                obj.object_mask = sel_label_image;

                % visualizing - temporary, here...
                u(obj.object_mask==0)=0;
                obj.display_scene_image(u);
                %                        
        end        
%-------------------------------------------------------------------------%        
function u = calculate_stat_image(obj,image_type,channel,~)

    u = [];
    
    if isempty(obj.object_mask), return, end;
    
    %c = str2num(channel(length(channel)));
    c = 1;
    if strcmp(channel,'Ch2'), c = 2; end; % mmmm not good
    
    if isempty(obj.imgdata), return, end;
    [sizeX,sizeY,~,sizeC,nT] = size(obj.imgdata);
    if c > sizeC, return, end;
    
    if      strcmp(image_type,'masked 0-th image')
                        u = squeeze(obj.imgdata(:,:,1,c,1)); % just first image
                        u(~obj.object_mask)=0;
    elseif  strcmp(image_type,'sources')
                        u = obj.sources_mask;    
    elseif  strcmp(image_type,'amplitude')
                        u = zeros(sizeX,sizeY);
                        for x=1:sizeX
                            for y=1:sizeY
                                if obj.object_mask(x,y)
                                    v = obj.imgdata(x,y,1,c,:);
                                    minv = min(v(:));
                                    maxv = max(v(:));
                                    u(x,y) = maxv-minv;                                        
                                end
                            end
                        end                   
                        u(~obj.object_mask)=0;
    elseif  strcmp(image_type,'relative amplitude')
                        u = zeros(sizeX,sizeY);
                        for x=1:sizeX
                            for y=1:sizeY
                                if obj.object_mask(x,y)
                                    v = obj.imgdata(x,y,1,c,:);
                                    minv = min(v(:));
                                    maxv = max(v(:));
                                    u(x,y) = (maxv-minv)/mean(v);                                        
                                end
                            end
                        end                   
                        u(~obj.object_mask)=0;
    elseif  strcmp(image_type,'activity') 
                        TA = zeros(sizeX,sizeY);
                        for k = 1 : nT-1
                            u1 = squeeze(obj.imgdata(:,:,1,c,k));
                            u2 = squeeze(obj.imgdata(:,:,1,c,k+1));
                            TA = TA + (u2-u1).^2;
                        end
                        u = sqrt(TA/(nT-1)); %:)
                        u(~obj.object_mask)=0;
    elseif  strcmp(image_type,'distance to source')
                        u = bwdist( obj.sources_mask );
                        u(~obj.object_mask)=0;
    end
                
end
%-------------------------------------------------------------------------%        
function display_scene_image(obj,image,~)   
        imagesc(image,'Parent',obj.scene_axes);
        daspect(obj.scene_axes,[1 1 1]);
        set( obj.scene_axes, 'xticklabel', [], 'yticklabel', [] );        
end
%-------------------------------------------------------------------------%        
function ret = get_popupmenu_string(obj,popupmenu,~)
        string = get(popupmenu,'String'); 
        value = get(popupmenu,'Value');
        ret = string(value);
end    
            % scene
%-------------------------------------------------------------------------%                    
function onSceneImageSet(obj,~,~) 
    set(obj.display_tabpanel, 'SelectedChild', 1); % scene
    %
    image_type = obj.get_popupmenu_string(obj.scene_popupmenu);
    channel = obj.get_popupmenu_string(obj.scene_channel_selector_popupmenu);
    %
    obj.display_scene_image(obj.calculate_stat_image(image_type,channel));    
end
%-------------------------------------------------------------------------%        
function onSceneChannelSet(obj,~,~) % same as above
    obj.onSceneImageSet;
end
            % globals
            
%-------------------------------------------------------------------------%        
function [X,Y] = get_global_vars(obj,type,channel) % same as above
    
    if isempty(obj.object_mask), return, end;
    
    %c = str2num(channel(length(channel)));
    c = 1;
    if strcmp(channel,'Ch2'), c = 2; end; % mmmm not good
    
    if isempty(obj.imgdata), return, end;
    [sizeX,sizeY,~,sizeC,nT] = size(obj.imgdata);
    if c > sizeC, return, end;

    times = (1:nT);
    
    if      strcmp(type,'average(t)')
                averages = zeros(1,nT);        
                for k = 1 : nT
                    plane = squeeze(obj.imgdata(:,:,1,c,k));
                    sample = plane(obj.object_mask~=0);
                    %sample = sample(sample~=0);
                    averages(k) = mean(sample(:));
                end        
                X = times;
                Y = averages;        
    elseif  strcmp(type,'std(t)')
                stds = zeros(1,nT);        
                for k = 1 : nT
                    plane = squeeze(obj.imgdata(:,:,1,c,k));
                    sample = plane(obj.object_mask~=0);
                    %sample = sample(sample~=0);
                    stds(k) = std(sample(:));
                end        
                X = times;
                Y = stds;                
    elseif  strcmp(type,'gradmod(t)')
                gradmods = zeros(1,nT);        
                for k = 1 : nT
                    plane = squeeze(obj.imgdata(:,:,1,c,k));
                    [gx,gy] = gsderiv(plane,1,1); % scale might be specified
                    gradmod = sqrt(gx.*gx+gy.*gy);
                    sample = gradmod(obj.object_mask~=0);
                    %sample = sample(sample~=0);
                    gradmods(k) = mean(sample(:));
                end        
                X = times;
                Y = gradmods;                        
    elseif  strcmp(type,'std vs average')
                averages = zeros(1,nT);
                stds = zeros(1,nT);  
                for k = 1 : nT
                    plane = squeeze(obj.imgdata(:,:,1,c,k));
                    sample = plane(obj.object_mask~=0);
                    %sample = sample(sample~=0);
                    averages(k) = mean(sample(:));
                    stds(k) = std(sample(:));
                end        
                Y = stds;
                X = averages;                
    end
            
end            
%-------------------------------------------------------------------------%        
function onGlobalsSet(obj,~,~) 
    set(obj.display_tabpanel, 'SelectedChild', 2); % globals    
    type = obj.get_popupmenu_string(obj.globals_popupmenu);
    channel = obj.get_popupmenu_string(obj.globals_channel_selector_popupmenu);        
    [X,Y] = obj.get_global_vars(type,channel);
    %
    plot(obj.globals_axes,X,Y,'bo-');
    xlabel(obj.globals_axes,[type ' ' channel]);    
    grid(obj.globals_axes,'on');
end
%-------------------------------------------------------------------------%        
function onGlobalsChannelSet(obj,~,~) 
    obj.onGlobalsSet;
end                       
            % correlation plot
%-------------------------------------------------------------------------%                    
function onCorrplotXSet(obj,~,~) 
    set(obj.display_tabpanel, 'SelectedChild', 3); % corrplot
    channel = obj.get_popupmenu_string(obj.corrplot_channel_selector_popupmenu);
    ximage = obj.calculate_stat_image(obj.get_popupmenu_string(obj.corrplotX_popupmenu),channel);
    yimage = obj.calculate_stat_image(obj.get_popupmenu_string(obj.corrplotY_popupmenu),channel);
    corrmap = correlation_map(ximage,yimage,obj.object_mask,obj.correlation_plot_width);
    %
    imagesc(corrmap,'Parent',obj.corrplot_axes);
    daspect(obj.corrplot_axes,[1 1 1]);
    set(obj.corrplot_axes, 'xticklabel', [], 'yticklabel', []);
    %
    xlabel(obj.corrplot_axes,obj.get_popupmenu_string(obj.corrplotX_popupmenu));
    ylabel(obj.corrplot_axes,obj.get_popupmenu_string(obj.corrplotY_popupmenu));        
end
%-------------------------------------------------------------------------%        
function onCorrplotYSet(obj,~,~) 
    obj.onCorrplotXSet;
end                         
            % histogram
%-------------------------------------------------------------------------%        
function onCorrplotChannelSet(obj,~,~)
    obj.onCorrplotXSet;
end
%-------------------------------------------------------------------------%        
function onHistoSet(obj,~,~) 
    set(obj.display_tabpanel, 'SelectedChild', 4); % histo
    image_type = obj.get_popupmenu_string(obj.histo_popupmenu);
    channel = obj.get_popupmenu_string(obj.histo_channel_selector_popupmenu);
    %
    vals = obj.calculate_stat_image(image_type,channel); 
    
    % mmm - bad
    vals = vals(obj.object_mask~=0);
    
    hist(obj.histogram_axes,vals(:),obj.histogram_bins);            
    % can play with this - it works
    % daspect(obj.histogram_axes,[1 1 1]);
end
%-------------------------------------------------------------------------%        
function onHistoChannelSet(obj,~,~) 
    obj.onHistoSet;
end                         
    %-------------------------------------------------------------------------%                
        function save_settings(obj,~,~)        
            settings = [];
            settings.DefaultDirectory = obj.DefaultDirectory;
            settings.IcyDirectory = obj.IcyDirectory;
            settings.downsampling = obj.downsampling;            
            settings.histogram_bins = obj.histogram_bins; 
            settings.correlation_plot_width = obj.correlation_plot_width;
            settings.microns_per_pixel = obj.microns_per_pixel;            
            %
            xml_write([pwd filesep obj.data_settings_filename], settings);
        end % save_settings
    %-------------------------------------------------------------------------%                        
        function load_settings(obj,~,~)        
             if exist([pwd filesep obj.data_settings_filename],'file') 
                [ settings, ~ ] = xml_read ([pwd filesep obj.data_settings_filename]);                                 
                obj.DefaultDirectory = settings.DefaultDirectory;  
                obj.IcyDirectory = settings.IcyDirectory;
                obj.downsampling = settings.downsampling;
                obj.histogram_bins = settings.histogram_bins;
                obj.correlation_plot_width = settings.correlation_plot_width;
                obj.microns_per_pixel = settings.microns_per_pixel;                
             end
        end
    end
    
end