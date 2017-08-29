function [results] = rm_adapt_fields(results)
%assumes input has standardized names

rm_fields = {'atten_rate', 'atten_unc', 'reflectivity', 'reflect', ...
             'C_0', 'C_min', 'fit_distance','geo_pow', ...
             'fit_segment_index','fit_rate'};

for i = 1:length(rm_fields)
    if isfield(results, rm_fields{i})
        results = rmfield(results, rm_fields{i});
    end
end




end

