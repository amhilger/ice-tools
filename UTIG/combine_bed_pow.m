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
end

%when there are no lo-gain points above the noisefloor, we can't compute an
%offset, so we'll just discard the data from this transect
if isnan(offset)
    disp('Warning: insufficient lo-gain data with sufficient SNR')
    disp('Assuming offset of 19 dB - xover will determine correct offset')
    offset = 19; %dB
end



%when we hit the low-gain noise threshold, use the high-gain minus the
%offset
bed_pow(bed_pow_lo < nf_lo_thresh) = ...
    bed_pow_hi(bed_pow_lo < nf_lo_thresh) - offset;

%record the channel number used for the output bed power, 1 correpsonds to
%lo-gain, 2 corresponds to hi-gain
channel_num = 1 + (bed_pow_lo < nf_lo_thresh);

%throw out saturated points
bed_pow(bed_pow > sat_thresh) = NaN;
channel_num(bed_pow > sat_thresh) = NaN;


end

