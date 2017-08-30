function [bed_pow] = combine_bed_pow(bed_pow_lo, bed_pow_hi)
%combines hi-gain and lo-gain channels for a transect. Computes a
%transect-specific offset 

assert(length(bed_pow_lo) == length(bed_pow_hi))

nf_lo_thresh = 60; %dB
sat_thresh = 80; %dB of low-gain where high gain saturates

%use low-gain by default
bed_pow = bed_pow_lo;

%calculate the offset from the difference when low-gain is between the
%noisefloor and saturation thresholds
delta = bed_pow_hi - bed_pow_lo;
offset = mean( delta(bed_pow_lo > nf_lo_thresh & ...
                     bed_pow_lo < sat_thresh), ...
               'omitnan');

%when we hit the low-gain noise threshold, use the high-gain minus the
%offset
bed_pow(bed_pow_lo < nf_lo_thresh) = ...
    bed_pow_hi(bed_pow_lo < nf_lo_thresh) - offset;



end

