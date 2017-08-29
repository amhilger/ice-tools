save_dir = [pwd '/piks_lo_hi_filtered'];
load_dir = [pwd '/piks_lo_hi'];
orig_dir = cd(save_dir);
cd(orig_dir)

starts_with_str = {'DRP','X','Y'};
results_name = '_results.mat';
min_ice_thick = 200; % to avoid firn correction inaccuracies
min_bed_pow = 0;

cd ../tools
transect_names = get_transect_names(load_dir, starts_with_str);

for i = 1:length(transect_names)
    disp(transect_names{i})
    cd(load_dir)
    load([transect_names{i} results_name])
    cd(orig_dir); cd ../tools
    good_piks = find(~isnan(results.rdr_thick) & ...
                     ~isnan(results.bed_pow) & ...
                     ~isnan(results.rdr_clear) & ...
                     results.bed_pow >= min_bed_pow & ...
                     results.rdr_thick >= min_ice_thick & ...
                     filter_heading(results.heading, results.rdr_dist));
    
    if length(good_piks) ~= length(results.heading)
        disp([num2str(length(results.heading) - length(good_piks)) ...
                ' piks removed out of ' num2str(length(results.heading))])
    end
    
    if isempty(good_piks)
        disp('*** No piks survive filters in this transect ***')
        continue
    end
    
    results = structfun(@(fld) fld(good_piks), results, ...
                        'UniformOutput', false');
    
    cd(save_dir)
    save([transect_names{i} results_name], 'results') 
end

cd(orig_dir)

