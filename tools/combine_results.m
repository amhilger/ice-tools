function [survey] = combine_results(results_dir, transect_names, ...
                                    results_name, doClean)
%outputs a structure survey containing all the fields of the input results
orig_dir = pwd;

%if doClean is enabled

if ~exist('doClean','var')
    doClean = 1;
end


save_index = 1;
for i = 1:length(transect_names)
    cd(results_dir)
    load([transect_names{i} results_name])
%     if isfield(results,'fit_segment_index')
%         results = rmfield(results, 'fit_segment_index')
%     end
    cd(orig_dir)
    if doClean
        results = standardize_fields(results);
        results = fill_in_fields(results);
	if ~isempty(strfind(results_dir, 'ASE'))
            results = ase_preprocess(results);
        end
    end
     
    if i == 1
        survey = structfun(@(fld) zeros(size(fld, 1)*2*length(transect_names), ...
                                        size(fld, 2)), results, ...
                                        'UniformOutput', false);
        fld_nms = fieldnames(survey); %field names except transect index
        survey.ts_idx = zeros(size(results.rdr_clear, 1)*2*length(transect_names), 1);

    end
    L = length(results.rdr_clear);
    for j = 1:length(fld_nms)
        survey.(fld_nms{j})(save_index:save_index+L-1) = results.(fld_nms{j});
    end
    survey.ts_idx(save_index:save_index+L-1) = i*ones(L,1);
    save_index = save_index + L;
end

%remove extraneous zeros
survey = structfun(@(fld) fld(1:save_index-1), survey, ...
                   'UniformOutput', false);
cd(orig_dir)
