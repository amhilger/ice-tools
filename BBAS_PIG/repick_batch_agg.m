function [max_pow, mp_sample, noise_floor, agg_pow, ft_range] = ...
    repick_batch_agg(transect_name, pri_min, pri_max, ...
                            results_dir, radar_dir)
%repicks a transect for the picks between pri_min and pri_max

n_ice = 299.8/168; %from Vaughan
pulse_hw = 15; %m, c_light/pulse chirp frequency/2

%repick_parameters
MA_window_size = 10; %number of traces to average for re-pick
assert(mod(MA_window_size, 2) == 0) %MA_window must be even 
noise_floor_range = 1190:1205; %range of samples to use for noisefloor

%retrieve necessary parameters from results
results_file_name = [transect_name '_results.mat'];
curr_dir = cd(results_dir);
load(results_file_name);
cd(curr_dir)
res_pri = results.pri;
res_bed_sample = results.bed_pik_sample;
res_clear = results.rdr_clear;
res_thick = results.rdr_thick;
%discard first and last picks to ensure sufficient radar data

%select picks corresponding to range
pick_sample = res_bed_sample(res_pri >= pri_min & res_pri <= pri_max);
pick_clear = res_clear(res_pri >= pri_min & res_pri <= pri_max);
pick_thick = res_thick(res_pri >= pri_min & res_pri <= pri_max);
pick_pri = res_pri(res_pri >= pri_min & res_pri <= pri_max);

%retrieve radar data 
sar_out_min_pri = pri_min - 50*ceil(MA_window_size/2);
sar_out_max_pri = pri_max + 50*ceil(MA_window_size/2);
sar_out = get_radar_pri(transect_name, ...
                        sar_out_min_pri, sar_out_max_pri, ...
                        radar_dir);
sar_out_pri = linspace(sar_out_min_pri,sar_out_max_pri,size(sar_out,2));


%initialize results arrays
mp_sample = zeros(length(pick_sample),1); %sample of re-pick
max_pow = zeros(length(pick_sample),1); %dB power of re-pick
noise_floor  = zeros(length(pick_sample),1); %noise floor, for repick
agg_pow = zeros(length(pick_sample),1); %aggregated power

%calc repick fast time range based on Fresnel zone (Jordan, Oswald & Gogin)
samples_per_meter = 22/299.8/2; %22MHz sampling, speed of light
ft_range = sqrt(pulse_hw*(pick_thick/n_ice + pick_clear))*samples_per_meter;
%calc how many traces to average assuming 100 m/pik


for j = 1:length(pick_sample)
    %don't allow any picks from below noise floor range because it has a
    %wraparound effect from fft calc
    sample_range = max(1, round((pick_sample(j) - ft_range(j)))): ...
                   min(1190, round((pick_sample(j) + ft_range(j))));
    %rounding because picks at decimal values
    trace_num = find(pick_pri(j) <= sar_out_pri,1);
    trace_range = max(1, (trace_num - MA_window_size/2)) : ...
                  min(size(sar_out, 2), (trace_num + MA_window_size/2));
    noise_floor(j) = 10*log10(mean(mean(abs(sar_out(noise_floor_range, ...
                                           trace_range)))));
    %if all samples from below noise floor range, set values to nan
    if isempty(sample_range)
        agg_pow(j) = NaN; max_pow(j) = NaN;
        noise_floor(j) = NaN; mp_sample(j) = NaN;
        continue
    end
    
    %performs the centered moving average over the trace range
    power_samples = mean(abs(sar_out(sample_range, trace_range)), 2);
    %take noise floor from bottom of radargram
    
    
    %perform light-touch moving average filter to attenuate funkiness
    %filt_power = sgolayfilt(power_samples, 2, 5);
    %convert to log scale
    
    %sum aggregate powers in linear space then convert to dB
    agg_pow(j) = 10*log10(sum(power_samples));
    %use the sample with max power within the sample range
    [max_pow(j), peak_index] = max(10*log10(power_samples));
    mp_sample(j) = sample_range(1) + peak_index - 1;
end

%subtract noise_floor to normalize
max_pow = max_pow - noise_floor;
agg_pow = agg_pow - noise_floor;


end

