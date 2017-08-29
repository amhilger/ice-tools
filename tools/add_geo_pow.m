
starts_with_str = {'b'};
orig_dir = pwd;
data_dir = [pwd '/agg_repick_two'];
results_name = '_results.mat';

cd ../tools
tr_names = get_transect_names(data_dir, starts_with_str);

for i = 1:length(tr_names)
    disp(tr_names{i})
    cd(data_dir)
    load([tr_names{i} results_name])
    cd ../../tools
    results.geo_pow_fr = geo_correct_power(results.max_pow, ...
                                           results.rdr_clear, ...
                                           results.rdr_thick);
    cd(data_dir)
    save([tr_names{i} results_name], 'results')
end

cd(orig_dir)