%loads data, calculates geometric power and reflectivity, and saves
%downsampled version for plotting. This version uses a single attenuation
%rate for each transect, which is statistically fit.

source_dir = [pwd '/cross_calib'];
save_dir = [pwd '/atten_fit2d_ri_10km_C07'];
orig_dir = cd(save_dir);
cd(orig_dir)

seg_len = 1;
min_rad = 10;
use_bm_thick = false;
loose_unc = true;
min_ice_thick = 200; % to avoid firn correction inaccuracies
min_bed_pow = 0;

clear results

starts_with_str = {'DRP','X','Y','b'};
results_name = '_results.mat';

cd ../tools
transect_names = get_transect_names(source_dir, starts_with_str);
survey = combine_results(source_dir, transect_names, results_name);

%must keep these consistent with results filters below
good_piks = find(~isnan(survey.rdr_thick) & ...
                     ~isnan(survey.bed_pow) & ...
                     ~isnan(survey.rdr_clear) & ...
                     survey.bed_pow >= min_bed_pow & ...
                     survey.rdr_thick >= min_ice_thick);
survey = structfun(@(field) field(good_piks), survey, ...
                        'UniformOutput', false);

kdtree = KDTreeSearcher([survey.easts, survey.norths]);


%%

for i = 1:length(transect_names)
    disp(' '); disp(transect_names{i}); pause(0.25)
    cd(source_dir); load([transect_names{i} '_results.mat']); 
    cd(orig_dir); cd ../tools
    
    
    %must keep these consistent with survey filters above
    good_piks = find(~isnan(results.rdr_thick) & ...
                     ~isnan(results.bed_pow) & ...
                     ~isnan(results.rdr_clear) & ...
                     results.bed_pow >= min_bed_pow & ...
                     results.rdr_thick >= min_ice_thick);
    results = structfun(@(field) field(good_piks), results, ...
                        'UniformOutput', false);
    cd(orig_dir); cd('../tools')
    %do adaptive fitting with x km minimum segment length
    results = adaptive_bed_power2d_ri(results, survey, kdtree, ...
                                       seg_len, min_rad, ...
                                       loose_unc, use_bm_thick);
    
    %downsamples each field by factor of M
    %  (scalar fields are preserved as scalars)
    % M is calculated so that pik spacing averages 1 km
%     if ~isempty(results.rdr_dist)
%         M = ceil(100*length(results.rdr_dist)/results.rdr_dist(end));
%         cd ../tools
%         results = structfun(@(s) downsample_data(s, M), results, ...
%                             'UniformOutput', false);
%     end
    

    
    cd(save_dir)
    save_name = [transect_names{i} '_results.mat'];
    save(save_name, 'results', 'min_rad', 'use_bm_thick', ...
                    'loose_unc', 'min_ice_thick', 'min_bed_pow', ...
                    'source_dir')
    clear results

    
end

cd(orig_dir)


    

