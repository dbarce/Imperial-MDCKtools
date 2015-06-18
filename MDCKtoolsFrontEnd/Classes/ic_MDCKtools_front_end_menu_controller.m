classdef ic_MDCKtools_front_end_menu_controller < handle
        
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
                
        menu_OMERO_login;
        menu_OMERO_Working_Data_Info;
        menu_OMERO_Set_Dataset;
        menu_OMERO_Switch_User;
        menu_OMERO_Connect_To_Another_User;
        menu_OMERO_Connect_To_Logon_User;
        menu_OMERO_Reset_Logon; 
            %                   
            menu_OMERO_load;
            
        menu_visualization_setup_Icy_directory;
        menu_visualization_start_Icy;
        
        menu_visualization_send_current_proj_to_Icy;
        menu_visualization_send_current_volm_to_Icy;        

        % holy cows
        omero_data_manager;     
        data_controller;
        
        %
        menu_file_Data_Info;
        menu_file_new_window;
        menu_file_load_native;
        menu_file_load_mat;
        menu_file_save_current_data;

        %================================= segmentation

        menu_segmentation_options;
        menu_segmentation_Go;
        menu_segmentation_add_source;
        menu_segmentation_delete_object;
        menu_segmentation_select_object;        

        %================================= settings

        menu_settings_downsampling;
        menu_settings_histogram_bins;
        menu_settings_corrplot_width;        
        menu_settings_microns_per_pixel;
                                
    end
    
    properties(SetObservable = true)

    end
        
    methods
        
        %------------------------------------------------------------------        
        function obj = ic_MDCKtools_front_end_menu_controller(handles)
            
            assign_handles(obj,handles);
            set_callbacks(obj);
            
            obj.data_controller.menu_controller = obj;
                                                                        
        end
        %------------------------------------------------------------------
        function set_callbacks(obj)
            
             mc = metaclass(obj);
             obj_prop = mc.Properties;
             obj_method = mc.Methods;
                          
             % Search for properties with corresponding callbacks
             for i=1:length(obj_prop)
                prop = obj_prop{i}.Name;
                if strncmp(prop,'menu_',5)
                    method = [prop '_callback'];
                    matching_methods = findobj([obj_method{:}],'Name',method);
                    if ~isempty(matching_methods)               
                        eval(['set(obj.' prop ',''Callback'',@obj.' method ')' ]);
                    end
                end          
             end
             
        end
        %------------------------------------------------------------------                                       
        function menu_file_new_window_callback(obj,~,~)
            ic_MDCKtools();
        end
                        
        %------------------------------------------------------------------
        % OMERO
        %------------------------------------------------------------------
        function menu_OMERO_login_callback(obj,~,~)
            obj.omero_data_manager.Omero_logon();
            
            if ~isempty(obj.omero_data_manager.session)
                props = properties(obj);
                OMERO_props = props( strncmp('menu_OMERO',props,10) );
                for i=1:length(OMERO_props)
                    set(obj.(OMERO_props{i}),'Enable','on');
                end
            end            
        end
        %------------------------------------------------------------------
        function menu_OMERO_Set_Dataset_callback(obj,~,~)            
            infostring = obj.omero_data_manager.Set_Dataset();
            if ~isempty(infostring)
                set(obj.menu_OMERO_Working_Data_Info,'Label',infostring,'ForegroundColor','blue');
                set(obj.menu_Batch_Indicator_Src,'Label',infostring,'ForegroundColor','blue');                
            end;
        end                        
        %------------------------------------------------------------------        
        function menu_OMERO_Reset_Logon_callback(obj,~,~)
            obj.omero_data_manager.Omero_logon();
        end
        %------------------------------------------------------------------        
        function menu_OMERO_Switch_User_callback(obj,~,~)
            %delete([ pwd '\' obj.omero_data_manager.omero_logon_filename ]);
            obj.omero_data_manager.Omero_logon_forced();
        end        
        %------------------------------------------------------------------
        function menu_OMERO_Connect_To_Another_User_callback(obj,~,~)
            obj.omero_data_manager.Select_Another_User();
            obj.omero_data_manager.dataset = [];
            obj.data_controller.proj = [];
            obj.data_controller.volm = [];            
            obj.data_controller.on_proj_and_volm_clear;
            set(obj.menu_OMERO_Working_Data_Info,'Label','...','ForegroundColor','red');
        end                            
        %------------------------------------------------------------------
        function menu_OMERO_Connect_To_Logon_User_callback(obj,~,~)            
            obj.omero_data_manager.userid = obj.omero_data_manager.session.getAdminService().getEventContext().userId;
            obj.omero_data_manager.dataset = [];
            obj.data_controller.proj = [];
            obj.data_controller.volm = [];            
            obj.data_controller.on_proj_and_volm_clear;
            set(obj.menu_OMERO_Working_Data_Info,'Label','...','ForegroundColor','red');
        end  
         %------------------------------------------------------------------
        function menu_OMERO_set_single_callback(obj, ~, ~)                                               
            infostring = obj.data_controller.OMERO_load_single(obj.omero_data_manager,true); % verbose
            if ~isempty(infostring)
                set(obj.menu_OMERO_Working_Data_Info,'Label',infostring,'ForegroundColor','blue','Enable','on');
                set(obj.menu_file_Working_Data_Info,'Label','...','Enable','off');                
                obj.data_controller.current_filename = [];
                set(obj.menu_settings_Zrange,'Label','Z range : full');
                obj.data_controller.Z_range = []; % no selection                                    
            end;            
        end
         %------------------------------------------------------------------
        function menu_OMERO_set_multiple_callback(obj, ~, ~)
            obj.data_controller.OMERO_load_multiple(obj.omero_data_manager);
        end
        
        %------------------------------------------------------------------
        % OMERO
        %------------------------------------------------------------------                                
                                        
         %------------------------------------------------------------------        
        function menu_tools_preferences_callback(obj,~,~)
            profile = ic_MDCKtools_profile_controller();
            profile.set_profile();
        end        
         %------------------------------------------------------------------                
        
        function menu_file_load_native_callback(obj, ~, ~)
            obj.data_controller.load_native(true); % verbose true
        end        
         %------------------------------------------------------------------                

        function menu_file_load_mat_callback(obj, ~, ~)
            obj.data_controller.load_mat();            
        end        
         %------------------------------------------------------------------                
            
        function menu_file_save_current_data_callback(obj, ~, ~)
            obj.data_controller.save_curent_data_mat();            
        end        
         %------------------------------------------------------------------                            

        %================================= segmentation

        function menu_segmentation_options_callback(obj, ~, ~)            
        end        
         %------------------------------------------------------------------                
            
        function menu_segmentation_Go_callback(obj, ~, ~)
            obj.data_controller.apply_segmentation();                        
        end        
         %------------------------------------------------------------------                
            
        function menu_segmentation_add_source_callback(obj, ~, ~)
            obj.data_controller.add_source();                                    
        end        
         %------------------------------------------------------------------                
            
        function menu_segmentation_delete_object_callback(obj, ~, ~)
            obj.data_controller.delete_object();                        
        end        
         %------------------------------------------------------------------                
        function menu_segmentation_select_object_callback(obj, ~, ~)
            obj.data_controller.select_object();                        
        end        
         %------------------------------------------------------------------                
                  
        %================================= settings

        function menu_settings_downsampling_callback(obj, ~, ~)            
             value = fix(enter_value());
             if isempty(value) || ~isnumeric(value) || value==obj.data_controller.downsampling, return, end;
             if value > 64, value = 64; end
             if value < 1 , value = 1; end
             obj.data_controller.downsampling = value;            
             set(obj.menu_settings_downsampling,'Label',['Downsampling ' num2str(obj.data_controller.downsampling)]);            
             
             obj.data_controller.clear_all();
        end        
         %------------------------------------------------------------------                
            
        function menu_settings_histogram_bins_callback(obj, ~, ~)
             value = fix(enter_value());
             if isempty(value) || ~isnumeric(value) || value==obj.data_controller.histogram_bins, return, end;
             if value < 10, value = 10; end
             obj.data_controller.histogram_bins = value;            
             set(obj.menu_settings_histogram_bins,'Label',['Histogram bins ' num2str(obj.data_controller.histogram_bins)]);
             obj.data_controller.onHistoSet;
        end        
         %------------------------------------------------------------------                
            
        function menu_settings_corrplot_width_callback(obj, ~, ~)       
             value = fix(enter_value());
             if isempty(value) || ~isnumeric(value) || value==obj.data_controller.correlation_plot_width, return, end;
             if value < 10, value = 10; end
             obj.data_controller.correlation_plot_width = value;            
             set(obj.menu_settings_corrplot_width,'Label',['Correlation plot width ' num2str(obj.data_controller.correlation_plot_width)]);                                     
             obj.data_controller.onCorrplotXSet;
        end        
        
         %------------------------------------------------------------------                
            
        function menu_settings_microns_per_pixel_callback(obj, ~, ~)       
             value = fix(enter_value());
             if isempty(value) || ~isnumeric(value) || value==obj.data_controller.microns_per_pixel || value <=0, return, end;
             obj.data_controller.microns_per_pixel = value;            
             set(obj.menu_settings_microns_per_pixel,'Label',['Microns per pixel ' num2str(obj.data_controller.microns_per_pixel)]);                                                 
        end        
                
         %------------------------------------------------------------------                
                                                           
    %================================= % VANITY       
    
        %------------------------------------------------------------------
        function menu_help_about_callback(obj, ~, ~)
            % to do
        end            
        %------------------------------------------------------------------
        function menu_help_tracker_callback(obj, ~, ~)
            % to do
        end            
        %------------------------------------------------------------------
        function menu_help_bugs_callback(obj, ~, ~)
            % to do
        end
                            
    end
    
end
