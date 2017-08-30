function [max_pow, mp_sample, noise_floor, agg_pow, ft_range] = ...
    repick_bed(results, radar_hi, radar_lo)
%repicks a transect for the picks between pri_min and pri_max

%repick_parameters
c_light = 299.7925;
n_ice = c_light/168.374; %from Holt 06
pulse_hw = 10; %m, halfwidth = c_light/pulse chirp frequency/2
f_sample = 22; %MHz 
noise_floor_range = 3100:3150; %range of samples to use for noisefloor

%retrieve necessary parameters from results
pick_sample = results.bed_pik_sample;
pick_clear = results.rdr_clear;
pick_thick = results.rdr_thick;

L = length(pick_sample); %number of traces

%initialize results arrays
mp_sample = zeros(L,1); %sample of re-pick
max_pow = zeros(L,1); %dB power of re-pick
agg_pow = zeros(L,1); %aggregated power

%calc repick fast time range based on Fresnel zone (Jordan, Oswald & Gogin)
samples_per_meter = f_sample/c_light/2; %divide by 2 because roundtrip
ft_range = sqrt(pulse_hw*(pick_thick/n_ice + pick_clear))*samples_per_meter;
%calc how many traces to average assuming 100 m/pik

%use hi-gain channel for noise-floor, because when we combine high and low
%gain channels, we use high-gain channel for low-power measurements
noise_floor = ones(L,1)*mean(mean(radar_lo(noise_floor_range,:), ...
                                  'omitnan'), 'omitnan');

for j = 1:length(pick_sample)
    %don't allow any picks from below noise floor range because it has a
    %wraparound effect from fft calc
    sample_range = max(1, round((pick_sample(j) - ft_range(j)))): ...
                   min(noise_floor_range(1), ...
                       round((pick_sample(j) + ft_range(j))));
    %rounding because picks at decimal values

    %if all samples from below noise floor range, set values to nan
    if isempty(sample_range)
        agg_pow(j) = NaN; max_pow(j) = NaN; mp_sample(j) = NaN;
        continue
    end
    
    power_samples = combine_bed_pow(radar_lo(sample_range, j), ...
                                    radar_hi(sample_range, j));
    
    agg_pow(j) = sum(power_samples);
    %use the sample with max power within the sample range
    [max_pow(j), peak_index] = max(power_samples);
    %offset index of max power sample using index of beginning of range
    mp_sample(j) = sample_range(1) + peak_index - 1;
    %subtract noise_floor to normalize
    max_pow(j) = max_pow(j) - noise_floor;
    agg_pow(j) = agg_pow(j) - noise_floor*length(power_samples);
end

end

