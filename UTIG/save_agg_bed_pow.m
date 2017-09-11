orig_dir = cd('../tools');
source_dir = '/data/cees/amhilger/UTIG/piks_lo_hi_all';
save_dir    = '/data/cees/amhilger/UTIG/piks_agg';

%test that save_dir exists
cd(save_dir); cd(orig_dir); cd ../tools
tr_names = get_transect_names(source_dir, {'X','Y','DRP'});

for i = 1:length(tr_names)
    disp(tr_names{i})
    cd(orig_dir)
    [radar_lo, radar_hi] = load_incoh_radar(tr_names{i});
    %load results directory 
    %NB: results directory must be unfiltered; otherwise, results won't be
    %aligned with incoherently processed radargram
    cd(source_dir); load([tr_names{i} '_results.mat'])
    cd(orig_dir)
    % do the repick
    [results.max_pow, ...
     results.max_pow_sample, ...
     results.noise_floor, ...
     results.agg_pow, ...
     results.ft_range, ...
     results.abrupt] = ...
        repick_bed(results, radar_lo, radar_hi);

    cd(save_dir)
    save([tr_names{i} '_results.mat'], 'results','source_dir')
end

cd(orig_dir)
