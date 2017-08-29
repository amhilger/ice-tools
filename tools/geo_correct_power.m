function [geo_pow] = geo_correct_power(bed_power, rdr_clear, ice_thick)
%
n_ice = 1.782; %index of refraction for ice

%require positive ice thicknesses and clearances among non-nan entries
assert(all(rdr_clear(~isnan(rdr_clear)) >= 0))
assert(all(ice_thick(~isnan(ice_thick)) >= 0))

% geometrically corrected bed power
geo_pow = bed_power + 20*log10(rdr_clear + ice_thick/n_ice);

end

