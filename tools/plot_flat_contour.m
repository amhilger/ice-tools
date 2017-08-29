function [] = plot_flat_contour(data_dir, fig_num, results_field, ...
                                scale_factor, subtract_field_mean, ...
                                manual_clim, field_units, map_size)
                            
orig_dir = pwd;
cd(data_dir);  cd(orig_dir)


if ~exist('map_size','var')
    map_size = 800;
end

transect_names = get_transect_names(data_dir);

avg_lat = compute_survey_median('lat',data_dir,transect_names);
avg_long = compute_survey_median('long',data_dir,transect_names);


if subtract_field_mean
    field_mean = compute_survey_mean(results_field, ...
                                       data_dir, transect_names);
else
    field_mean = 0;
end


%use survey minimum and maximum for color limits if none specified
if isempty(manual_clim)
    [survey_min, survey_max] = compute_survey_minmax(results_field, ...
                                                     data_dir, ...
                                                     transect_names);
    color_limits = scale_factor*([survey_min survey_max] - field_mean);
else
    color_limits = manual_clim;
end

%refresh current figure
f = figure(fig_num); close(f); f = figure(fig_num);
