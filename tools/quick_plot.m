orig_dir = pwd;
%cd ../; load_dir = [pwd '/UTIG/piks_agg_plottable']; cd ./tools
%cd ../; load_dir = [pwd '/BBAS_PIG/agg_repick_xover_plottable']; cd ./tools
cd ../; load_dir = [pwd '/ASE/cross_calib_all_plot']; cd ./tools
results_field = 'abrupt';
fig_num = 8;
map_size = 1050; %km
%clim_override = [0 15]

if any(strcmp(results_field, {'atten_rate', 'atten_unc'}))
    scale_factor = 1000;
    field_units = 'dB/km';
    if strcmp(results_field, 'atten_rate')
        plot_clim = [0 20];
    else
        plot_clim = [0 3];
    end
elseif any(strcmp(results_field, {'bed_slope','srf_slope'}))
    field_units = '% grade';
    scale_factor = 100;
else
    scale_factor = 1;
end

if any(strcmp(results_field, {'reflect', 'rdr_geo_pow', ...
                              'bm_geo_pow', 'bed_pow', ...
                              'bed_pow_xover', 'geo_pow_xover', ...
                              'bed_pow_lo', 'bed_pow_hi', ...
                              'bed_pow_calib', 'geo_pow_calib', ...
                              'max_pow', 'agg_pow', 'snr_agg', ...
                              'geo_pow_max', 'geo_pow_agg', ...
                              'geo_pow_max_xover', 'geo_pow_agg_xover', ...
                              'geo_pow_max_calib', 'geo_pow_agg_calib'}))
    field_units = 'dB';
    subtract_mean = false; %subtract _survey_ mean
    %plot_clim = [-25 25];
else
    subtract_mean = false;
end

if any(strcmp(results_field, {'rdr_thick','ice_thick','bm_thick', ...
                              'bm_bed_height','bm_srf_height', ...
                              'rdr_clear', 'rdr_dist', ...
                              'rdr_height','srf_height'}))
    field_units = 'm';
end 

if any(strcmp(results_field, {'fit_dist'}))
    field_units = 'km';
end

if any(strcmp(results_field, {'ft_range'}))
    field_units = 'samples';
    scale_factor = 2;
end

if any(strcmp(results_field, {'C_0', 'C_min','survey_num','abrupt', 'peakiness'}))
    field_units = '';
end

if any(strcmp(results_field, {'heading'}))
    field_units = 'deg';
end

if ~exist('plot_clim','var')
    plot_clim = []; %empty triggers autoscaling based on min/max
end

if exist('clim_override','var')
    plot_clim = clim_override;
end
    
plot_contour_scatter(load_dir, fig_num, results_field, ...
               scale_factor, subtract_mean, ...
               plot_clim, field_units, map_size)
clear plot_clim        
if exist('clim_override','var')
    clear clim_override
end
cd(orig_dir)
