function [results] = ...
    adaptive_bed_power_binsearch_bas(results, seg_len, loose_unc, use_bm_thick)
%results is a structure containin fields
%Adaptively determine attenuation rate to determine bed reflectivity

%seg_len is minimum fitting distance in km

%this version allows 10% attenuation uncertain

C_0_min = 0.5; %minimum correlation for thickness and geometrically corrected power
att_unc_max = 0.001; %dB/km
att_unc_max_per = 0.003; %dB/km (max when using percentage attenuation rate)
att_unc_per = 0.1; %allow any attenution rate with uncertainty below 10%
C_m_max = 0.01; %maximum allowable correlation at fit attenuation
C_hw = 0.1; %For calculating atten uncertainty

%shorten variable names from results file
if isfield(results, 'bed_pow_xover')
    bed_power = results.bed_pow_xover;
else
    bed_power = results.bed_pow; % dB
end
path_dist = results.rdr_dist/1000; %convert to km
if exist('use_bm_thick','var') && use_bm_thick
    ice_thick = results.bm_thick;
else
    ice_thick = results.rdr_thick;
end
geo_power = geo_correct_power(bed_power, results.rdr_clear, ice_thick);

%initialize outputs
atten_rate_array = zeros(size(bed_power));
atten_unc_array = zeros(size(bed_power));
reflectivity_array = zeros(size(bed_power));
C_0_array = zeros(size(bed_power));
C_min_array = zeros(size(bed_power));
fit_segment_index = zeros(length(bed_power), 2);
fit_distance_array = zeros(length(bed_power), 1);

%segment_indices gives segment beginnings and ends as row vectors
segment_indices = initialize_out_segments(seg_len, path_dist);
%the returned segments have a minimum length of seg_len
num_segments = size(segment_indices, 1); %number of row vectors

%pass_array = zeros(size(jump_seg_starts));


%for each segment
for i = 1:num_segments
    %find points from (i-1)th km to ith km
    out_segment = segment_indices(i,1):segment_indices(i,2);
    out_dist =  path_dist(out_segment(end)) - path_dist(out_segment(1));
    %initialize fit segment to twice length of output_segment, so adjacent
    %segments overlap by 50%
    fit_segment = next_segment(out_segment, out_dist, Inf, path_dist);
    %initialize new distance 
    new_dist =  path_dist(fit_segment(end)) - path_dist(fit_segment(1));

    %if segment has significantly fewer piks/km than average, expand it
    while length(fit_segment)/new_dist*2 < ...
          length(path_dist)/max(path_dist)
        fit_segment = next_segment(out_segment, new_dist, Inf, path_dist);
        disp('Expanding fit segment due to insufficient data density')
        new_dist = path_dist(fit_segment(end)) - path_dist(fit_segment(1))
    end
    
    %initialize quality parameters
    C_0 = 0;
    C_min = 1;
    atten_unc = 100;
    
    %initialize distance of shortest successful fit as Infinity
    min_fitted = Inf; 
    %initialize max_failed in case the first fit succeeds
    max_failed = new_dist;
    %initialize exit condition to false to gauarantee at least one loop
    %execution
    exit_condition = false;
    %this loop performs a binary search for the shortest fit segment that
    %produces a fit, where the fit segment is 
    %disp(['Out segment: ' num2str(out_segment(1)) ' to ' num2str(out_segment(end))])
    while ~exit_condition
        current_dist = new_dist;
        assert(all(ice_thick(fit_segment) > 0))
        C_0 = abs(corr(geo_power(fit_segment), ...
                             ice_thick(fit_segment)));
        if C_0 >= C_0_min && ...
           fit_segment(1) <= out_segment(1) &&...
           fit_segment(end) >= out_segment(end)
            %if initial correlation check successful, do full fit
            %we also require that the fit_segment contains the entire
            %out_segment
            [~, atten_rate, atten_unc, C_min, C_0] = ...
                    fit_attenuation_rate(geo_power(fit_segment) , ...
                                         ice_thick(fit_segment), ...
                                         C_hw);
            if loose_unc %if loose_unc enabled, allow wider uncertainty
                atten_unc_thresh = max(att_unc_max,atten_rate*att_unc_per);
                %impose an upper limit on %uncertainty
                atten_unc_thresh = min(atten_unc_thresh, att_unc_max_per);
            else %else, use strict cutoff that doesn't depend on atten_rate
                atten_unc_thresh = att_unc_max;
            end
            %check if full fit successful
            if C_min        <= C_m_max ...
               && atten_unc <= atten_unc_thresh
                %fit is successful, so update successful fit distance
                min_fitted = current_dist;
                best_fit = fit_segment; %saving successful fit segment
            else
                max_failed = current_dist;
            end
        else %initial correlation check unsuccesful, or fit_segment doesn't
             %contain entire out_segment, so record failure
            max_failed = current_dist;
        end
        %find 
        fit_segment = next_segment(out_segment, max_failed, min_fitted, ...
                path_dist);
        %update fit segment distance
        %disp([num2str(fit_segment(1)) ' to ' num2str(fit_segment(end))])
        new_dist =  path_dist(fit_segment(end)) - path_dist(fit_segment(1));
        
        %check loop execution condition
        exit_condition = abs(new_dist - current_dist) < seg_len/100;
        %the loop will exit when either
        %(i) the search expands to the entire transect, which fails, or
        %(ii) the binary search converges to a particular segmen len
        %in either case, the next_segment function will return an
        %identical fit_segment to the previous fit_segment
        
    end
    
    if min_fitted == Inf %if minimum fitted hasn't been changed, 
        %then none of the fits have worked, so record the failure
        
        disp(['Segment failed: ' num2str(min(out_segment)) ...
            ' to ' num2str(max(out_segment))])
        seg_distance = path_dist(max(out_segment)) - ...
                       path_dist(min(out_segment));
        disp(['Segment distance: ' num2str(seg_distance)])
        atten_rate_array(out_segment) = NaN;
        reflectivity_array(out_segment) = NaN;
        fit_segment_index(out_segment,:) = NaN(length(out_segment), 2);
        fit_distance_array(out_segment) = NaN;
    else %min_fitted has a value of the shortest-found fit, so record data
        %get reflectivity, attenuation rate, and fit stats form best fit
        [~, atten_rate, atten_unc, C_min, C_0] = ...
                    fit_attenuation_rate(geo_power(best_fit) , ...
                                         ice_thick(best_fit), ...
                                         C_hw); %
        disp(['Segment passed: ' num2str(min(out_segment)) ...
            ' to ' num2str(max(out_segment)) ...
            ' -- Fit segment: ' num2str(min(best_fit)) ...
            ' to ' num2str(max(best_fit))])
        fit_distance = path_dist(max(best_fit)) - ...
                        path_dist(min(best_fit));
        disp(['Fit distance: ' num2str(fit_distance )])
        disp(['Atten rate: ' num2str(atten_rate)])
        atten_rate_array(out_segment) = atten_rate;
        reflectivity_array(out_segment) = geo_power(out_segment) + ...
                                          2*atten_rate*...
                                          ice_thick(out_segment);
        fit_segment_index(out_segment,:) = ...
            ones(length(out_segment), 1)* ...
            [min(best_fit), max(best_fit)];
        fit_distance_array(out_segment) = fit_distance;
    end
    %record the fit statistics
    atten_unc_array(out_segment) = atten_unc;
    C_0_array(out_segment) = C_0;
    C_min_array(out_segment) = C_min;
end

%assemble the fit data in a structure and return

results.atten_rate = atten_rate_array;
results.atten_unc = atten_unc_array;
results.reflect = reflectivity_array;
results.C_0 = C_0_array;
results.C_min = C_min_array;
results.fit_segment_index = fit_segment_index;
results.fit_dist = fit_distance_array;



end

function [segment_indices] = ...
    initialize_out_segments(seg_len, path_dist)
%initialize  non-overlapping output segments. The segments all include.
%All the segments will be at least 
%seg_len long, except potentially the last segment. 

%seg_len should have the same units as path_dist (ie km)

num_segments = ceil( path_dist(end)/seg_len ) + 1;
if num_segments <= 1 %includes case num_segments = 0
                     %(if seg_len >> transect length)
    segment_indices = [1 length(path_dist)];
else
    segment_indices = zeros(num_segments, 2);
    segment_indices(1, :) =   [1 ...
                               find(path_dist >= path_dist(1)+seg_len, 1)];
    save_index = 2; %initialize row index
    for i = 2:num_segments
        seg_start = min(1+segment_indices(save_index-1,2), ...
                        length(path_dist));
        seg_end = find(path_dist >= path_dist(seg_start)+seg_len, 1);
        %seg_end will either be >= (1+seg_start) or empty
        if isempty(seg_end)
            %this part allows the last segment to be less than seg_len
            seg_end = length(path_dist);
        end 
        %if a sensible start and end are found, then save them
        if seg_start < seg_end % if segment is one point long, it is not saved
            segment_indices(save_index, :) = [seg_start seg_end];
            save_index = save_index + 1; %increment row
        end
    end
    %remove extra trailing rows && segments with little data
    segment_indices = segment_indices(segment_indices(:,2) - ...
                                      segment_indices(:,1) > 1,:);
end

end


function [segment_indices] = initialize_segments(seg_len, seg_sep, path_dist)
%initializes output segments having a minimum length of seg_len
%the number of segments is ~2*transect_length/seg_len. Adjacent segments
%overlap by 50%. The amount of overlap with the last segment is not
%guaranteed. Additionally, if the data are not spaced evenly, then the
%overlap amount may vary

%seg_len should have the same units as path_dist (ie km)

num_segments = ceil( (path_dist(end)-seg_len)/seg_sep ) + 1;
if num_segments <= 1 %includes case num_segments = 0
                     %(if seg_len >> transect length)
    segment_indices = [1 length(path_dist)];
else
    segment_indices = zeros(num_segments, 2);
    segment_indices(1, :) =   [1 ...
                               find(path_dist >= path_dist(1)+seg_len, 1)];
    segment_indices(end, :) = ...
        [find(path_dist <= path_dist(end) - seg_len, 1, 'last'), ...
         length(path_dist)];
    save_index = 2; %initialize row index
    for i = 2:num_segments-1 %middle rows
        seg_start = find(path_dist <= seg_sep*(i-1), 1, 'last');
        seg_end = find(path_dist >= seg_sep*(i-1)+seg_len, 1);
        %if a sensible start and end are found, then save them
        if seg_start < seg_end %catches NaN
            %also check that segment is not a duplicate of previous one
            if seg_start ~= segment_indices(save_index-1, 1) && ...
               seg_end   ~= segment_indices(save_index-1, 2)
            segment_indices(save_index, :) = [seg_start seg_end];
            save_index = save_index + 1; %increment row
            end
        end
    end
    %remove extra trailing rows && segments with little data
    segment_indices = segment_indices(segment_indices(:,2) - ...
                                      segment_indices(:,1) > seg_len,:);
end


%first column is segment beginnings, second column is segment end
 

end

%TODO: ensure consistent distance calculation when fit segment against
%transect boundary


function [new_fit_seg] = next_segment(old_fit_seg, max_failed, ...
                                      min_fit, path_dist)
    %old_seg and %new_seg includes all the indices in the segment
    %max_failed is distance of longest fit that has failed, so far
    %min_fit is distance of shortest fit that has worked, so far
    
%check that minimum fit distance is longer than maximum fit distance
if max_failed > min_fit 
    %if it's not, then we're seeing non-monotonic behavior, so it's best
    %to stop the search and go with the shortest working fit
    new_dist = min_fit; 
    disp('Non-mono behavior')
else
    if min_fit == Inf
        %if haven't found a good fit yet, double fit distance
        new_dist = max_failed*2;  
    else
       %normally, we want to try the distance in between the longest failed
       %segment and the shortest successfully fit segment
        new_dist = (max_failed+min_fit)/2;
    end
end
seg_middle = path_dist(floor(median(old_fit_seg)));

%start at last pick before half of distance before segment middle
new_seg_start = find(path_dist < seg_middle - new_dist/2, ...
            1, 'last');
%end at first pick after half of distance after segment middle
new_seg_end = find(path_dist > seg_middle + new_dist/2, ...
                1, 'first');

            
if isempty(new_seg_start) && isempty(new_seg_end)
    %if fit distance is longer than transect (awkward...)
    new_seg_start = 1;
    new_seg_end = length(path_dist);
elseif isempty(new_seg_start)
    %if fit segment abuts beginning of transect
    new_seg_start = 1;
    new_seg_end = find(path_dist >= min(new_dist + path_dist(1), ...
                                        path_dist(end)), ...
                       1, 'first');
elseif isempty(new_seg_end)
%if fit segment abuts end of transect
    new_seg_end = length(path_dist);
    new_seg_start = find(path_dist <= max(path_dist(end) - new_dist, ...
                                          path_dist(1)), ...
                         1, 'last');
end

%return segment

new_fit_seg = new_seg_start:new_seg_end;
 
end



