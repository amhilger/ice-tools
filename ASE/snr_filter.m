%run before do_downsample

starts_with_str = {'DRP','X','Y','b'};
orig_dir = pwd;
load_dir = [pwd '/piks_agg_xover'];
save_dir = [pwd '/piks_agg_xover_filter'];
results_name = '_results.mat';

cd ../tools
tr_names = get_transect_names(data_dir, starts_with_str);

%snr threshold at which noise induces a 10% error in abruptness
snr_thresh_abr = 12; 
%more permissible snr threshold, below which data is removed entirely
snr_thresh_gen = 5;

for i = 1:length(tr_names)
    disp(' '); disp(tr_names{i})
    cd(load_dir); load([tr_names{i} results_name])
    %mark as nan abruptness and peakiness not meeting 10% error criteria
    results.abrupt(results.max_pow < snr_thresh_abr) = NaN;
    results.peakiness(results.max_pow < snr_thresh_abr) = NaN;
    bad_peakiness_ratio = sum(isnan(results.peakiness))/length(results.peakiness);
    disp(['Transect SNR = ' num2str(mean(results.max_pow), 4) ...
          '+/- ' num2str(std(results.max_pow), 4) ' dB'])
    if bad_peakiness_ratio > 0.5
        disp(['Piks insufficient for abruptness calcs = ' ...
                num2str(bad_peakiness_ratio*100, 4) ' %'])
        disp('Removing entire transect from consideration')
        continue
    end
        
    %identify piks meeting more permissive snr threshold
    good_piks = find(results.max_pow >= snr_thresh_gen); 
    %filter the results to only the piks meeting the threshold
    results = structfun(@(fld) fld(good_piks), results, ...
                        'UniformOutput', false);
    cd(save_dir); save([tr_names{i} results_name],'results')
end

cd(orig_dir)