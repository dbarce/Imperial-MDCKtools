function handles = setup_menu(obj,handles)

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
           
    downsampling = handles.data_controller.downsampling;    
    histogram_bins = handles.data_controller.histogram_bins;    
    correlation_plot_width = handles.data_controller.correlation_plot_width;    
    microns_per_pixel = handles.data_controller.microns_per_pixel;
    time_step = handles.data_controller.time_step;
        
    %================================= file

    menu_file = uimenu(obj.window,'Label','File');
    
    handles.menu_file_Data_Info = uimenu(menu_file,'Label','...','ForegroundColor','red','Enable','off');    
    handles.menu_file_new_window = uimenu(menu_file,'Label','New Window','Accelerator','N');
    handles.menu_file_load_native = uimenu(menu_file,'Label','Load (native)..','Separator','on');
    handles.menu_file_load_mat = uimenu(menu_file,'Label','Load (*.mat)..');    
    handles.menu_file_save_current_data = uimenu(menu_file,'Label','Save Current Image Data as *.mat','Separator','on');
            
    %================================= OMERO
    
    menu_OMERO = uimenu(obj.window,'Label','OMERO');

    handles.menu_OMERO_Working_Data_Info = uimenu(menu_OMERO,'Label','...','ForegroundColor','red','Enable','off');
    handles.menu_OMERO_login = uimenu(menu_OMERO,'Label','Log in to OMERO');    

    menu_OMERO_Set_Data = uimenu(menu_OMERO,'Label','Set User');
    handles.menu_OMERO_Switch_User = uimenu(menu_OMERO_Set_Data,'Label','Switch User...','Separator','on','Enable','off');    

    handles.menu_OMERO_Connect_To_Another_User = uimenu(menu_OMERO_Set_Data,'Label','Connect to another User...','Enable','off');    
    handles.menu_OMERO_Connect_To_Logon_User = uimenu(menu_OMERO_Set_Data,'Label','Connect to Logon User...','Enable','off');    

    handles.menu_OMERO_Reset_Logon = uimenu(menu_OMERO_Set_Data,'Label','Restore Logon','Separator','on','Enable','off');                
    
    handles.menu_OMERO_load = uimenu(menu_OMERO,'Label','Load Data','Separator','on','Enable','off');
    
    %================================= segmentation
    
    menu_segmentation = uimenu(obj.window,'Label','Segmentation');   
    handles.menu_segmentation_Go = uimenu(menu_segmentation,'Label','Go Segment everything');       
    handles.menu_segmentation_options = uimenu(menu_segmentation,'Label','Segmentation Options','Separator','on');    
    handles.menu_segmentation_add_source = uimenu(menu_segmentation,'Label','Add Source','Separator','on');        
    handles.menu_segmentation_delete_object = uimenu(menu_segmentation,'Label','Delete Object');            
    handles.menu_segmentation_select_object = uimenu(menu_segmentation,'Label','Select Object');                
    
    %================================= settings
    
    menu_settings = uimenu(obj.window,'Label','Settings');        
    handles.menu_settings_microns_per_pixel = uimenu(menu_settings,'Label',['Microns per pixel ' num2str(microns_per_pixel)]);                
    handles.menu_settings_downsampling = uimenu(menu_settings,'Label',['Downsampling ' num2str(downsampling)]); 
    handles.menu_settings_time_step = uimenu(menu_settings,'Label',['Time step ' num2str(time_step)],'Separator','on');  
    handles.menu_settings_histogram_bins = uimenu(menu_settings,'Label',['Histogram bins ' num2str(histogram_bins)],'Separator','on');        
    handles.menu_settings_corrplot_width = uimenu(menu_settings,'Label',['Correlation plot width ' num2str(correlation_plot_width)]);        
        
    %================================= visualization
    
    menu_visualization = uimenu(obj.window,'Label','Icy');
    menu_visualization_Icy_setup = uimenu(menu_visualization,'Label','Setup');        
    handles.menu_visualization_setup_Icy_directory = uimenu(menu_visualization_Icy_setup,'Label','Set Icy Directory');    
    handles.menu_visualization_start_Icy = uimenu(menu_visualization_Icy_setup,'Label','Start Icy');
    %
    handles.menu_visualization_send_movie_to_Icy = uimenu(menu_visualization,'Label','Send Movie','Separator','on');
    
    %================================= help   
    
%     menu_help = uimenu(obj.window,'Label','Help');
%     handles.menu_help_about = uimenu(menu_help,'Label','About...');
%     handles.menu_help_tracker = uimenu(menu_help,'Label','Open Issue Tracker...');
%     handles.menu_help_bugs = uimenu(menu_help,'Label','File Bug Report...');
        
end


