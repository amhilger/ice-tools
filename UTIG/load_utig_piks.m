%loads data, calculates geometric power and reflectivity, and saves
%downsampled version for plotting. This version uses a single attenuation
%rate for each transect, which is statistically fit.
save_dir =  '/data/cees/amhilger/UTIG/piks_lo_hi_all/';
orig_dir = cd(save_dir);
cd(orig_dir)

clear results

avg_lat = -77.5; avg_long = -110;
transect_names = get_transects();
filterNaN = false;

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
    [results.bed_pik_sample,~] = load_bed_delay(transect_names{i});
    
     
    cd ../BEDMAP
    results.rdr_dist = pathdistps(results.easts, results.norths);
    [results.lat, results.long] = ps2ll(results.easts, results.norths);
    
    cd ../tools
    results.heading = calc_heading_1km(results.easts, results.norths, ...
        results.rdr_dist);
    
    if filterNaN
        %remove any piks that have a NaN for ice thickness, bed power, or
        %clearance
        good_piks = find(~isnan(results.ice_thick) & ...
                         ~isnan(results.rdr_clear) & ...
                         ~isnan(results.bed_pow_lo) & ...
                         ~isnan(results.bed_pow_hi));
        results = structfun(@(field) field(good_piks), results, ...
                            'UniformOutput', false);
    end
    
    
    cd ../UTIG
    results.bed_pow = combine_bed_pow(results.bed_pow_lo, ...
                                      results.bed_pow_hi);
    
    cd ../tools
    results = standardize_fields(results);
    results = fill_in_fields(results);

    
    cd(save_dir)
    save_name = [transect_names{i} '_results.mat'];
    save(save_name, 'results'); clear results

    
end

cd(orig_dir)


    

