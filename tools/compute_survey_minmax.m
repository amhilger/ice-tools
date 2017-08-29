function [survey_min, survey_max] = compute_survey_minmax(results_field, ... 
                                                 load_dir, ...
                                                 transect_names)
%computes the transect mean for a structure, which must be called results

if ~exist('transect_names','var')
    transect_names = get_transects();
end

survey_min = Inf;
survey_max = -Inf;

%switch into results directory
orig_dir = cd(load_dir);

%for each transect
for i = 1:length(transect_names)
    load([transect_names{i} '_results.mat']) %load results structure
    %comparre survey min/max so far to each transect
    if isempty(results.(results_field))
        continue
    end
    survey_min = min(survey_min, min(results.(results_field)));
    survey_max = max(survey_max, max(results.(results_field)));
end

%compute mean and check answer

assert(~isnan(survey_min))
assert(~isnan(survey_max))

%clean-up directory
cd(orig_dir)

end

