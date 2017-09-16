
load_dir = [pwd '/piks_agg'];
save_dir = [pwd '/piks_agg_filter'];
orig_dir = pwd;

cd ../tools
transect_names = get_transect_names(load_dir); cd(orig_dir)

%filter parameters
min_ice_thick = 200; %m, see MacGregor, to avoid firn correction inaccuracies
min_rdr_clear = 50; %m, plane must be airborne
min_snr = 5; %dB, minimum SNR in normalized max power and aggregated power

for i = 1:length(transect_names)
    cd(load_dir)
    data_name = [transect_names{i} '_results.mat'];
    disp(data_name); load(data_name)
    
    cd(orig_dir); cd('../tools')
    results.geo_pow_max = geo_correct_power(results.max_pow, ...
                                            results.rdr_clear, ...
					    results.rdr_thick);
    results.geo_pow_agg = geo_correct_power(results.agg_pow, ...
                                            results.rdr_clear, ...
					    results.rdr_thick);
    good_piks = find(~isnan(results.rdr_thick) & ...
                     ~isnan(results.bed_pow) & ...
		     ~isnan(results.rdr_clear) & ...
		     results.max_pow >= min_snr & ...
		     results.agg_pow >= min_snr & ...
		     results.rdr_thick >= min_ice_thick & ...
		     results.rdr_clear >= min_rdr_clear & ...
		     filter_heading(results.heading, results.rdr_dist));
    if length(good_piks) ~= length(results.rdr_clear)
	    disp([num2str(length(results.rdr_clear) - length(good_piks)) ...
	            ' piks removed out of ' num2str(length(results.heading))])

    end
    if isempty(good_piks)
        disp('*** No piks survive filters in this transect ***')
        continue
    end

    %do the actual filtering
    results = structfun (@(fld) fld(good_piks), results, ...
                         'UniformOutput', false);
    cd(save_dir)
    save(data_name, 'results')
    clear results
end

cd(orig_dir)
