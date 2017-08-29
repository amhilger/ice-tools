%loads data, calculates geometric power and reflectivity, and saves
%downsampled version for plotting. This version uses a single attenuation
%rate for each transect, which is statistically fit.

save_dir = [pwd '/atten_fit_5km_loose'];
orig_dir = cd(save_dir);
cd(orig_dir)


clear results

avg_lat = -77.5; avg_long = -110;
M = 100; %downsampling factor
transect_names = get_transects();


%%

for i = 1:length(transect_names)
    disp(' '); disp(transect_names{i})
    cd(orig_dir) 
    results.ice_thick = load_ice_thickness(transect_names{i}, true); 
    [results.rdr_clear, ~] = load_rdr_clear(transect_names{i});
    [results.easts, results.norths] = load_position(transect_names{i});
    %load distance, altitude, and clearance - negative clearances are
    %flagged as NaN
    [~, results.rdr_height, results.srf_height] = ...
        load_heights(transect_names{i});
    results.bed_pow = load_bed_power(transect_names{i});
    
    cd ../BEDMAP
    results.rdr_dist = pathdistps(results.easts, results.norths);
    [results.lat, results.long] = ps2ll(results.easts, results.norths);
 
    %remove any piks that have a NaN for ice thickness, bed power, or
    %clearance
    good_piks = find(~isnan(results.ice_thick) & ...
                     ~isnan(results.bed_pow) & ...
                     ~isnan(results.rdr_clear));
    results = structfun(@(field) field(good_piks), results, ...
                        'UniformOutput', false);
    cd(orig_dir); cd('../tools')
    %do adaptive fitting with 10 km minimum segment
    results = adaptive_bed_power_binsearch_utig2(results, 5);
    
    %downsamples each field by factor of M
    %  (scalar fields are preserved as scalars)
    % M is calculated so that pik spacing averages 100m
    
%     M = ceil(100*length(results.rdr_dist)/results.rdr_dist(end));
%     cd(orig_dir)
%     results = structfun(@(s) downsample_data(s, M), results, ...
%                         'UniformOutput', false);
    %duplicate scalar fields C0, Cmin, atten_rate, and atten_uncertainty to
    %same length as other fields for plotting
    results = duplicate_scalar_fields(results);
    
    cd(save_dir)
    save_name = [transect_names{i} '_results.mat'];
    save(save_name, 'results'); clear results

    
end

cd(orig_dir)


    

