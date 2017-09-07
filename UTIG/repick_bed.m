function [max_pow_norm_filt, mp_sample, noise_floor, ...
          agg_pow_norm_filt, ft_range, abrupt_filt] = ...
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
hi_lo_offset = compute_hi_lo_offset(results.bed_pow_lo, results.bed_pow_hi);

%initialize results arrays
mp_sample = zeros(L,1); %sample of re-pick
max_pow = zeros(L,1); %dB power of re-pick
agg_pow = zeros(L,1); %aggregated power
agg_pow_norm = zeros(L,1); %normalized aggregate power
channel_num = zeros(L, 1);
noise_floor = zeros(L,1);

%calc repick fast time range based on Fresnel zone (Jordan, Oswald & Gogin)
samples_per_meter = f_sample/c_light/2; %divide by 2 because roundtrip
ft_range = sqrt(pulse_hw*(pick_thick/n_ice + pick_clear))*samples_per_meter;
%calc how many traces to average assuming 100 m/pik

%use hi-gain channel for noise-floor, because when we combine high and low
%gain channels, we use high-gain channel for low-power measurements

% noise_floor_lo = mean(mean(radar_lo(noise_floor_range,:), ...
%                                   'omitnan'), 'omitnan');
noise_floor_hi = mean(mean(radar_lo(noise_floor_range,:), ...
                                  'omitnan'), 'omitnan') - hi_lo_offset;

                              
%for each trace - note: this code could be improved by handling all the NaN
%cases with a few vectorized statements upfront and only iterating over the
%traces where we have adequate info to both with a repick
for j = 1:length(pick_sample)
    %if no valid pick sample, just skip it
    if isnan(pick_sample(j)) || isnan(ft_range(j))
        max_pow(j) = NaN; agg_pow(j) = NaN; mp_sample(j) = NaN;
        channel_num(j) = NaN; noise_floor(j) = NaN;
        agg_pow_norm(j) = NaN;
        continue
    end
        
    %don't allow any picks from below noise floor range because it has a
    %wraparound effect from fft calc
    %rounding because picks at decimal values
    mp_sample_range = max(1, round((pick_sample(j) - ft_range(j)))): ...
                   min(noise_floor_range(1), ...
                       round((pick_sample(j) + 2*ft_range(j))));
    assert( length(mp_sample_range) <= 1 + 3*ceil(ft_range(j)) )
    assert( ~isempty(mp_sample_range) )

    %if all samples from below noise floor range, set values to nan
    
    [mp_lo, mp_id_lo] = max(radar_lo(mp_sample_range, j));
    [mp_hi, mp_id_hi] = max(radar_hi(mp_sample_range, j));
    
    [max_pow(j), channel_num(j)] = ...
            combine_bed_pow(mp_lo, mp_hi, hi_lo_offset);
     
     switch channel_num(j)
         case 1
             mp_sample(j) = mp_sample_range(1) + mp_id_lo - 1;
         case 2
             mp_sample(j) = mp_sample_range(1) + mp_id_hi - 1;
         otherwise
             mp_sample(j) = NaN;
     end
    
    if ~isnan(mp_sample(j)) 
        %find first-return radius around max power 
        agg_sample_range = max(1, round((mp_sample(j) - ft_range(j)))): ...
                           min(noise_floor_range(1), ...
                           round((mp_sample(j) + ft_range(j))));
        assert( length(agg_sample_range) <= 1 + 2*ceil(ft_range(j)) )
        %use combined hi-gain and lo-gain channel to improve snr of
        %off-peak powers
        agg_pow_samples = combine_bed_pow(radar_lo(agg_sample_range,j), ...
                                          radar_hi(agg_sample_range,j), ...
                                          hi_lo_offset);
        agg_pow(j) = sum(agg_pow_samples);
        noise_floor(j) = noise_floor_hi;
        %save normalized agg power because would be annoying to reconstruct
        %how many samples were summed if we did it later
        agg_pow_norm(j) = agg_pow(j) - ...
                            length(agg_sample_range)*noise_floor(j);
    else %if max power not defined, leave agg pow and noisefloor NaN   
        agg_pow(j) = NaN;
        noise_floor(j) = NaN;
        agg_pow_norm(j) = NaN;
    end

end

%use hampel filter to smooth max power and normalize by subtracting noise
%floor
max_pow_filt = hampel(max_pow, 11, 2);
max_pow_norm_filt = max_pow_filt - noise_floor;
%use hampel median filter to smooth aggregate power
agg_pow_norm_filt = hampel(agg_pow_norm, 11, 2);

%calculate abruptness using filtered, normlaized powers
abrupt_filt = max_pow_norm_filt./agg_pow_norm_filt;


end

