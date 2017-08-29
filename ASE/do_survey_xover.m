
starts_with_str = {'DRP','X','Y','b'};
orig_dir = pwd;
source_data_dir = [pwd '/xover_combo'];
save_dir = [pwd '/cross_calib'];
results_name = '_results.mat';

seg_lin_err_thresh = 75; %m
xover_dist_thresh = 1000; %m
xover_bp_dist = 1000; %m
xover_huber_thresh = 3; %dB

cd ../tools
matches = find_xover_bw_surveys(source_data_dir, starts_with_str, ...
                                results_name, seg_lin_err_thresh, ...
                                xover_dist_thresh, xover_bp_dist);
%%
disp(['Uncorrected RMSD: ' ...
        num2str(norm(matches.geo_pow(:,1)-matches.geo_pow(:,2)) / ...
                sqrt(size(matches.ts,1)))])
cvx_begin quiet
    variable dc_offset
    variable adj_bedpows1(size(matches.ts,1),1) 
    variable adj_bedpows2(size(matches.ts,1),1)
    %use huber penalty function, kinked at 3dB
    minimize (sum(huber(adj_bedpows1 - adj_bedpows2, xover_huber_thresh)))
    subject to
        adj_bedpows1 == matches.geo_pow(:,1) + dc_offset
        adj_bedpows2 == matches.geo_pow(:,2)
cvx_end
assert(strcmp(cvx_status, 'Solved'))
disp(['Corrected RMSD: ' ...
        num2str(norm(adj_bedpows1-adj_bedpows2) / ...
                sqrt(size(matches.ts,1)))])

cd(orig_dir)

assert(dc_offset > 0)

%%
cd ../tools
transect_names = get_transect_names(source_data_dir,starts_with_str);

%standardize field names of each results file and save
for i = 1:length(transect_names)
    disp(' '); disp(transect_names{i});
    cd(source_data_dir); load([transect_names{i} results_name]); ...
    cd(orig_dir)
    

    if results.survey_num(1) == 2 % if BAS, subtract DC offset
        results.bed_pow_calib = results.bed_pow_xover - dc_offset;
        results.geo_pow_calib = results.geo_pow_xover - dc_offset;
    else %if UTIG, just copy
        results.bed_pow_calib = results.bed_pow_xover;
        results.geo_pow_calib = results.geo_pow_xover;
    end
    disp(['Number of picks: ' num2str(length(results.bed_pow_xover))])
    disp(['Pik spacing: ' ...
            num2str((results.rdr_dist(end)-results.rdr_dist(1)) / ...
                     length(results.rdr_dist))])
    cd(save_dir)
    save_name = [transect_names{i} '_results.mat'];
    save(save_name, 'results')
    clear results
    
end

cd(save_dir); save('xover_matches.mat', ...
                    'matches', 'dc_offset', ...
                    'huber_thresh', 'seg_lin_err_thresh', ...
                    'xover_dist_thresh', 'xover_bp_dist', ...
                    'source_data_dir'); 
cd(orig_dir)
