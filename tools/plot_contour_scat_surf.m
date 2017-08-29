function [] = plot_contour_scat_surf(data_dir, fig_num, results_field, ...
                           scale_factor, subtract_mean, ...
                           manual_clim, field_units, plot_size)

N_interp = 500;


transect_names = get_transect_names(data_dir);
survey = combine_results(data_dir, transect_names, '_results.mat');

if subtract_mean
    field_mean = mean(survey.(results_field),'omitnan');
else
    field_mean = 0;
end





if isempty(manual_clim)
    survey_min = prctile(survey.(results_field), 2.5); %min(survey.(results_field))
    survey_max = prctile(survey.(results_field), 97.5); %max(survey.(results_field))
    survey_95_range = prctile(survey.(results_field), 97.5) - ...
                        prctile(survey.(results_field), 2.5)
    survey_98_range = prctile(survey.(results_field), 99) - ...
        prctile(survey.(results_field), 1)
    survey_99_range = prctile(survey.(results_field), 99.5) - ...
        prctile(survey.(results_field), 0.5)
    survey_100_range = prctile(survey.(results_field), 100) - ...
        prctile(survey.(results_field), 0)
    color_limits = scale_factor*[survey_min survey_max] - field_mean;
else
    color_limits = manual_clim;
end




plot_data = scale_factor * (survey.(results_field) - field_mean);

close(figure(fig_num)); f = figure(fig_num);
avg_lat = median(survey.lat);
avg_lon = median(survey.long);

plot_contour(f, avg_lat, avg_lon, plot_size);
caxis(color_limits)
colormap('jet')
cb = colorbar; ylabel(cb, field_units)

hold on;
        
scatter(survey.easts,survey.norths, ...
        3*ones(size(survey.norths)),plot_data,...
        'filled');
    
F = scatteredInterpolant(survey.easts, survey.norths, ...
                         survey.(results_field), ...
                         'natural', 'none');
easts_grid  = linspace(min(survey.easts),  max(survey.easts),  N_interp);
norths_grid = linspace(min(survey.norths), max(survey.norths), N_interp);
[X,Y] = meshgrid(easts_grid, norths_grid);
V = scale_factor * (F(X,Y) - field_mean);



h = surface(X, Y, zeros(size(X)), V, ...
        'FaceAlpha' ,0.5, ...
        'EdgeColor','none', ...
        'FaceColor', 'flat');
    
h.Parent.CLim = color_limits;
colormap(h.Parent, 'jet')


f.Position = [f.Number*20 40+f.Number*20 ...
              f.Position(3)*1.7 f.Position(4)*1.7];