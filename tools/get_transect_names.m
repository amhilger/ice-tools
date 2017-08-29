function [out_transects] = get_transect_names(results_dir, starts_with_str)
%returns a list of all the transects starting with X, Y, or DRP (drape),
%where we have the necessary ztim file, position file, clearance file, bed
%pick file, and surface pick file

%%this function is overloaded--if no input is specified, it looks at the
%%original UTIG data directories and finds the transects with complete pik
%%and metadata. This version would be used by the load functions
orig_dir = pwd; 
if ~exist('starts_with_str','var')
    if ~isempty(strfind(results_dir, 'UTIG'))
        starts_with_str = {'X','Y','DRP'};
    elseif ~isempty(strfind(results_dir, 'BBAS_PIG'))
        starts_with_str = {'b'};
    elseif ~isempty(strfind(results_dir, 'ASE'))
        starts_with_str = {'X','Y','DRP','b'}; %
    else
        error(['Unexpected directory: must manually ' ... 
               'specify starting characters of transect'])
    end 
end

disp('Finding transect names starting with: ')
disp(starts_with_str)
%if results_dir is specified, returns a list of
%%all transect names (starting with X, Y, or DRP) in results_dir -- this
%%version should be used when doing further processing on results files
if exist('results_dir', 'var')
    cd(results_dir)
    %return file names starting with starts_with_str
    result_names = filter_dir_contents(results_dir, starts_with_str);
    %find indices of underscores in directory contents
    underscore_index = strfind(result_names,'_');
    %trim file names to characters before first underscore
    out_transects = cellfun(@(str, k) str(1:k(1)-1), ...
                            result_names, underscore_index, ...
                            'UniformOutput', false);
    cd(orig_dir); return
end

%if no results_dir is specified, look at the raw data files 

%%this implementation is quicky and dirty - it only takes the intersection
%%of the transects listed in the PIK, CMP, and FOC/.../S1_POS directories.
%%A more thorough implementation would check for the existence of the ztim
%%in CMP, ztim_DNhH and ztim_xyhd in S1_POS, and MagLoResInco1.srf and .bed
%%in PIK.



top_dir = '/data/schroeder/Andrew_ASE/targ/ASE1/';
pik_dir = 'PIK/ase1/THW/SJB2/';
cmp_dir = 'CMP/pik1/THW/SJB2/';
foc_dir = 'FOC/MEP_Development/S1_POS/THW/SJB2/';


pik_transects = filter_dir_contents([top_dir pik_dir], starts_with_str);
cmp_transects = filter_dir_contents([top_dir cmp_dir], starts_with_str);
foc_transects = filter_dir_contents([top_dir foc_dir], starts_with_str);

out_transects = intersect(pik_transects, ...
                intersect(cmp_transects, ...
                          foc_transects));
                      
cd(orig_dir)
 
end

function filtered_contents = filter_dir_contents(directory, ...
                                                 starts_with_str)
%Returns folders in directory that start with one of the strings in
%start_with_str
cd(directory)
load_dir_contents = dir;

filtered_contents = cell(length(load_dir_contents), 1);
out_index = 1;

for i = 1:length(load_dir_contents)
    file_name = load_dir_contents(i).name;
    str_index = cell2mat(regexp(file_name, starts_with_str));
    if ~isempty(str_index((str_index == 1)))
        filtered_contents{out_index} = file_name;
        out_index = out_index + 1;
    end
end
empty_cells = cellfun('isempty',filtered_contents);
filtered_contents = filtered_contents(~empty_cells);

end