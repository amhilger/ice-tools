function [reflect, atten_rate, atten_unc, C_min, C_0] = ...
    fit_attenuation_rate_robust(bed_power, ice_thick, rdr_clear)


%%Outputs attenuation rate and corrected bed power based on the calculated
%%atttenuation rate. The bed power is corrected for both geometric
%%spreading and the derived ice attenuation rate. All powers are assumed to
%%be in dB scale.

%this version uses robust regression (like a huber penalty function, which
%suppresses the effects of outliers)

%%the only trouble with this version is that it's hard to compare fit
%%quality with the LS version. The quality metrics developed for LS version
%%don't make sense here, because the correlation coefficient is an
%%inherently LS type metric

%%called by adaptive_bed_power.m


% geometrically corrected bed power
bed_pow_geo = geo_correct_power(bed_power, rdr_clear, ice_thick);

%correlation between geometrically corrected bed power and ice thickness
C_0 = corrcoef(bed_pow_geo, ice_thick);
C_0 = abs(C_0(1,2));

%calculate the attenuation rate with a regression
[b, stats] = robustfit(ice_thick, bed_pow_geo, 'huber');
atten_rate = abs(0.5*b(2)); %second entry in b is slope (first is intercept)

%calc reflectivity and corresponding fit quality C_min
reflect = bed_pow_geo + 2*atten_rate*ice_thick;
C_min = corrcoef(reflect, ice_thick);
C_min = abs(C_min(1,2));

%if fit is terrible, don't bother calculating uncertainty
if C_min > C_hw
    atten_unc = NaN;
    return
end

%use standard error estimated for slope coefficient for attenuation
%uncertainty. This corresponds to 95% confidence interval
atten_unc = stats.se(2);

end

