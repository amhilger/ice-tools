
starts_with_str = {'DRP','X','Y','b'};
orig_dir = pwd;
data_dir = [pwd '/cross_calib_plot'];
results_name = '_results.mat';

cd ../tools
tr_names = get_transect_names(data_dir, starts_with_str);


cd(data_dir)

for i = 1:length(tr_names)
    disp(tr_names{i})
    cd(data_dir); load([tr_names{i} results_name])
    M = ceil(1000*length(results.rdr_dist)/results.rdr_dist(end));
    cd ../../tools
    results = structfun(@(s) downsample_data(s, M), results, ...
                        'UniformOutput', false);
    cd(data_dir); save([tr_names{i} results_name],'results')
end

cd(orig_dir)