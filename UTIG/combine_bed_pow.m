function [bed_pow, channel_num] = ...
    combine_bed_pow(bed_pow_lo, bed_pow_hi, offset)
%combines hi-gain and lo-gain channels for a transect. Computes a
%transect-specific offset 

assert(length(bed_pow_lo) == length(bed_pow_hi))
sat_thresh = 96; %dB we don't trust anything above this
nf_lo_thresh = 60; %dB

%use low-gain by default
bed_pow = bed_pow_lo;

%calculate the offset from the difference when low-gain is between the
%noisefloor and saturation thresholds
if ~exist('offset','var')
    offset = compute_hi_lo_offset(bed_pow_lo, bed_pow_hi);
    assert(~isnan(offset))
end

%when we hit the low-gain noise threshold, use the high-gain minus the
%offset
bed_pow(bed_pow_lo < nf_lo_thresh) = ...
    bed_pow_hi(bed_pow_lo < nf_lo_thresh) - offset;

channel_num = 1 + (bed_pow_lo < nf_lo_thresh);

%throw out saturated points
bed_pow(bed_pow > sat_thresh) = NaN;
channel_num(bed_pow > sat_thresh) = NaN;


end

