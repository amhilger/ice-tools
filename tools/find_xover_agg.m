function [matches, self_matches] = ...
                find_xover_agg(data_dir,starts_with_str,result_name, ...
                                lin_err_thresh, dist_thresh, ...
                                bp_dist_thresh)


num_match_guess = 2500;
%guessing on order of 1000-1200 X,Y crossovers + 100-200 DRP crossovers

orig_dir  = pwd;

if ~exist('starts_with_str','var')
    starts_with_str = {'DRP','X','Y'};
end
if ~exist('result_name','var')
    result_name = '_results.mat';
end


transect_names = get_transect_names(data_dir, starts_with_str);

if ~exist('lin_err_thresh','var')
    lin_err_thresh = 125; %m, for linear fits
end
min_seg_len = 5; %number of piks
if ~exist('dist_thresh','var')
    dist_thresh = 1000; %distance threshold for intersection, m
end
if ~exist('bp_dist_thresh','var')
    bp_dist_thresh = 1000; %use bed powers within 1 km for computing median
end
%initialize cells to store segment indices and coefficients
seg_indexes =  cell(length(transect_names),1);
seg_coeffs  =  cell(length(transect_names),1);
seg_ts_idx  =  cell(length(transect_names),1);
ts_easts    =  cell(length(transect_names),1);
ts_norths   =  cell(length(transect_names),1);
ts_maxpow   =  cell(length(transect_names),1);
ts_aggpow   =  cell(length(transect_names),1);
ts_dist     =  cell(length(transect_names),1);
ts_heading  =  cell(length(transect_names),1);
ts_abrupt   =  cell(length(transect_names),1);

%segment each transect
for i = 1:length(transect_names)
    cd(data_dir); load([transect_names{i} result_name]); cd(orig_dir)
    ts_easts{i}   = results.easts;    %save easts and norths 
    ts_norths{i}  = results.norths;   %for finding xovers loops
    ts_maxpow{i}  = results.geo_pow_max; %use geometrically corrected versions
    ts_aggpow{i}  = results.geo_pow_agg;
    ts_abrupt{i}  = results.abrupt;
    ts_heading{i} = results.heading;
    ts_dist{i}    = results.rdr_dist; %for computing DC offsets within TS
    [seg_idx, seg_coef] = linear_segmentize(results.easts, ...
                                            results.norths, ...
                                            lin_err_thresh, ...
                                            min_seg_len);
    seg_indexes{i} = seg_idx; %[start_idx end_idx] of each segment
    seg_coeffs{i}  = seg_coef;%[b m] of linear fit for each segment
    seg_ts_idx{i}  = i*ones(size(seg_idx,1),1); %transect of each segment
end
%convert to cells
seg_indexes = cell2mat(seg_indexes);
seg_coeffs  = cell2mat(seg_coeffs );
seg_ts_idx  = cell2mat(seg_ts_idx );


seg_e_edges  =  cell(length(seg_ts_idx),1);
seg_n_edges  =  cell(length(seg_ts_idx),1);
%generate histogram edges to be used in finding closest point
%histogram edges are midpoint between each point and +/- Inf at ends
%if the data were nice, we'd only have to look at easts or norths, but the
%pathological BAS data is often non-monotonic, so we need to look at
%everything we can get our grubby hands on
for i = 1:length(seg_ts_idx)
    est = ts_easts{ seg_ts_idx(i)}(seg_indexes(i,1):seg_indexes(i,2));

    if est(end) > est(1) %if in overall ascending order
        seg_e_edges{i} = [-Inf; 0.5*(est(1:end-1)+est(2:end)); Inf];
        if any(diff(seg_e_edges{i}) <= 0) %if not monotonically increasing
             seg_e_edges{i} = []; %set to empty
        end
    else %if in overall descending order
        seg_e_edges{i} = [Inf; 0.5*(est(1:end-1)+est(2:end)); -Inf];
        if any(diff(seg_e_edges{i}) >= 0) %if not monotonically decreasing
             seg_e_edges{i} = []; %set to empty
        end     
    end
    nrt = ts_norths{seg_ts_idx(i)}(seg_indexes(i,1):seg_indexes(i,2));
    if nrt(end) > nrt(1) %if in normal ascending order
        seg_n_edges{i} = [-Inf; 0.5*(nrt(1:end-1)+nrt(2:end)); Inf];
        if any(diff(seg_n_edges{i}) <= 0)
            seg_n_edges{i} = [];
        end
    else %if in descending order
        seg_n_edges{i} = [Inf; 0.5*(nrt(1:end-1)+nrt(2:end)); -Inf];
        if any(diff(seg_n_edges{i}) >= 0)
            seg_n_edges{i} = [];
        end
    end
    if(isempty(seg_n_edges{i}) && isempty(seg_e_edges{i}))
        disp(['Segment #' num2str(i) ' -- segment #' ...
              num2str(i+1-find(seg_ts_idx == seg_ts_idx(i),1,'first')) ...
              ' of transect ' num2str(seg_ts_idx(i)) ...
              ' is non-monotonic in both east and north directions'])  
%         disp(i)
%         figure; subplot(211);
%         plot(ts_easts{seg_ts_idx(i)}(seg_indexes(i,1):seg_indexes(i,2)))
%         subplot(212); plot(ts_norths{seg_ts_idx(i)}(seg_indexes(i,1):seg_indexes(i,2)))
    end
end

disp(['Split ' num2str(length(transect_names)) ' transects into ' ...
      num2str(size(seg_indexes,1)) ' segments']); pause(0.5)

%each column corresponds to one of the partners in the match
matches.ts      = zeros(num_match_guess, 2); %transect
matches.tr_idx  = zeros(num_match_guess, 2); %trace index within transect
matches.max_pow = zeros(num_match_guess, 2); %bed power at intersection
matches.agg_pow = zeros(num_match_guess, 2);
matches.heading = zeros(num_match_guess, 2);
matches.easts   = zeros(num_match_guess, 2); %for plotting
matches.norths  = zeros(num_match_guess, 2); %for plotting
matches.dist    = zeros(num_match_guess, 1); %distance b/w pair
matches.seg_num = zeros(num_match_guess, 2); %segment number
matches.abrupt  = zeros(num_match_guess, 2); %segment abruptness

save_idx = 1;
%compare each pair of segments
for i = 1:length(seg_ts_idx)
    if mod(i,50) == 0, disp(i); end
    for j = i+1:length(seg_ts_idx) %ignore already compared segments    
        tsA = seg_ts_idx(i); %transect A index
        tsB = seg_ts_idx(j); %transect B index
        %compute distance of closest intersection between segments i and j,
        %as well as traces indexes corresponding to the closest
        %intersection. We don't clip norths and easts to just the segment
        %length, so it's possible that traceA or traceB is outside of
        %corresponding segment
        [traceA, traceB] = ...
            find_intersect(seg_coeffs(i,:), seg_coeffs(j,:), ...
                                seg_e_edges{i}, seg_e_edges{j}, ...
                                seg_n_edges{i}, seg_n_edges{j});
        %convert segment index to trace index
        traceA = traceA - 1 + seg_indexes(i,1); %with segment start index
        traceB = traceB - 1 + seg_indexes(j,1);
        %NaN trace implies that transect in non-monotonic, so no suitable
        %edges available -> check all
        if isnan(traceA)
            traceA = seg_indexes(i,1):seg_indexes(i,2);
        end
        if isnan(traceB)
            traceB = seg_indexes(j,1):seg_indexes(j,2);
        end
%         if length(traceA) > 1 || length(traceB) > 1
%             disp(['i=' num2str(i) ' j=' num2str(j) ': ' ...
%                 num2str(length(traceA > 1)) ' A candidates and ' ...
%                 num2str(length(traceB > 1)) ' B candidates'])
%         end
        %empty trace implies that no intersection found
        if ~isempty(traceA) && ~isempty(traceB)
        [traceA, traceB, dmin] = ...
            dmin_between(traceA, traceB, ts_easts{tsA}, ...
                         ts_norths{tsA}, ts_easts{tsB}, ts_norths{tsB});
        else %if either is empty, than no intersection possible
            continue; %in other words, dmin = Inf;
        end
        %check that distance less than threshold, and that traces of
        %intersection are actually within segment
        if dmin <= dist_thresh 
               matches.ts(    save_idx,:) = [tsA tsB]; %transect index
               matches.tr_idx(save_idx,:) = [traceA traceB]; %trace index
               
               %compute bed powers along each transect near xover
               %use median of bed powers within a threshold distance
               maxpowA = median(ts_maxpow{tsA}(abs(ts_dist{tsA} - ...
                                            ts_dist{tsA}(traceA)) < ...
                                            bp_dist_thresh),'omitnan');

               maxpowB = median(ts_maxpow{tsB}(abs(ts_dist{tsB} - ...
                                            ts_dist{tsB}(traceB)) < ...
                                            bp_dist_thresh),'omitnan');
               matches.max_pow(save_idx,:) = [maxpowA maxpowB];
               
               %use median of geo powers within a threshold distance
               aggpowA = median(ts_aggpow{tsA}(abs(ts_dist{tsA} - ...
                                            ts_dist{tsA}(traceA)) < ...
                                            bp_dist_thresh),'omitnan');
               aggpowB = median(ts_aggpow{tsB}(abs(ts_dist{tsB} - ...
                                            ts_dist{tsB}(traceB)) < ...
                                            bp_dist_thresh),'omitnan');
               matches.agg_pow(save_idx,:) = [aggpowA aggpowB];
               
               %use median abruptness within threshold distance
               abruptA = median(ts_abrupt{tsA}(abs(ts_dist{tsA} - ...
                                             ts_dist{tsA}(traceA)) < ...
                                             bp_dist_thresh),'omitnan');
               abruptB = median(ts_abrupt{tsB}(abs(ts_dist{tsB} - ...
                                             ts_dist{tsB}(traceB)) < ...
                                             bp_dist_thresh),'omitnan');
               matches.abrupt(save_idx,:) = [abruptA abruptB];               
               
               matches.easts(save_idx,:) =  [ts_easts{tsA}(traceA) ...
                                             ts_easts{tsB}(traceB)];
               matches.norths(save_idx,:) = [ts_norths{tsA}(traceA) ...
                                             ts_norths{tsB}(traceB)];
               matches.heading(save_idx,:) = [ts_heading{tsA}(traceA) ...
                                              ts_heading{tsB}(traceB)];
               matches.dist(save_idx) = dmin;
               matches.seg_num(save_idx,:) = [i j];
               save_idx = save_idx + 1;
        end
    end
end
%remove trailing zeros
matches.tr_idx  = matches.tr_idx(  matches.ts(:,1) ~= 0, : );
matches.max_pow = matches.max_pow( matches.ts(:,1) ~= 0, : );
matches.agg_pow = matches.agg_pow( matches.ts(:,1) ~= 0, : );
matches.heading = matches.heading( matches.ts(:,1) ~= 0, : );
matches.easts   = matches.easts(   matches.ts(:,1) ~= 0, : );
matches.norths  = matches.norths(  matches.ts(:,1) ~= 0, : );
matches.dist    = matches.dist(    matches.ts(:,1) ~= 0, : );
matches.seg_num = matches.seg_num( matches.ts(:,1) ~= 0, : );
matches.ts      = matches.ts(      matches.ts(:,1) ~= 0, : );
matches.abrupt  = matches.abrupt(  matches.ts(:,1) ~= 0, : );

matches = deduplicate(matches, dist_thresh, transect_names);

%identify self_xover
matches.self_xover = ( matches.ts(:,1) == matches.ts(:,2) );

%split self_matches into a separate 
self_matches = structfun(@(field) field(matches.self_xover,:), matches, ...
                         'UniformOutput', false);
matches = structfun(@(field) field(~matches.self_xover,:), matches, ...
                    'UniformOutput', false);

cd(orig_dir)

%debug/verification code
close(figure(1)); figure(1); hold on
for i = 1:length(transect_names)
    plot(ts_easts{i},ts_norths{i},'.','MarkerSize',2)
end
for i = 1:size(matches.ts,1)
    if ~matches.self_xover(i)
        plot(ts_easts{ matches.ts(i,1)}(matches.tr_idx(i,1)), ...
             ts_norths{matches.ts(i,1)}(matches.tr_idx(i,1)),'x')
        plot(ts_easts{ matches.ts(i,2)}(matches.tr_idx(i,2)), ...
             ts_norths{matches.ts(i,2)}(matches.tr_idx(i,2)),'+')
    end
end

close(figure(2)); figure(2); hold on 
for i = 1:size(seg_indexes,1)
    est = ts_easts{seg_ts_idx(i)}(seg_indexes(i,1):seg_indexes(i,2));
    nrt = seg_coeffs(i,2)*est + seg_coeffs(i,1);
    plot(est,nrt,'.','MarkerSize',2)
end

close(figure(3)); figure(3)
scatter(matches.easts(:,1), matches.norths(:,1), ...
        5*ones(size(matches.easts,1),1), ...
        matches.max_pow(:,1) - matches.max_pow(:,2), ...
        'filled')
title('xover error - uncorrected')
colorbar

close(figure(4)); figure(4)
scatter(matches.easts(:,1), matches.norths(:,1), ...
        5*ones(size(matches.easts,1),1), ...
        matches.dist, ...
        'filled')
title('xover distance')
colorbar

close(figure(5)); figure(5)
histogram(matches.dist)
title('xover distance')
xlabel('m')

close(figure(6)); figure(6)
histogram(matches.agg_pow(:,1) - matches.agg_pow(:,2),20)
title('xover aggpow-gc')
xlabel('dB')


close(figure(7)); figure(7)
histogram(matches.max_pow(:,1) - matches.max_pow(:,2),20)
title('xover maxpow-gc')
xlabel('dB')

close(figure(8)); figure(8)
histogram(matches.heading(:,1) - matches.heading(:,2),20)
title('heading')
xlabel('deg')

end




