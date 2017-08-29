function [transect_mean] = compute_survey_mean(results_field, ... 
                                                 load_dir, ...
                                                 transect_names)
%computes the transect mean for a structure, which must be called results

if ~exist('transect_names','var')
    transect_names = get_transects();
end

running_sum = 0;
running_count = 0;

%switch into results directory
orig_dir = cd(load_dir);

%for each transect
for i = 1:length(transect_names)
    load([transect_names{i} '_results.mat']) %load results structure
    %increment by number of non-NaN entries in field
    running_count = running_count + ...
                    length(find(~isnan(results.(results_field))));
    %increment by sum of non-NaN entries in field (zero if all NaN)
    running_sum   = running_sum + ...
                    nansum(results.(results_field));
end

%compute mean and check answer
transect_mean = running_sum/running_count;
assert(~isnan(transect_mean))

%clean-up directory
cd(orig_dir)

end

