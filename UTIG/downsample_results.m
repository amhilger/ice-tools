
load_dir = [pwd '/piks_agg_filter'];
save_dir = [pwd '/piks_agg_filter_plottable'];
orig_dir = pwd;

cd ../tools
transect_names = get_transect_names(load_dir); cd(orig_dir)

for i = 1:length(transect_names)
    cd(load_dir)
    data_name = [transect_names{i} '_results.mat'];
    disp(data_name); load(data_name)
    
    %downsample to 1 pik per km
    M = ceil(1000*length(results.rdr_dist)/results.rdr_dist(end));
    cd(orig_dir); cd('../tools')
    results = structfun(@(s) downsample_data(s, M), results, ...
                        'UniformOutput', false);
    cd(save_dir)
    save(data_name, 'results')
    clear results
end

cd(orig_dir)
