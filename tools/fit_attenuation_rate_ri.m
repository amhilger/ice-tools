function [reflect, atten_rate, atten_unc, C_min, C_0] = ...
    fit_attenuation_rate_ri(bed_pow_geo, ice_thick, C_hw, ts_idx)
%%%WARNING: function modified so that C_0 returns negative when the ice
%%%thickness and geometric power are anti-correlated (as they should be)


%%Outputs attenuation rate and corrected bed power based on the calculated
%%atttenuation rate. The bed power is corrected for both geometric
%%spreading and the derived ice attenuation rate. All powers are assumed to
%%be in dB scale.

%%called by adaptive_bed_power.m

%intercept matrix - should have one-hot rows indicating which transect it
%is part of
int_mat = full(ind2vec(ts_idx')');
%b_ind keeps track of which columns are non-zero (ie which transects are
%represented)
b_ind = find(any(int_mat == 1, 1));
any_col_removed = (length(b_ind) ~= size(int_mat,2));

if any_col_removed
%remove the columns that are all zeros - we do this to avoid rank deficient
%regressions
    int_mat = int_mat(:, any(int_mat == 1));
    %ts_edges used to perform inverse value -> index lookup so we can lookup
    %the right intercepts later
    ts_edges = [-Inf 0.5*(b_ind(1:end-1)+b_ind(2:end)) Inf];
end


%correlation between geometrically corrected bed power and ice thickness
C_0 = corr(bed_pow_geo, ice_thick);




%calculate the attenuation rate with a regression
b = regress(bed_pow_geo, [ice_thick int_mat]);
atten_rate = abs(0.5*b(1)); %first entry in b is slope (others are intercepts)

%calc reflectivity and corresponding fit quality C_min
reflect = bed_pow_geo + 2*atten_rate*ice_thick;
%subtract intercepts so that reflect_ri only reflect quality of slope fit
%discretize is used to quickly do inverse lookup from the transect index to
%the inde of the intercept, with the +1 offset skipping the slope in the
%first entry of b
if any_col_removed
    reflect_ri = reflect - b(discretize(ts_idx,ts_edges) + 1);
else %no need to do lookup because no columns removed
    reflect_ri = reflect - b(ts_idx+1);
end
%verify that regression worked
C_min = abs(corr(reflect_ri, ice_thick));


if ~exist('C_hw','var') 
    %if no threshold specified, use uncertainty in slope calculated by
    %regress function
    [~, bint] = regress(bed_pow_geo, [ice_thick int_mat]);
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
%approximation of the correlation coefficient around the C_min value. We
%calculate correlation for reflectivity with 110% attenuation rate and then
%use this to calculate a linear fit of the trend around C_min. We then
%determine the attenuation rate corresponding to the desired C_hw. This is
%repeated for 90% attenuation rate, and the resulting attenuation rates are
%used to calculate the half-width uncertainty in the attenuation rate
atten_hw = zeros(2,1);
for i = -1:2:1 %for i = 1 and i = -1 (ie low and high)
    %calculate reflectivities with 90% and 10% atten rates
    reflect_unc = bed_pow_geo + 2*(1+i*0.1)*atten_rate*ice_thick;
    if any_col_removed
        reflect_unc_ri = reflect_unc - b(discretize(ts_idx,ts_edges) + 1);
    else %then we can use natural indexing because no columns removed
        reflect_unc_ri = reflect_unc - b(ts_idx + 1);
    end
    %C_unc corresponds to the 90% or 110% atten_rate
    C_unc = abs(corr(reflect_unc_ri, ice_thick));
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

if C_0 > 0.8
    keyboard
end

%disp(['Atten = ' num2str(atten_rate) ' +/- ' num2str(atten_unc)]) 

end

