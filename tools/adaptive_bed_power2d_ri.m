function [results] = ...
    adaptive_bed_power2d_ri(results, survey, kdtree, seg_len, ... 
                                    min_rad, loose_unc, use_bm_thick)
%results is a structure containin fields
%Adaptively determine attenuation rate to determine bed reflectivity

%seg_len is minimum fitting distance in km
%min_rad is minimum fitting radius in km

%this version allows 10% attenuation uncertain

%if transect is empty (due to filtering for ice thickness or bed power, eg)
if isempty(results.max_pow)
    results.atten_rate = zeros(0,1);
    results.atten_unc = zeros(0,1);
    results.reflect = zeros(0,1);
    results.C_0 = zeros(0,1);
    results.C_min = zeros(0,1);
    results.fit_dist = zeros(0,1);
    return
end;

    
max_fit_radius = 500; %km
C_0_min = -0.5; %minimum correlation for thickness and geometrically corrected power
att_unc_max = 0.001; %dB/km
att_unc_max_per = 0.003; %dB/km (max when using percentage attenuation rate)
att_unc_per = 0.1; %allow any attenution rate with uncertainty below 10%
C_m_max = 0.01; %maximum allowable correlation at fit attenuation
C_hw = 0.1; %For calculating atten uncertainty

%shorten variable names from results file
path_dist = results.rdr_dist/1000; %convert to km
if use_bm_thick
    ice_thick = survey.bm_thick;
    ts_ice_thick = results.bm_thick;
else
    ice_thick = survey.rdr_thick;
    ts_ice_thick = results.rdr_thick;
end
%use calib-corrected bed powers if available
if isfield(results, 'agg_pow_calib')
    bed_power = survey.agg_pow_calib;
    ts_bed_power = results.agg_pow_calib;
elseif isfield(results,'agg_pow_xover')
    bed_power = survey.agg_pow_xover;
    ts_bed_power = results.agg_pow_xover;
else
    bed_power = survey.agg_pow;
    ts_bed_power = results.agg_pow;
end
ts_idx = survey.ts_idx; 
%calculate geometrically corrected bed power
geo_power = geo_correct_power(bed_power, survey.rdr_clear, ice_thick);
ts_geo_power = geo_correct_power(ts_bed_power, results.rdr_clear, ...
                                 ts_ice_thick);

L = length(results.agg_pow);
%initialize outputs
atten_rate_array = zeros(L,1);
atten_unc_array = zeros(L,1);
reflectivity_array = zeros(L,1);
C_0_array = zeros(L,1);
C_min_array = zeros(L,1);
fit_distance_array = zeros(L,1);

%segment_indices gives segment beginnings and ends as row vectors
segment_indices = initialize_out_segments(seg_len, path_dist);
%the returned segments have a minimum length of seg_len
num_segments = size(segment_indices, 1); %number of row vectors


%fit_radius = 0; %initialize fit_radius
num_success = 0; %number of successful fits

%for each segment
for i = 1:num_segments
    %find points from (i-1)th km to ith km
    out_segment = segment_indices(i,1):segment_indices(i,2);
    %initialize fit with radius equal to min_radius or half of last
    %successful fit_radius
    [fit_idx, fit_radius] = get_fit_idx(out_segment, results, kdtree, ...
                                        min_rad/2, ...
                                        Inf, max_fit_radius);
    assert(fit_radius >= min_rad)
    

    %if segment has significantly fewer piks/km than average, expand it
    while length(fit_idx)/fit_radius*2 ...
          < length(path_dist)/max(path_dist)
        [fit_idx, fit_radius] = get_fit_idx(out_segment, results, kdtree, ...
                                        fit_radius, Inf, max_fit_radius);
        disp('Expanding fit segment due to insufficient data density')
    end
    
    %initialize quality parameters
    C_0 = 0;
    C_min = 1;
    atten_unc = 100;
    
    %initialize distance of shortest successful fit as Infinity
    min_fitted = Inf; 
    %initialize max_failed in case the first fit succeeds
    max_failed = fit_radius;
    %initialize exit condition to false to gauarantee at least one loop
    %execution
    exit_condition = false;
    %this loop performs a binary search for the shortest fit segment that
    %produces a fit, where the fit segment is 
    %disp(['Out segment: ' num2str(out_segment(1)) ' to ' num2str(out_segment(end))])
    while ~exit_condition
        C_0 = corr(geo_power(fit_idx), ice_thick(fit_idx));
        if C_0 <= C_0_min 
            %if initial correlation check successful, do full fit
            [~, atten_rate, atten_unc, C_min, ~] = ...
                    fit_attenuation_rate_ri(geo_power(fit_idx) , ...
                                         ice_thick(fit_idx), ...
                                         C_hw, ts_idx(fit_idx));
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
                min_fitted = fit_radius;
                best_fit = fit_idx; %saving successful fit segment
            else
                max_failed = fit_radius;
            end
        else %initial correlation check unsuccesful, or fit_idx doesn't
             %contain entire out_segment, so record failure
            max_failed = fit_radius;
        end
        %expand fitting radius
        old_radius = fit_radius;
        [fit_idx, fit_radius] = get_fit_idx(out_segment, results, ...
                                            kdtree, max_failed, ...
                                            min_fitted, max_fit_radius);
        %check loop execution condition
        exit_condition = abs(old_radius - fit_radius) < 0.1;
        %the loop will exit when either
        %(i) the radius is as long as the entire transect, or
        %(ii) the binary search converges to a particular segmen len
        %in either case, the next_segment function will return an
        %identical fit_segment to the previous fit_segment
        
    end
    
    if min_fitted == Inf %if minimum fitted hasn't been changed, 
        %then none of the fits have worked, so record the failure
        
        disp(['Segment failed: ' num2str(min(out_segment)) ...
            ' to ' num2str(max(out_segment))])
        disp(['Segment radius: ' num2str(fit_radius)])
        atten_rate_array(out_segment) = NaN;
        reflectivity_array(out_segment) = NaN;
        fit_distance_array(out_segment) = NaN;
    else %min_fitted has a value of the shortest-found fit, so record data
        %get reflectivity, attenuation rate, and fit stats form best fit
        [~, atten_rate, atten_unc, C_min, C_0] = ...
                    fit_attenuation_rate_ri(geo_power(best_fit) , ...
                                         ice_thick(best_fit), ...
                                         C_hw, ts_idx(best_fit)); %
        disp(['Segment passed: ' num2str(min(out_segment)) ...
            ' to ' num2str(max(out_segment))])
        disp(['Fit radius: ' num2str(fit_radius)])
        disp(['Atten rate: ' num2str(atten_rate)])
        atten_rate_array(out_segment) = atten_rate;

        reflectivity_array(out_segment) = ts_geo_power(out_segment) + ...
                                            2*atten_rate*...
                                            ts_ice_thick(out_segment);
        fit_distance_array(out_segment) = fit_radius;
        num_success = num_success + 1; 
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
results.fit_dist = fit_distance_array;
results.fit_rate = num_success/num_segments;



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


function [fit_idx, new_radius] = get_fit_idx(out_seg, results, kdtree, ...
                                  max_failed,  min_fit, max_radius)
%out_seg is the output segment, results contains the transect results, and
%kdtree contains the xy coordinates of all survey points, sorted to enable
%quick searching max_failed and min_fit are search radii

%this is currently using a radius around the middle of segment. This could
%be expanded to grab radius around additional points (ie end points)
    
%check that minimum fit radius is longer than maximum fit radius
if max_failed > min_fit 
    %if it's not, then we're seeing non-monotonic behavior, so it's best
    %to stop the search and go with the shortest working fit
    new_radius = min_fit; 
    disp('Non-mono behavior')
else
    if min_fit == Inf
        %if haven't found a good fit yet, double fit distance
        new_radius = min(max_failed*2, max_radius);
        %don't allow any radius greater than max radius
    else
       %normally, we want to try the distance in between the longest failed
       %segment and the shortest successfully fit segment
        new_radius = (max_failed+min_fit)/2;
    end
end
seg_middle = floor(median(out_seg));

fit_idx = rangesearch(kdtree, ...
                      [results.easts(seg_middle), ...
                       results.norths(seg_middle)], ...
                      new_radius*1000); %convert to meters
fit_idx = fit_idx{1}; %extract from cell structure
 
end



