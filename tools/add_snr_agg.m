
starts_with_str = {'b'};
orig_dir = pwd;
data_dir = [pwd '/agg_repick_two'];
results_name = '_results.mat';

cd ../tools
tr_names = get_transect_names(data_dir, starts_with_str);


cd(data_dir)

for i = 1:length(tr_names)
    disp(tr_names{i})
    load([tr_names{i} results_name])
    if isfield(results, 'snr_max')
        results = rmfield(results, 'snr_max');
    end
    results.snr_agg = results.agg_pow./(2*results.ft_range);
    save([tr_names{i} results_name], 'results')
end

cd(orig_dir)