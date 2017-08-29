save_dir = [pwd '/results_aligned_5dBsnr'];
load_dir = [pwd '/results_aligned_5dBsnr'];
orig_dir = cd(save_dir);
cd(orig_dir)

starts_with_str = {'b'};
results_name = '_SRG_repick.mat';

cd ../tools
transect_names = get_transect_names(load_dir, starts_with_str);

for i = 1:length(transect_names)
    disp(transect_names{i})
    cd(load_dir)
    load([transect_names{i} results_name])
    cd(orig_dir); cd ../tools
    results = SRG_results;
    
    results = standardize_fields(results);
    results = rm_adapt_fields(results);
    
    results.rdr_clear(results.rdr_clear < 0) = NaN;
    results.rdr_thick(results.rdr_thick < 0) = NaN;
    
    results = fill_in_fields(results);
    
    
    

    
    
    good_piks = find(~isnan(results.rdr_thick) & ...
                      ~isnan(results.bed_pow) & ...
                      ~isnan(results.rdr_clear));
    
    if length(good_piks) ~= length(results.heading)
        disp([num2str(length(results.heading) - length(good_piks)) ...
                ' piks removed out of ' num2str(length(results.heading))])
    end
    
    results = structfun(@(fld) fld(good_piks), results, ...
                        'UniformOutput', false');
    
    cd(save_dir)
    save([transect_names{i} '_results.mat'], 'results') 
end

cd(orig_dir)

