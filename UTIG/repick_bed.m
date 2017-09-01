function [max_pow, mp_sample, noise_floor, agg_pow, ft_range] = ...
    repick_bed(results, radar_lo, radar_hi)
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

%compute offset between hi- and lo-gain samples
offset = compute_hi_lo_offset(results.bed_pow_lo, results.bed_pow_hi);

%initialize results arrays
mp_sample = zeros(L,1); %sample of re-pick
max_pow = zeros(L,1); %dB power of re-pick
agg_pow = zeros(L,1); %aggregated power
mp_lo = zeros(L, 1);
mp_hi = zeros(L, 1);

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
    mp_sample_range = max(1, round((pick_sample(j) - ft_range(j)))): ...
                   min(noise_floor_range(1), ...
                       round((pick_sample(j) + 2*ft_range(j))));
    %rounding because picks at decimal values

    %if all samples from below noise floor range, set values to nan
    if isempty(mp_sample_range)
        agg_pow(j) = NaN; max_pow(j) = NaN; mp_sample(j) = NaN;
        continue
    end
    
     [mp_lo(j), mp_id_lo] = max(radar_lo(mp_sample_range, j));
     [mp_hi(j), mp_id_hi] = max(radar_hi(mp_sample_range, j));
     
     [max_pow(j), channel_num] = combine_bed_pow(mp_lo(j), mp_hi(j), offset);
     
     switch channel_num
         case 1
             mp_sample(j) = mp_sample_range(1) + mp_id_lo - 1;
         case 2
             mp_sample(j) = mp_sample_range(1) + mp_id_hi - 1;
         otherwise
             mp_sample(j) = NaN;
     end
    
%     max_pow_samples = combine_bed_pow(radar_lo(mp_sample_range, j), ...
%                                       radar_hi(mp_sample_range, j), ...
%                                       offset);
%    
%     %use the sample with max power within the sample range
%     [max_pow(j), peak_index] = max(max_pow_samples);
%     %offset index of max power sample using index of beginning of range
%     mp_sample(j) = mp_sample_range(1) + peak_index - 1;
    agg_sample_range = max(1, round((mp_sample(j) - ft_range(j)))): ...
                       min(noise_floor_range(1), ...
                       round((mp_sample(j) + ft_range(j))));
    agg_pow_samples = combine_bed_pow(radar_lo(agg_sample_range, j), ...
                                      radar_hi(agg_sample_range, j), ...
                                      offset);
    agg_pow(j) = sum(agg_pow_samples);
    
    %subtract noise_floor to normalize
    max_pow(j) = max_pow(j) - noise_floor(j);
    agg_pow(j) = agg_pow(j) - noise_floor(j)*length(agg_pow_samples);
end

max_pow = medfilt1(max_pow,5, 'omitnan','truncate');


close all
figure(1); plot(results.rdr_dist, max_pow, 'x')
hold on; plot(results.rdr_dist, results.bed_pow - noise_floor)
% figure(2); plot(results.rdr_dist, mp_lo, 'x')
% hold on; plot(results.rdr_dist, results.bed_pow)
% figure(3); plot(results.rdr_dist, mp_hi, 'x')
% hold on; plot(results.rdr_dist, results.bed_pow)

end

