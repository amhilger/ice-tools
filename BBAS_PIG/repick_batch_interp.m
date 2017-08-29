function [interp_pri, repick_power, repick_sample, noise_floor, ...
         interp_surf_pick, interp_dist, is_interp] ...
      = repick_batch_interp(transect_name, pri_min, pri_max, ...
                            results_dir, radar_dir)
%repicks a portion of a transect between pri_min and pri_max based on
%maximum power within a fast-time sample range of the input BAS picks

%interpolates synthetic picks between BAS picks and repicks both the
%original BAS picks and the synthetic BAS picks

%%ToDo: repick that's aware of expected double reflections from aircraft or
%%from surface to bed to surface to bed

%repick_parameters
MA_window_size = 11; %number of traces to average for re-pick
calc_window_size = 101; %size of sample window around pick (in fast time)
%number of samples to search near pick for re-pick (assume ODD)
repick_window_size = 81; 
noise_floor_range = 1190:1205; %range of samples to use for noisefloor

%retrieve necessary parameters from results
results_file_name = [transect_name 'Bot_results.mat'];
curr_dir = cd(results_dir);
results = load(results_file_name);
cd(curr_dir)
results = results.results; %remove wrapper
res_pri = results.PriNum;
res_bed_sample = results.botPickLoc;
res_surf_sample = results.surfPickLoc;
res_lat = results.Lat; %latitude
res_long = results.Long; %longitude

cd ../BEDMAP
path_dist = pathdistps(res_lat, res_long, 'km'); %distance in km
cd(curr_dir)
%discard first and last picks to ensure sufficient radar data

%select picks corresponding to range
bed_pick_sample = res_bed_sample(res_pri >= pri_min & res_pri <= pri_max);
pick_pri = res_pri(res_pri >= pri_min & res_pri <= pri_max);
surf_pick = res_surf_sample(res_pri >= pri_min & res_pri <= pri_max);
path_dist = path_dist(res_pri >= pri_min & res_pri <= pri_max);

%number of interpolations between ith element and ith+1 element
%Per Fretwell BEDMAP paper, elevation error is +/- 140m for 5 km grid in
%areas of higher slope. Using repick window of at least +/- 26 samples
%ensures finding bed if within 200 m {200 m/(c_light/n_ice)*F_samp = 26}
num_interps = zeros(length(bed_pick_sample)-1, 1); 
for i = 1:length(bed_pick_sample)-1 %for every pick except last one
    dist_between_picks = path_dist(i+1) - path_dist(i);
    
    %don't interpolate between picks 5 km apart, allow num_interps to
    %remain zero.
    if dist_between_picks < 5
        num_interps(i) = floor(dist_between_picks/0.005);
        %there are roughly 4000 traces per km, one every 0.25m
        %There are roughly 20 picks per km, one every 50 m
        %want re-interpolation every 5m, or 200 per km
    end
    
end

% do interpolation of sample, pri, surface pick sample, and distance
%(see internal function below)
[interp_sample, interp_pri, interp_surf_pick, interp_dist, is_interp] = ...
    interpolate_pick_sample(num_interps, pick_pri, bed_pick_sample, ...
                            surf_pick, path_dist);


%retrieve radar data 
sar_out_min_pri = pri_min - 50*ceil(MA_window_size/2);
sar_out_max_pri = pri_max + 50*ceil(MA_window_size/2);
sar_out = get_radar_pri(transect_name, sar_out_min_pri, ...
                        sar_out_max_pri, radar_dir);
%synthetic pri based on endpoints
sar_out_pri = linspace(sar_out_min_pri,sar_out_max_pri,size(sar_out,2));

%repicking based on max of interpolated bed_power for a window 20 samples
%above pick to 20 samples below pick


repick_sample = zeros(length(interp_sample),1); %sample of re-pick
repick_power = zeros(length(interp_sample),1); %dB power of re-pick
noise_floor  = zeros(length(interp_sample),1); %noise floor, for repick
repick_range = (-repick_window_size+1)/2 : (repick_window_size-1)/2;
repick_range = repick_range + (calc_window_size-1)/2;
%do the repick for each interpolated sample
for j = 1:length(interp_sample)
    sample_range = (interp_sample(j) - (calc_window_size-1)*1/2) : ...
                   (interp_sample(j) + (calc_window_size-1)*1/2);
    sample_range = round(sample_range); %rounding because picks at decimal values
    trace_range = zeros(1,MA_window_size);
    for k = 1:MA_window_size %moving window over traces
        trace_offset = k-(MA_window_size-1)/2-1; %ranges from -10 to 10
        if j + trace_offset < 1
            trace_range(k) = find(interp_pri(1) < sar_out_pri,1);
        elseif j + trace_offset > length(interp_pri)
            trace_range(k) = find(interp_pri(end) < sar_out_pri,1);
        else 
        trace_range(k) = find(interp_pri(j + trace_offset) < sar_out_pri,1);
        end
    end
    %performs the centered moving average over the trace range
    power_samples = mean(abs(sar_out(sample_range, trace_range)), 2);
    %take noise floor from bottom of radargram
    noise_floor(j) = mean(mean(abs(sar_out(noise_floor_range, ...
                                           trace_range))));
    
    %perform light-touch moving average filter to attenuate funkiness
    filt_power = sgolayfilt(power_samples, 2, 5);
    %convert to log scale
    filt_power = 10*log10(max(filt_power,1)); %sets floor of 0 dB
    %use the sample with max power within the sample range
    [repick_power(j), peak_index] = max(filt_power(repick_range));
    repick_sample(j) = interp_sample(j) + peak_index - (repick_window_size-1)/2-1;
end
%convert noise floor to dB scale
noise_floor = 10*log10(noise_floor);


end


%%%%% interpolate_pick_sample %%%%%
function [interp_sample, interp_pri, ...
            interp_surf_pick, interp_dist, is_interp] = ...
         interpolate_pick_sample(num_interps, pick_pri, ...
            pick_sample, surf_pick, path_dist)

%the interp sample array holds the sample number (in fast time)
%corresponding to each pick or interpolation between picks
interp_sample = zeros(sum(num_interps)+length(pick_sample), 1);
interp_pri    = zeros(length(interp_sample), 1);
interp_surf_pick = zeros(length(interp_sample), 1);
interp_dist   = zeros(length(interp_sample), 1);
is_interp     = zeros(length(interp_sample), 1); %indicates whether interpolated

index = 1; %index (in interp_sample, interp_pri)
for i = 1:length(pick_sample)-1 %for each pick, except last
    interp_sample(index) = pick_sample(i);
    next_index = index+num_interps(i)+1; %index of next pick
    interp_pri(index:next_index) = ...
        floor(linspace(pick_pri(i), pick_pri(i+1), num_interps(i)+2));
    %round interp_pri to nearest multiple of 50
    interp_pri = round(interp_pri/50)*50;
    %interpolate fast time samples
    dsample_dpri = (pick_sample(i+1)-pick_sample(i))/ ...
                   (pick_pri(i+1)-pick_pri(i));
    interp_sample(index:next_index) = pick_sample(i) + ...
        dsample_dpri*(interp_pri(index:next_index) - interp_pri(index));
    
    %interpolate path distance
    ddist_dpri  = (path_dist(i+1)-path_dist(i))/ ...
                  (pick_pri(i+1)-pick_pri(i));
    interp_dist(index:next_index) = path_dist(i) + ...
        ddist_dpri*(interp_pri(index:next_index) - interp_pri(index));
    
    %interpolate surface pick
    dsurf_dpri  = (surf_pick(i+1)-surf_pick(i))/ ...
                  (pick_pri(i+1)-pick_pri(i));
    interp_surf_pick(index:next_index) = surf_pick(i) + ...
        dsurf_dpri*(interp_pri(index:next_index) - interp_pri(index));

    %set interpolation flags
    is_interp(index:next_index) = [0; ones(num_interps(i), 1); 0];
    %updating index of interp_sample and interp_pri
    index = next_index; 
end

end

