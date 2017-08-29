function [trimmed_results] = trim_results_by_pri(results, pri_min, pri_max)
%Trims a results file to contain only a pri range

field_names = fieldnames(results);
result_pri = results.pri;
min_index  = find(result_pri == pri_min);
max_index  = find(result_pri == pri_max);

for i = 1:length(field_names)
    field = results.(field_names{i});
    trimmed_field = field(min_index:max_index);
    trimmed_results.(field_names{i}) = trimmed_field;

end

