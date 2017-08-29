%loads data, calculates geometric power and reflectivity, and saves
%downsampled version for plotting. This version uses a single attenuation
%rate for each transect, which is statistically fit.
save_dir =  '/data/cees/amhilger/UTIG/piks_lo_hi/';
orig_dir = cd(save_dir);
cd(orig_dir)

clear results

avg_lat = -77.5; avg_long = -110;
transect_names = get_transects();

for i = 1:length(transect_names)
    disp(' '); disp(transect_names{i})
    cd(orig_dir) 
    [results.ice_thick, results.ice_thick_lo] = ...
        load_ice_thickness(transect_names{i}, true); 
    [results.rdr_clear, ~] = load_rdr_clear(transect_names{i});
    [results.easts, results.norths] = load_position(transect_names{i});
    %load distance, altitude, and clearance - negative clearances are
    %flagged as NaN
    [~, results.rdr_height, results.srf_height] = ...
        load_heights(transect_names{i});
    [results.bed_pow_lo, results.bed_pow_hi] = ...
        load_bed_power(transect_names{i});
    
     
    cd ../BEDMAP
    results.rdr_dist = pathdistps(results.easts, results.norths);
    [results.lat, results.long] = ps2ll(results.easts, results.norths);
    
    cd ../tools
    results.heading = calc_heading_1km(results.easts, results.norths, ...
        results.rdr_dist);
    
    %remove any piks that have a NaN for ice thickness, bed power, or
    %clearance
    good_piks = find(~isnan(results.ice_thick) & ...
                     ~isnan(results.rdr_clear) & ...
                     ~isnan(results.bed_pow_lo) & ...
                     ~isnan(results.bed_pow_hi));
    results = structfun(@(field) field(good_piks), results, ...
                        'UniformOutput', false);
    
    cd ../UTIG
    results.bed_pow = combine_bed_pow(results.bed_pow_lo, ...
                                      results.bed_pow_hi);
    
    cd ../tools
    results = standardize_fields(results);
    results = fill_in_fields(results);
                    
    %cd(orig_dir); cd('../tools')
    %geometric power implicitly rounds negative clearances up to zero
%     results.geo_pow = geo_correct_power(results.bed_pow, ...
%                                         results.rdr_clear, ...
%                                         results.ice_thick);

                                   
    %cd ../tools
    %downsamples each field by factor of M
    %  (scalar fields are preserved as scalars)
    % M is calculated so that pik spacing averages 1 km
%     M = ceil(1000*length(results.rdr_dist)/results.rdr_dist(end));
%     results = structfun(@(s) downsample_data(s, M), results, ...
%                         'UniformOutput', false);
    

    
    cd(save_dir)
    save_name = [transect_names{i} '_results.mat'];
    save(save_name, 'results'); clear results

    
end

cd(orig_dir)


    

