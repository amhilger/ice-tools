
starts_with_strA = {'DRP','X','Y','b'};
starts_with_strB = {'b'};
orig_dir = pwd;
data_dir = [pwd '/xover_combo'];
results_name = '_results.mat';

cd ../tools
tr_names = get_transect_names(data_dir, starts_with_str);


cd(data_dir)

for i = 1:length(tr_names)
    load([tr_names{i} results_name])
    if ~isfield(results,'geo_pow_xover')
        dc_offset = mean(results.bed_pow_xover - results.bed_pow);
        assert(std(results.bed_pow_xover - results.bed_pow) < 0.01)
        results.geo_pow_xover = results.rdr_geo_pow + dc_offset;
    end
    save([tr_names{i} results_name],'results')
end
