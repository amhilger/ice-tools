

orig_dir = pwd;
cd('../'); source_dir = [pwd '/UTIG/piks_agg_filter'];
save_dir = [pwd '/UTIG/piks_agg_xover']; cd(orig_dir)

starts_with_str = {'DRP','X','Y'};
results_name = '_results.mat';

seg_lin_err_thresh = 75;  %m
xover_dist_thresh  = 1000; %m
xover_bp_dist      = 1000; %m
xover_huber_thresh = 3; %dB
%threshold beyond which deviation signifies likely outlier

[matches, self_matches] = ...
    find_xover_agg(source_dir, starts_with_str,results_name, ...
                     seg_lin_err_thresh, xover_dist_thresh, xover_bp_dist);

%Fit DC offsets using Huber penalty function
disp(['Uncorrected RMSD: ' ...
        num2str( norm(diff(matches.agg_pow, 1, 2)) / ...
                 sqrt(size(matches.ts,1)) )])


cvx_begin quiet
    variable dc_offset(max(matches.ts(:)),1)
    variable adj_bedpows1(size(matches.ts,1),1) 
    variable adj_bedpows2(size(matches.ts,1),1)
    %use huber penalty function, kinked at 3dB
    minimize (sum(huber(adj_bedpows1 - adj_bedpows2, xover_huber_thresh)))
    subject to
        adj_bedpows1 == matches.agg_pow(:,1) + dc_offset(matches.ts(:,1))
        adj_bedpows2 == matches.agg_pow(:,2) + dc_offset(matches.ts(:,2))  
cvx_end
cd(orig_dir)

assert(strcmp(cvx_status, 'Solved'))
disp(['Corrected RMSD: ' ...
        num2str(norm(adj_bedpows1-adj_bedpows2) / ...
                sqrt(size(matches.ts,1)))])

dc_offset = dc_offset - mean(dc_offset); %center dc_offsets around zero
%%

scatter(matches,easts, matches.norths, 

%plot corrected xover errors
close(figure(8)); figure(8)
scatter(matches.easts(:,1), matches.norths(:,1), ...
        10*ones(size(matches.easts,1),1), ...
        adj_bedpows1 - adj_bedpows2, ...
        'filled')
title('xover error - corrected')
colorbar

transect_names = get_transect_names(source_dir,starts_with_str);

%standardize field names of each results file and save
for i = 1:length(transect_names)
    disp(' '); disp(transect_names{i}); pause(0.25)
    cd(source_dir); load([transect_names{i} results_name]); cd(orig_dir)
    
%     results = standardize_fields(results);
%     results = rm_adapt_fields(results);
%     results = fill_in_fields(results);
    
    
%     good_piks = find(~isnan(results.rdr_thick) & ...
%                      ~isnan(results.bed_pow) & ...
%                      ~isnan(results.rdr_clear));
%     results = structfun(@(field) field(good_piks), results, ...
%                         'UniformOutput', false);
     cd('../tools')
    
    
    results.agg_pow_xover = results.agg_pow + dc_offset(i);
    results.max_pow_xover = results.max_pow + dc_offset(i); 
    results.geo_pow_agg_xover = results.geo_pow_agg + dc_offset(i);
    results.geo_pow_max_xover = results.geo_pow_max + dc_offset(i);
    disp(['Number of picks: ' num2str(length(results.agg_pow_xover))])
    disp(['Pik spacing: ' ...
            num2str((results.rdr_dist(end)-results.rdr_dist(1)) / ...
                     length(results.rdr_dist))])
    cd(save_dir)
    save_name = [transect_names{i} '_results.mat'];
    save(save_name, 'results')
    clear results
    
end

cd(save_dir); save('xover_matches.mat', ...
                    'matches','self_matches', 'dc_offset', ...
                    'xover_huber_thresh', 'seg_lin_err_thresh', ...
                    'xover_dist_thresh', 'xover_bp_dist', ...
                    'source_dir'); 
cd(orig_dir)
