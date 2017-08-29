function [reflect, atten_rate, atten_unc, C_min, C_0] = ...
    fit_attenuation_rate(bed_pow_geo, ice_thick, C_hw)
%%%WARNING: function modified so that C_0 returns negative when the ice
%%%thickness and geometric power are anti-correlated (as they should be)


%%Outputs attenuation rate and corrected bed power based on the calculated
%%atttenuation rate. The bed power is corrected for both geometric
%%spreading and the derived ice attenuation rate. All powers are assumed to
%%be in dB scale.

%%called by adaptive_bed_power.m





%correlation between geometrically corrected bed power and ice thickness
C_0 = corr(bed_pow_geo, ice_thick);


%calculate the attenuation rate with a regression
[b, bint] = regress(bed_pow_geo, [ones(size(ice_thick)) ice_thick]);
atten_rate = abs(0.5*b(2)); %second entry in b is slope (first is intercept)

%calc reflectivity and corresponding fit quality C_min
reflect = bed_pow_geo + 2*atten_rate*ice_thick;
C_min = abs(corr(reflect, ice_thick));


if ~exist('C_hw','var') 
    %if no threshold specified, use uncertainty in slope calculated by
    %regress function
    atten_unc = abs(bint(2,1) - bint(2,2))/2;
   %disp(['Atten = ' num2str(atten_rate) ' +/- ' num2str(atten_unc)]) 
    return
end

%if fit is terrible, don't bother calculating uncertainty
% if C_min > C_hw
%     atten_unc = NaN;
%     return
% end

%if fit isn't terrrible, calculate the uncertainty. We use a linear
%approximation of the correlation coefficiet around the C_min value. We
%calculate correlation for reflectivity with 110% attenuation rate and then
%use this to calculate a linear fit of the trend around C_min. We then
%determine the attenuation rate corresponding to the desired C_hw. This is
%repeated for 90% attenuation rate, and the resulting attenuation rates are
%used to calculate the half-width uncertainty in the attenuation rate
atten_hw = zeros(2,1);
for i = -1:2:1 %for i = 1 and i = -1 (ie low and high)
    %calculate reflectivities with 90% and 10% atten rates
    reflect_unc = bed_pow_geo + 2*(1+i*0.1)*atten_rate*ice_thick;
    %C_unc corresponds to the 90% or 110% atten_rate
    C_unc = abs(corr(reflect_unc, ice_thick));
    %interpolate/extrapolate atten_hw by finding C_hw on line between C_min
    %and C_unc
    atten_hw((i+3)/2) = i*0.1*atten_rate*(C_hw-C_min)/(C_unc-C_min) + atten_rate;
end
if atten_hw(1) < 0 %if the lower atten_hw is negative
    %use only the upper one
    atten_unc = abs(atten_hw(2) - atten_rate);
else
    %Increasing uncertainty by 10% to match original method (discrepancy
    %caused by curvature of actual C(atten) function.
    atten_unc = abs(atten_hw(2) - atten_hw(1))/2*1.1;
end

%disp(['Atten = ' num2str(atten_rate) ' +/- ' num2str(atten_unc)]) 

end

