orig_dir = pwd;
cd('../'); source_data_dir = [pwd '/BBAS_PIG/results_aligned_5dBsnr'];
save_dir = [pwd '/BBAS_PIG/results_aligned_5dBsnr_std']; cd(orig_dir)

starts_with_str = {'b'};
results_name = '_SRG_repick.mat';

transect_names = get_transect_names(source_data_dir,starts_with_str);


for i = 1:length(transect_names)
    disp(' '); disp(transect_names{i});
    cd(source_data_dir); load([transect_names{i} results_name]); ...
    cd(orig_dir)
    results = SRG_results;
    
    L1 = length(results.PriNum);
    results = standardize_fields(results);
    results = rm_adapt_fields(results);

    
    
    
    good_piks = find(~isnan(results.rdr_thick) & ...
                     ~isnan(results.bed_pow) & ...
                     ~isnan(results.rdr_clear) & ...
                     results.rdr_thick >= 0 & ...
                     results.rdr_clear >= 0);
    results = structfun(@(field) field(good_piks), results, ...
                        'UniformOutput', false);
    L2 = length(results.pri);
    disp([num2str(L1-L2) ' removed'])
    results = fill_in_fields(results);
    
    moving_radar = find(diff(results.rdr_dist) >= 0.01);
    results = structfun(@(field) field(moving_radar), results, ...
                        'UniformOutput', false);
    
    cd(save_dir); save_name = [transect_names{i} '_results.mat'];
    save(save_name, 'results')
    clear results
end

cd(orig_dir)