function [transect_median] = compute_survey_median(results_field, ... 
                                                 load_dir, ...
                                                 transect_names)
%computes the transect median for transects located in load_dir having
%names given by transect_names. results_field is a string specifying the
%field name in the results structure for each transect

if ~exist('transect_names','var')
    transect_names = get_transect_names(load_dir);
end

%switch into results directory
orig_dir = cd(load_dir);

all_entries = cell(length(transect_names),1);

%for each transect
for i = 1:length(transect_names)
    load([transect_names{i} '_results.mat']) %load results structure
    %increment by number of non-NaN entries in field
    all_entries{i} = results.(results_field);
end

transect_median = median(cell2mat(all_entries),'omitnan');

%compute mean and check answer
assert(~isnan(transect_median))

%clean-up directory
cd(orig_dir)

end

