function [offset] = compute_hi_lo_offset(bed_pow_lo, bed_pow_hi)
%compute offset between hi and low gain channels.

%Ideally, the inputs correspond to the entire transect or large portion
%thereof. If insufficient data is present, the offset cannot be computed
%and will return NaN

nf_lo_thresh = 60; %dB
sat_thresh = 80; %dB of low-gain where high gain saturates

delta = bed_pow_hi - bed_pow_lo;
offset = mean( delta(bed_pow_lo > nf_lo_thresh & ...
                     bed_pow_lo < sat_thresh), ...
               'omitnan' );
%if inputs are arrays, take another mean to reduce to scalar
if length(offset) > 1
    offset = mean(offset, 'omitnan');
end

end

