
starts_with_str = {'DRP','X','Y','b'};
orig_dir = pwd;
load_dir = [pwd '/piks_agg_xover'];
save_dir = [pwd '/piks_agg_xover_plottable'];
results_name = '_results.mat';

cd ../tools
tr_names = get_transect_names(load_dir, starts_with_str);



for i = 1:length(tr_names)
    disp(tr_names{i})
    cd(load_dir); load([tr_names{i} results_name])
    %downsample to 1 pik per kilometer, along line, on average
    M = ceil(1000*length(results.rdr_dist)/results.rdr_dist(end));
    cd ../../tools
    results = structfun(@(fld) downsample_data(fld, M), results, ...
                        'UniformOutput', false);
    cd(save_dir); save([tr_names{i} results_name],'results')
end

cd(orig_dir)