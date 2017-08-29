function [] = plot_velocon(data_dir, fig_num, results_field, ...
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



[~] = plot_contour(f, avg_lat, avg_long, map_size);
hold on

[velo_ax, ~] = plot_velo(f, avg_lat, avg_long, map_size);
hold on


%% overlay
over_ax = axes(f);
cd(orig_dir)


for i = 1:length(transect_names)
    disp(transect_names{i})
    cd(data_dir)
    load([transect_names{i} '_results.mat'])
    cd(orig_dir)
    plot_one_scatter(over_ax, results.easts, results.norths, ...
                     scale_factor*(results.(results_field) - field_mean));
    hold on
end
over_ax.CLim = color_limits;

over_cb = colorbar(over_ax,'Position',[.85 .11 .0675 .815]);
ylabel(over_cb, field_units) %line units

combine_plots(velo_ax, over_ax)
%scale up plot by 70% and tile from lower-left corner to upper-right
f.Position = [f.Number*20 40+f.Number*20 ...
              f.Position(3)*1.7 f.Position(4)*1.7];

    