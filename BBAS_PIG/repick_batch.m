function [repick_power, repick_sample, noise_floor] = ...
    repick_batch(transect_name, pri_min, pri_max, ...
                            results_dir, radar_dir)
%repicks a transect for the picks between pri_min and pri_max

%repick_parameters
MA_window_size = 11; %number of traces to average for re-pick
calc_window_size = 101; %size of sample window around pick (in fast time)
repick_window_size = 81; %number of samples to search near pick for re-pick
noise_floor_range = 1190:1205; %range of samples to use for noisefloor

%retrieve necessary parameters from results
results_file_name = [transect_name 'Bot_results.mat'];
curr_dir = cd(results_dir);
results = load(results_file_name);
cd(curr_dir)
results = results.results; %remove wrapper
res_pri = results.PriNum;
res_bed_sample = results.botPickLoc;
%discard first and last picks to ensure sufficient radar data

%select picks corresponding to range
pick_sample = res_bed_sample(res_pri >= pri_min & res_pri <= pri_max);
pick_pri = res_pri(res_pri >= pri_min & res_pri <= pri_max);

%retrieve radar data 
sar_out_min_pri = pri_min - 50*ceil(MA_window_size/2);
sar_out_max_pri = pri_max + 50*ceil(MA_window_size/2);
sar_out = get_radar_pri(transect_name, ...
                        sar_out_min_pri, sar_out_max_pri, ...
                        radar_dir);
sar_out_pri = linspace(sar_out_min_pri,sar_out_max_pri,size(sar_out,2));

%repicking based on max of interpolated bed_power for a window 20 samples
%above pick to 20 samples below pick


repick_sample = zeros(length(pick_sample),1); %sample of re-pick
repick_power = zeros(length(pick_sample),1); %dB power of re-pick
noise_floor  = zeros(length(pick_sample),1); %noise floor, for repick
repick_range = (-repick_window_size+1)/2 : (repick_window_size-1)/2;
repick_range = repick_range + (calc_window_size-1)/2;
for j = 1:length(pick_sample)
    sample_range = (pick_sample(j) - (calc_window_size-1)*1/2) : (pick_sample(j) + (calc_window_size-1)*1/2);
    sample_range = round(sample_range); %rounding because picks at decimal values
    trace_range = zeros(1,MA_window_size);
    for k = 1:MA_window_size
        trace_offset = k-(MA_window_size-1)/2-1; %ranges from -10 to 10
        if j + trace_offset < 1
            trace_range(k) = find(pick_pri(1) < sar_out_pri,1);
        elseif j + trace_offset > length(pick_pri)
            trace_range(k) = find(pick_pri(end) < sar_out_pri,1);
        else 
        trace_range(k) = find(pick_pri(j + trace_offset) < sar_out_pri,1);
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
    repick_sample(j) = pick_sample(j) + peak_index - (repick_window_size-1)/2-1;
end

%convert noise floor to dB scale
noise_floor = 10*log10(noise_floor);

end

