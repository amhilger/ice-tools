function [results] = ...
    filter_fit_quality(results, Cmin_thresh, C0_thresh, atten_unc_thresh)
%Filters by enforcing maximum Cmin and attenuation uncertainty, as well as
%maximum initial correlation C0

failed_Cmin = find(results.C_min > Cmin_thresh);
failed_att_unc = find(results.atten_unc > atten_unc_thresh);
failed_C0 = find(results.C_0 < C0_thresh);

failed_all = union(failed_Cmin, union(failed_att_unc, failed_C0));


results.reflect(failed_all) = NaN;
results.atten_rate(failed_all) = NaN;

end

