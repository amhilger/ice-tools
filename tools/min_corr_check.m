function [C_0] = ...
    min_corr_check(bed_power, ice_thick, rdr_clear)
%
%%Outputs the correlation between thickness and geometrically corrected bed
%%power, ie for an attenuation correction of zero. This is a lightweight
%%version of bed_power_correct used to quickly iterate through pick
%%segments that are so short that the noise overwhelms the overall signal.

% geometrically corrected bed power
bed_pow_geo = geo_correct_power(bed_power, rdr_clear, ice_thick);

% corrected attenuation rate
C = corrcoef(bed_pow_geo, ice_thick);  %2x2 correlation coeff matrix
C_0 = abs(C(1,2)); %use the cross-correlation coefficient






end

