%loads data, calculates geometric power and reflectivity, and saves
%downsampled version for plotting. This version uses a single attenuation
%rate for each transect, which is statistically fit.

save_dir = [pwd '/scratch'];
load_dir = [pwd '/atten_fit_5km'];
orig_dir = cd(save_dir);
cd(orig_dir)

fit_dist = 5; 
use_bm_thick = false;
loose_unc = true;

clear results

avg_lat = -77.5; avg_long = -110;
transect_names = get_transects(load_dir);


%%

for i = 1:length(transect_names)
    disp(' '); disp(transect_names{i}); pause(0.25)
    cd(load_dir); load([transect_names{i} '_results.mat']); 
    cd(orig_dir); cd ../tools
    
    results = standardize_fields(results);
    results = sanitize_results(results);
    results = fill_in_fields(results);
    
    
    good_piks = find(~isnan(results.rdr_thick) & ...
                     ~isnan(results.bed_pow) & ...
                     ~isnan(results.rdr_clear) & ...
                     results.bed_pow > 58 & ...
                     results.rdr_thick >= 50);
    results = structfun(@(field) field(good_piks), results, ...
                        'UniformOutput', false);
    cd(orig_dir); cd('../tools')
    %do adaptive fitting with x km minimum segment length
    results = adaptive_bed_power_binsearch_utig(results, fit_dist, loose_unc, use_bm_thick);
    
    %downsamples each field by factor of M
    %  (scalar fields are preserved as scalars)
    % M is calculated so that pik spacing averages 10km
    
    M = ceil(1000*length(results.rdr_dist)/results.rdr_dist(end));
    cd ../tools
    results = rmfield(results, 'fit_segment_index');
    results = structfun(@(s) downsample_data(s, M), results, ...
                        'UniformOutput', false);
    %duplicate scalar fields C0, Cmin, atten_rate, and atten_uncertainty to
    %same length as other fields for plotting
    results = duplicate_scalar_fields(results);
    
    cd(save_dir)
    save_name = [transect_names{i} '_results.mat'];
    save(save_name, 'results'); clear results

    
end

cd(orig_dir)


    

