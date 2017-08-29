function [] = plot_contour_surf(data_dir, fig_num, results_field, ...
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
    survey_min = min(survey.(results_field));
    survey_max = max(survey.(results_field));
    color_limits = scale_factor*([survey_min survey_max] - field_mean);
else
    color_limits = manual_clim;
end



F = scatteredInterpolant(survey.easts, survey.norths, ...
                         survey.(results_field), ...
                         'natural', 'none');
easts_grid  = linspace(min(survey.easts),  max(survey.easts),  N_interp);
norths_grid = linspace(min(survey.norths), max(survey.norths), N_interp);
[X,Y] = meshgrid(easts_grid, norths_grid);
V = scale_factor * (F(X,Y) - field_mean);

close(figure(fig_num)); f = figure(fig_num);
avg_lat = median(survey.lat);
avg_lon = median(survey.long);

plot_contour(f, avg_lat, avg_lon, plot_size)

hold on;
h = surface(X, Y, zeros(size(X)), V, ...
        'FaceAlpha' ,0.5, ...
        'EdgeColor','none', ...
        'FaceColor', 'flat');
    
h.Parent.CLim = color_limits;
colormap(h.Parent, 'jet')

cb = colorbar; ylabel(cb, field_units)


f.Position = [f.Number*20 40+f.Number*20 ...
              f.Position(3)*1.7 f.Position(4)*1.7];