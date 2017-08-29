function [lat, long, reflectivity_array ] = ...
    adapt_bed_pow_interp_loose(transect_name, results_dir, save_dir)
%Adaptively determine attenuation rate to determine bed reflectivity

C_0_min = 0.5; %minimum correlation for thickness and geometrically corrected power
att_unc_max = 0.002; %dB/km
C_m_max = 0.01; %maximum allowable correlation at fit attenuation

%load repick_results
orig_dir = cd(results_dir);
repick_name = [transect_name '_SRG_interp_repick.mat'];
load(repick_name)
cd(orig_dir)

%shorten variable names from results file
lat = SRG_results.repick_lat;
long = SRG_results.repick_long;
repick_sample = SRG_results.repick_sample; %sample of bottom repick, 0 to 1250
surf_sample = SRG_results.interp_surf_pick; %sample of surface pick, 0 to 1250
clearance = SRG_results.repick_clear; %aircraft clearance from ice, m
repick_power = SRG_results.repick_power; % dB


%calculate time between bed and surface
c_light = 2.99792e8; %m/s
n_ice = 1.78; %
f_sample = 22e6; %Hz 
bed_to_surf_time = 1/2*(repick_sample-surf_sample)/f_sample;
derived_thick = c_light/n_ice*bed_to_surf_time;

%%get path distance
cd /data/cees/amhilger/BEDMAP/
path_dist = pathdistps(lat, long, 'km'); %distance in km
cd /data/cees/amhilger/BBAS_PIG/


atten_rate_array = zeros(size(repick_sample));
atten_unc_array = zeros(size(repick_sample));
reflectivity_array = zeros(size(repick_sample));
C_0_array = zeros(size(repick_sample));
C_min_array = zeros(size(repick_sample));
fit_segment_index = zeros(length(repick_sample), 2);
fit_distance_array = zeros(length(repick_sample), 1);


num_segments = floor(max(path_dist)) - 1;
%pass_array = zeros(size(jump_seg_starts));

%for each km of track
for i = 1:num_segments
    %find points from (i-1)th km to ith km
    out_segment = find(path_dist > i-1 & path_dist <= i);
    segment_middle = floor(median(out_segment)); 
    %skip adaptive fitting if no points in km
    if isempty(out_segment)
        disp('Skipsies!')
        disp(['distance = i = ' num2str(i)])
        continue
    end
    %accelerate calculations when an output segment is deep inside the
    %previous fit segment
%     if max(out_segment)*2 < max(prev_fit_segment) && ...
%         min(out_segment) >= min(prev_fit_segment) && ...
%         prev_segment_fail == 0
%             fit_segment = prev_fit_segment;
    %initial segment to fit, require minimum number of points
    min_points = 50; %assume minimum number of points is even
    if length(out_segment) < min_points
        fit_segment_start = max(1, segment_middle - min_points/2+1);
        fit_segment_end = min(length(repick_sample), ...
			      segment_middle + min_points/2);
        fit_segment = fit_segment_start:fit_segment_end;
    else
        fit_segment = out_segment;
    end
    %initialize quality parameters
    C_0 = 0;
    C_min = 1;
    atten_unc = 100;
    %while quality measures unmet
    while (C_min > C_m_max || C_0 < C_0_min || atten_unc > att_unc_max)
        C_0 = min_corr_check(repick_power(fit_segment), ...
                                derived_thick(fit_segment), ...
                                clearance(fit_segment));
        while C_0 < C_0_min && ok_segment_length(fit_segment, path_dist)
            %increment segment length by ~1 km if insufficient correlation
            %check if thickness sufficiently correlated with bed power
            fit_segment = expand_segment(fit_segment, path_dist);
            C_0 = min_corr_check(repick_power(fit_segment), ...
                                derived_thick(fit_segment), ...
                                clearance(fit_segment));
            disp(['C_0 = ' num2str(C_0) ', fit distance = ' num2str(path_dist(max(fit_segment)) - ...
                            path_dist(min(fit_segment)))])
        end
        %once sufficient correlation without attenuation correction, find
        %attenuation correction that minimizes correlation b/w thickness and
        %corrected power
        [reflectivity, atten_rate, atten_unc, C_min, C_0] = ...
            fit_attenuation_rate(repick_power(fit_segment) , ...
                                derived_thick(fit_segment), ...
                                clearance(fit_segment));
        disp(['C_0 = ' num2str(C_0) ', C_min = ' num2str(C_min) ...
            ', att_uncert = ' num2str(atten_unc) ...
            ', fit distance = ' num2str(path_dist(max(fit_segment)) - ...
                            path_dist(min(fit_segment)))])  
        if C_min <= C_m_max && C_0 >= C_0_min && atten_unc <= att_unc_max
            %if successful, save data and start next segment
            disp(['Segment passed: ' num2str(min(out_segment)) ...
                ' to ' num2str(max(out_segment)) ...
                ' -- Fit segment: ' num2str(min(fit_segment)) ...
                ' to ' num2str(max(fit_segment))])
            fit_distance = path_dist(max(fit_segment)) - ...
                            path_dist(min(fit_segment));
            disp(['Fit distance: ' num2str(fit_distance)])
            disp(['Atten rate: ' num2str(atten_rate)])
            atten_rate_array(out_segment) = atten_rate;
            atten_unc_array(out_segment) = atten_unc;
            out_reflectivity = reflectivity(out_segment - min(fit_segment) + 1);
            reflectivity_array(out_segment) = out_reflectivity;
            C_0_array(out_segment) = C_0;
            C_min_array(out_segment) = C_min;
            fit_segment_index(out_segment,:) = ...
                ones(length(out_segment), 1)* ...
                [min(fit_segment), max(fit_segment)];
            fit_distance_array(out_segment) = fit_distance;
        elseif ~ok_segment_length(fit_segment, path_dist)
            %if unsuccessful and segment length excessive, save failure
            disp(['Segment failed: ' num2str(min(out_segment)) ...
                ' to ' num2str(max(out_segment))])
            disp(['Fit segment: ' num2str(min(fit_segment)) ...
                ' to ' num2str(max(fit_segment))])
            fit_distance = path_dist(max(fit_segment)) - ...
                path_dist(min(fit_segment));
            disp(['Fit distance: ' num2str(fit_distance)])
            atten_unc_array(out_segment) = atten_unc;
            if isempty(C_0)
                C_0 = NaN; 
            end
            C_0_array(out_segment) = C_0;
            if isempty(C_min)
                C_min = NaN;
            end
            C_min_array(out_segment) = C_min;
            atten_rate_array(out_segment) = NaN;
            reflectivity_array(out_segment) = NaN;
            fit_segment_index(out_segment,:) = ...
		ones(length(out_segment), 1)* ...
		[min(fit_segment), max(fit_segment)];
	    fit_distance_array(out_segment) = fit_distance;
	    break;
        else %if any conditions failed, lengthen segment by 1 km
            fit_segment = expand_segment(fit_segment, path_dist);
        end
    end
    
end

%save the data
cd(save_dir);
save_name = [transect_name '_adapt_interp_results.mat'];
adapt_results = SRG_results;
adapt_results.atten_rate = atten_rate_array;
adapt_results.atten_unc = atten_unc_array;
adapt_results.reflectivity = reflectivity_array;
adapt_results.C_0 = C_0_array;
adapt_results.C_min = C_min_array;
adapt_results.fit_segment_index = fit_segment_index;
adapt_results.adapt_path_dist = path_dist;
adapt_results.fit_distance = fit_distance_array;
adapt_results.derived_thick = derived_thick;
save(save_name, 'adapt_results')
cd(orig_dir)




%}
% t = 1:num_segments;
% figure
% subplot(2,1,1)
% plot(t, C_0_array, t, C_min_array)
% subplot(2,1,2)
% plot(t,atten_rate_array)

%plot_flight_track(lat, long, repick_power)

end

function [] = plot_flight_track(lat, long, repick_power)
%%Plotting the flight track

curr_dir = cd('../BEDMAP/');
figure
avg_pick_lat = mean(lat);
avg_pick_long = mean(long);
mapzoomps(avg_pick_lat, avg_pick_long, 'mapwidth', 500)
bedmap2('grounding line','xy')
[plot_x,plot_y] = ll2ps(lat, long);
plot_z = zeros(size(plot_x));
plot_col = repick_power;
surface([plot_x,plot_x],[plot_y,plot_y], ...
    [plot_z,plot_z],[plot_col,plot_col],...
    'facecol','no',...
    'edgecol','interp',...
    'linew',2);
graticule_lats = floor(avg_pick_lat)-5:ceil(avg_pick_lat)+5;
graticule_lats = graticule_lats(graticule_lats>-90); %remove lats beyond 90 S
graticule_longs = floor(avg_pick_long)-10:ceil(avg_pick_long)+10;
graticuleps(graticule_lats, graticule_longs,'r:','linewidth',0.5)
cd(curr_dir)

end

function [new_fit_segment] = expand_segment(old_fit_segment, path_dist)

delta_seg_length = 1; %expand segment length 1 km at a time
old_start_dist = path_dist(min(old_fit_segment));
old_end_dist = path_dist(max(old_fit_segment));
new_seg_start = find(path_dist < old_start_dist - delta_seg_length/2, ...
                1, 'last');
new_seg_end = find(path_dist > old_end_dist + delta_seg_length/2, ...
                1, 'first');
            
%bound segment to first and last picks
if isempty(new_seg_start)
    new_seg_start = 1;
%     new_seg_end = find(path_dist > old_end_dist + delta_seg_length, ...
%                 1, 'first');
end
if isempty(new_seg_end)
    new_seg_end = length(path_dist);
%     new_seg_start = find(path_dist < old_start_dist - delta_seg_length, ...
%                 1, 'last');
end

%if segment is identical to old one,
%(due to geographically sparse data points, force expansion
if new_seg_start == min(old_fit_segment) && new_seg_start ~= 1
    new_seg_start = new_seg_start - 1;
end
if new_seg_end == max(old_fit_segment) && new_seg_end ~= length(path_dist)
    new_seg_end = new_seg_end + 1;
end

%return segment
new_fit_segment = new_seg_start:new_seg_end;
end

function [is_reasonable] = ok_segment_length(segment, path_dist)

%max_allowable length is lesser of 600 km or half of transect length
%max_dist = min(max(path_dist)/2, 600); 
max_dist = path_dist(end-1);
current_dist = path_dist(max(segment)) - path_dist(min(segment));
is_reasonable = current_dist < max_dist;


end

%This function divides the data into segments based on jumps in path
%distance on the theory that large jumps in path distance will lead to
%increased likelihood of changes in terrain that would hurt correlation
%between power and thickness. Ultimately, it is not being used in the
%current adaptive fitting function. 
%{
function [seg_starts, seg_stops, jump_seg_starts, jump_seg_stops] = ...
    segment_path(path_dist)
%segments path based on difference of distances
diff_dist = diff(path_dist);
%indices of picks after an abnormally large distance jump
jumps = find(diff_dist > mean(diff_dist) + std(diff_dist));
%define bad jumps as jumps occuring less than 1 km after another jump
bad_jump_indices = 1+find(diff(path_dist(jumps)) < 1);
bad_jumps = jumps(bad_jump_indices);
good_jumps = setxor(bad_jumps, jumps); %remove bad jumps from set of jumps
% a jump-defined segment ends before a good jump
jump_seg_stops = good_jumps - 1; 
jump_seg_starts = zeros(size(jump_seg_stops));
jump_seg_starts(1) = 1; %base case
for i = 2:length(jump_seg_stops)
    prev_good_jump = good_jumps(i-1); %previous good jump before
    bad_jumps_between = bad_jumps(bad_jumps > prev_good_jump & ...
                            bad_jumps < jump_seg_stops(i));
    if isempty(bad_jumps_between)
        jump_seg_starts(i) = prev_good_jump;
    else
        jump_seg_starts(i) = max(bad_jumps_between);
    end
end
%enforce a minimum of 10 picks in a segment
num_seg_points = jump_seg_stops-jump_seg_starts;
jump_seg_stops = jump_seg_stops(num_seg_points >= 10);
jump_seg_starts = jump_seg_starts(num_seg_points >= 10);
num_seg_points = num_seg_points(num_seg_points >= 10);

%enforce a minimum of 5 picks/km in a segment
jump_seg_dist = path_dist(jump_seg_stops) - path_dist(jump_seg_starts);
seg_pick_density = num_seg_points./jump_seg_dist;
jump_seg_stops = jump_seg_stops(seg_pick_density > 5);
jump_seg_starts = jump_seg_starts(seg_pick_density > 5);
jump_seg_dist = jump_seg_dist(seg_pick_density > 5);

%divide remaining segments into 1 km subsegments
num_subsegs = max(1, floor(jump_seg_dist)); %guard against a zero
seg_starts = [];
seg_stops = [];
for i = 1:length(jump_seg_starts)
    if num_subsegs(i) == 1
        subseg_starts = jump_seg_starts(i);
        subseg_stops = jump_seg_stops(i);
    else
        subseg_stops = floor(linspace(jump_seg_starts(i), ...
                                     jump_seg_stops(i), ...
                                     num_subsegs(i) + 1));
        subseg_stops = subseg_stops(2:end);
        subseg_starts = subseg_stops(1:end-1) + 1;
        subseg_starts = [jump_seg_starts(i) subseg_starts];
    end
    seg_starts = [seg_starts subseg_starts];
    seg_stops = [seg_stops subseg_stops];
    if length(seg_starts) > length(seg_stops)
        error('Number of segment starts ~= Number of segment stops')
    end
    if any(subseg_starts >= subseg_stops)
        error('Segment starts while or after it stops')
    end
end

end
%}


