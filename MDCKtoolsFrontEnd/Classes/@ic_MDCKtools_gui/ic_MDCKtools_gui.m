classdef ic_MDCKtools_gui
        
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
   
    properties
        
        window;
        data_controller;
        menu_controller;
        
    end
    
    methods
      
        function obj = ic_MDCKtools_gui(wait,require_auth)
                                                    
            if nargin < 1
                wait = false;
            end
            
            if nargin < 2
                require_auth = false;
            end
            
            if ~isdeployed
                addpath_MDCKtools;
            else
                wait = true;
            end
                                  
            profile = ic_MDCKtools_profile_controller();
            profile.load_profile();
            

            % Try and read in version number
            try
                v = textread(['GeneratedFiles' filesep 'version.txt'],'%s');
                v = v{1};
            catch
                v = '[unknown version]';
            end                                              

            obj.window = figure( ...
                'Name', ['ic_MDCKtools ' v], ...
                'NumberTitle', 'off', ...
                'MenuBar', 'none', ...
                'units','normalized','outerposition',[0 0 1 1], ...                
                'Toolbar', 'none', ...
                'DockControls', 'off', ...                
                'Resize', 'off', ...                
                'HandleVisibility', 'off', ...
                'Visible','off');
                                   
            handles = guidata(obj.window); 
                                                        
            handles.version = v;
            handles.window = obj.window;
            handles.use_popup = true;

            handles = obj.setup_layout(handles);            
            
            handles.data_controller = ic_MDCKtools_data_controller(handles);                        
                        
            handles.omero_data_manager = ic_MDCKtools_omero_data_manager(handles);            
            
            handles = obj.setup_menu(handles);   
                        
            handles.menu_controller = ic_MDCKtools_front_end_menu_controller(handles);
                        
            guidata(obj.window,handles);
                        
            loadOmero();
                       
            % find path to OMEuiUtils.jar - approach copied from
            % bfCheckJavaPath
            
            % first check it isn't already in the dynamic path
            jPath = javaclasspath('-dynamic');
            utilJarInPath = false;
            for i = 1:length(jPath)
                if strfind(jPath{i},'OMEuiUtils.jar');
                    utilJarInPath = true;
                    break;
                end
            end
                
            if ~utilJarInPath
                path = which('OMEuiUtils.jar');
                if isempty(path)
                    path = fullfile(fileparts(mfilename('fullpath')), 'OMEuiUtils.jar');
                end
                if ~isempty(path) && exist(path, 'file') == 2
                    javaaddpath(path);
                else 
                     assert('Cannot automatically locate an OMEuiUtils JAR file');
                end
            end
                                               
            % verify that enough memory is allocated
            bfCheckJavaMemory();
          
            % load both bioformats & OMERO
            autoloadBioFormats = 1;

            % load the Bio-Formats library into the MATLAB environment
            status = bfCheckJavaPath(autoloadBioFormats);
            assert(status, ['Missing Bio-Formats library. Either add loci_tools.jar '...
                'to the static Java path or add it to the Matlab path.']);

            % initialize logging
            loci.common.DebugTools.enableLogging('INFO');
            java.lang.System.setProperty('javax.xml.transform.TransformerFactory', 'com.sun.org.apache.xalan.internal.xsltc.trax.TransformerFactoryImpl');            
            
            close all;
            
            set(obj.window,'Visible','on');
            set(obj.window,'CloseRequestFcn',@obj.close_request_fcn);
                        
            if wait
                waitfor(obj.window);
            end                            
            
        end
        
        function vx = split_ver(obj,ver)
            % Convert version string into a number
            tk = regexp(ver,'([0-9]+).([0-9]+).([0-9]+)','tokens');
            if ~isempty(tk{1})
                tk = tk{1};
                vx = str2double(tk{1})*1e6 + str2double(tk{2})*1e3 + str2double(tk{3});
            else 
                vx = 0;
            end
        end
        
        function close_request_fcn(obj,~,~)
            
           handles = guidata(obj.window);
           client = handles.omero_data_manager.client;
            
            if ~isempty(client)                
                %
                disp('Closing OMERO session');
                client.closeSession();
                %
                 handles.omero_data_manager.session = [];
                 handles.omero_data_manager.client = [];
            end
            
            % Make sure we clean up all the left over classes
            names = fieldnames(handles);
                      
            for i=1:length(names)
                % Check the field is actually a handle and isn't the window
                % which we need to close right at the end
                if ~strcmp(names{i},'window') && all(ishandle(handles.(names{i})))
                    delete(handles.(names{i}));
                end
            end
            
            % Finally actually close window
            delete(handles.window);
            
        end
        
        function handles = setup_layout(obj, handles)
            % 
            n1 = 20;
            n2 = 1;
            main_layout = uiextras.VBox( 'Parent', obj.window, 'Spacing', n1 );
            top_layout = uiextras.VBox( 'Parent', main_layout, 'Spacing', n1 );            
            lower_layout = uiextras.HBox( 'Parent', main_layout, 'Spacing', n1 );
            set(main_layout,'Sizes',[-n1 -n2]);
            %    

            
            display_tabpanel = uiextras.TabPanel( 'Parent', top_layout, 'TabSize', 80 );
            handles.display_tabpanel = display_tabpanel;                                 
            %
            layout1 = uiextras.VBox( 'Parent', display_tabpanel, 'Spacing', n1 );                
            handles.scene_panel = uipanel( 'Parent', layout1 );
            %
            layout2 = uiextras.VBox( 'Parent', display_tabpanel, 'Spacing', n1 );    
            handles.globals_panel = uipanel( 'Parent', layout2 );
            
            layout3 = uiextras.VBox( 'Parent', display_tabpanel, 'Spacing', n1 );    
            handles.corrplot_panel = uipanel( 'Parent', layout3 );

            layout4 = uiextras.VBox( 'Parent', display_tabpanel, 'Spacing', n1 );    
            handles.histogram_panel = uipanel( 'Parent', layout4 );
            
            %
            set(display_tabpanel, 'TabNames', {'Scene','Globals','Correlation plot','Histogram'});
            set(display_tabpanel, 'SelectedChild', 1); 
            
            handles.display_tabpanel = display_tabpanel;            
            handles.lower_layout = lower_layout;
            
            
%             display_tabpanel = uiextras.TabPanel( 'Parent', top_layout, 'TabSize', 80 );
%             handles.display_tabpanel = display_tabpanel;                                 
%             %
%             layout1 = uiextras.VBox( 'Parent', display_tabpanel, 'Spacing', n1 );    
%             handles.scene_panel = uipanel( 'Parent', layout1 );
%             %
%             layout2 = uiextras.VBox( 'Parent', display_tabpanel, 'Spacing', n1 );    
%             handles.globals_panel = uipanel( 'Parent', layout2 );
%             
%             layout3 = uiextras.VBox( 'Parent', display_tabpanel, 'Spacing', n1 );    
%             handles.corrplot_panel = uipanel( 'Parent', layout3 );
% 
%             layout4 = uiextras.VBox( 'Parent', display_tabpanel, 'Spacing', n1 );    
%             handles.histogram_panel = uipanel( 'Parent', layout4 );
%             
%             %
%             set(display_tabpanel, 'TabNames', {'Scene','Globals','Correlation plot','Histogram'});
%             set(display_tabpanel, 'SelectedChild', 1); 
%             
%             handles.display_tabpanel = display_tabpanel;

            
            







            


            
            
            
            
                                    
%             %
%             % lower..
%             lower_left_layout = uiextras.VButtonBox( 'Parent', lower_layout );
%             handles.onCheckOut_button = uicontrol( 'Parent', lower_left_layout, 'String', 'Check out','Callback', @obj.onCheckOut );
%             handles.onGo_button = uicontrol( 'Parent', lower_left_layout, 'String', 'Go','Callback', @obj.onGo );            
%             handles.onCancel_button = uicontrol( 'Parent', lower_left_layout, 'String', 'Cancel','Callback', @obj.onCancel ); 
%             lower_right_layout = uiextras.Grid( 'Parent', lower_layout, 'Spacing', 3, 'Padding', 3, 'RowSizes',-1,'ColumnSizes',-1  );                        
%             set( lower_left_layout, 'ButtonSize', [100 20], 'Spacing', 5 );   
%             set(lower_layout,'Sizes',[-1 -4]);            
%             % lower..
%             %            
%             % "General" panel            
%             general_layout = uiextras.Grid( 'Parent', handles.panel1, 'Spacing', 10, 'Padding', 16, 'RowSizes',-1,'ColumnSizes',-1  );
%             uicontrol( 'Style', 'text', 'String', 'Modulo ',       'HorizontalAlignment', 'right', 'Parent', general_layout );
%             uicontrol( 'Style', 'text', 'String', 'Modulo Variable ', 'HorizontalAlignment', 'right', 'Parent', general_layout );
%             uicontrol( 'Style', 'text', 'String', 'Modulo Units ',    'HorizontalAlignment', 'right', 'Parent', general_layout );
%             uicontrol( 'Style', 'text', 'String', 'FLIM mode ',    'HorizontalAlignment', 'right', 'Parent', general_layout );
%             uicontrol( 'Style', 'text', 'String', 'Extension ',    'HorizontalAlignment', 'right', 'Parent', general_layout );
%             %
% %             handles.Modulo_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', obj.Modulo_popupmenu_str, 'Parent', general_layout,'Callback', @obj.onModuloSet ); 
% %             handles.Variable_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', obj.Variable_popupmenu_str, 'Parent', general_layout,'Callback', @obj.onVariableSet );    
% %             handles.Units_popupmenu = uicontrol( 'Style', 'popupmenu', 'String',obj.Units_popupmenu_str, 'Parent', general_layout,'Callback', @obj.onUnitsSet );    
% %             handles.FLIM_mode_popupmenu = uicontrol( 'Style', 'popupmenu', 'String',obj.FLIM_mode_popupmenu_str, 'Parent', general_layout,'Callback', @obj.onFLIM_modeSet );    
% %             handles.Extension_popupmenu = uicontrol( 'Style', 'popupmenu', 'String',obj.Extension_popupmenu_str, 'Parent', general_layout,'Callback', @obj.onExtensionSet );            
%             %
%             uiextras.Empty( 'Parent', general_layout );
%             uiextras.Empty( 'Parent', general_layout );
%             uiextras.Empty( 'Parent', general_layout );    
% %             handles.Attr1_text = uicontrol( 'Style', 'text', 'String', obj.Attr1,'HorizontalAlignment', 'right', 'Parent', general_layout);
% %             handles.Attr2_text = uicontrol( 'Style', 'text', 'String', obj.Attr2,'HorizontalAlignment', 'right', 'Parent', general_layout);
%             %
%             uiextras.Empty( 'Parent', general_layout );
%             uiextras.Empty( 'Parent', general_layout );
%             uiextras.Empty( 'Parent', general_layout );
% %             handles.Attr1_ZCT_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', obj.Attr1_ZCT_popupmenu_str, 'Parent', general_layout,'Callback', @obj.onAttr1_ZCT  );    
% %             handles.Attr2_ZCT_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', obj.Attr2_ZCT_popupmenu_str, 'Parent', general_layout,'Callback', @obj.onAttr2_ZCT  );    
%             %
%             uiextras.Empty( 'Parent', general_layout );
%             uiextras.Empty( 'Parent', general_layout );
%             uiextras.Empty( 'Parent', general_layout );
% %             handles.Attr1_meaning_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', obj.Attr1_meaning_popupmenu_str, 'Parent', general_layout,'Callback', @obj.onAttr1_meaning  );    
% %             handles.Attr2_meaning_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', obj.Attr2_meaning_popupmenu_str, 'Parent', general_layout,'Callback', @obj.onAttr2_meaning  );    
%             %            
%             set(general_layout,'RowSizes',[22 22 22 22 22]);
%             set(general_layout,'ColumnSizes',[90 170 120 50 100]);
%             %
%             % lower right
%             handles.Src_name = uicontrol( 'Style', 'text', 'String', '???', 'HorizontalAlignment', 'center', 'Parent', lower_right_layout,'BackgroundColor','white' );
%             handles.Dst_name = uicontrol( 'Style', 'text', 'String', '???', 'HorizontalAlignment', 'center', 'Parent', lower_right_layout,'BackgroundColor','white' );
%             handles.Indi_name = uicontrol( 'Style', 'text', 'String', '???', 'HorizontalAlignment', 'center', 'Parent', lower_right_layout,'BackgroundColor','red' );
%             set(lower_right_layout,'RowSizes',[-1 -1 -1]);
%             set(lower_right_layout,'ColumnSizes',-1);
%             %
%             anno_layout = uiextras.Grid( 'Parent', handles.panel2, 'Spacing', 10, 'Padding', 16, 'RowSizes',-1,'ColumnSizes',-1  );
%             uicontrol( 'Style', 'text', 'String', 'FOV extensions',       'HorizontalAlignment', 'right', 'Parent', anno_layout );
%             uicontrol( 'Style', 'text', 'String', 'Dataset extensions', 'HorizontalAlignment', 'right', 'Parent', anno_layout );
%             %              
%             handles.FOV_Annot_Extension_template = uicontrol( 'Style', 'edit', 'Parent', anno_layout,'BackgroundColor','white','Callback',@obj.onSetFOVAnnotationExtensionEdit ); 
%             handles.Dataset_Annot_Extension_template = uicontrol( 'Style', 'edit','Parent', anno_layout,'BackgroundColor','white','Callback',@obj.onSetDatasetAnnotationExtensionEdit   );    
%             %
%             handles.FOV_Annot_Extension_dflt = uicontrol('String', 'All', 'Parent', anno_layout, 'Callback',@obj.onSetFOVAnnotationExtensionsAll ); 
%             handles.Dataset_Annot_Extension_dflt = uicontrol('String', 'All', 'Parent', anno_layout, 'Callback',@obj.onSetDatasetAnnotationExtensionsAll ); 
%             %
%             set(anno_layout,'RowSizes',[22 22 22 22]);
%             set(anno_layout,'ColumnSizes',[95 400 45]);            
        end % setup_layout        
               
    end
    
end
