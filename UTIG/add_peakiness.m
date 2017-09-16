save_dir = [pwd '/piks_agg_filter'];
load_dir = [pwd '/piks_agg_filter'];
orig_dir = cd(save_dir);
cd(orig_dir)

starts_with_str = {'DRP','X','Y'};
results_name = '_results.mat';

Amax_utig = 0.16835; % max abruptness given chirp, sampling frequency
fc_utig = 60e6; %Hz carrier frequency
Amax_bas = 0.2551; % max abruptness given chirp, sampling frequency
fc_bas = 150e6; %Hz carrier frequency

cd ../tools
transect_names = get_transect_names(load_dir, starts_with_str);

for i = 1:length(transect_names)
    disp(transect_names{i})
    cd(load_dir)
    load([transect_names{i} results_name])
    cd(orig_dir); cd ../tools
    results.peakiness = peakiness_of(fc_utig, Amax_utig, results.abrupt, ...
                                     fc_utig, Amax_utig);
    cd(save_dir)
    save([transect_names{i} results_name], 'results') 
end

cd(orig_dir)

