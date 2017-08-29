
load_dir = [pwd '/atten_fit_10km_loose'];
save_dir = [pwd '/atten_fit_10km_loose/plottable'];
orig_dir = pwd;


transect_names = get_transects();

for i = 1:length(transect_names)
    cd(load_dir)
    data_name = [transect_names{i} '_results.mat'];
    disp(data_name); load(data_name)
    
    %downsample to 1 pik per hundred meters
    M = ceil(100*length(results.rdr_dist)/results.rdr_dist(end));
    cd(orig_dir); cd('../tools')
    results = rmfield(results, 'fit_segment_index');
    results = structfun(@(s) downsample_data(s, M), results, ...
                        'UniformOutput', false);
    cd(save_dir)
    save(data_name, 'results')
    clear results
end

cd(orig_dir)