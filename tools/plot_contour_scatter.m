function [] = plot_contour_scatter(data_dir, fig_num, results_field, ...
                           scale_factor, subtract_mean, ...
                           manual_clim, field_units, plot_size)




transect_names = get_transect_names(data_dir);
survey = combine_results(data_dir, transect_names, '_results.mat');

if subtract_mean
    field_mean = mean(survey.(results_field),'omitnan');
else
    field_mean = 0;
end


if isempty(manual_clim)
    color_min = prctile(survey.(results_field), 2.5); %min(survey.(results_field))
    color_max = prctile(survey.(results_field), 97.5); %max(survey.(results_field))
    survey_95_range = prctile(survey.(results_field), 97.5) - ...
                        prctile(survey.(results_field), 2.5)
    survey_98_range = prctile(survey.(results_field), 99) - ...
        prctile(survey.(results_field), 1)
    survey_99_range = prctile(survey.(results_field), 99.5) - ...
        prctile(survey.(results_field), 0.5)
    survey_max = prctile(survey.(results_field), 100) 
    survey_min = prctile(survey.(results_field), 0)
    color_limits = scale_factor*([color_min color_max] - field_mean);
else
    color_limits = manual_clim;
end




plot_data = scale_factor * (survey.(results_field) - field_mean);

close(figure(fig_num)); f = figure(fig_num);
avg_lat = median(survey.lat);
avg_lon = median(survey.long);

plot_contour(f, avg_lat, avg_lon, plot_size);

hold on;
        
scatter(survey.easts(~isnan(plot_data)), ...
        survey.norths(~isnan(plot_data)), ...
        12*ones('like', plot_data(~isnan(plot_data))), ...
        plot_data(~isnan(plot_data)),...
        'filled');

    
caxis(color_limits)
colormap('jet')
cb = colorbar; ylabel(cb, field_units)


f.Position = [f.Number*20 40+f.Number*20 ...
              f.Position(3)*1.7 f.Position(4)*1.7];