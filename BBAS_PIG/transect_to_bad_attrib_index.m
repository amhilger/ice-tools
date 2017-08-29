function [bad_traces_index] = transect_to_bad_attrib_index(transect_name)
%This is a crappy hardcoded function to translate transect name to index in
%the bad_traces file. It should be replaced by a function that finds the
%string transect_name in the bad_traces structure.


transect_num = str2num(transect_name(2:3));
bad_traces_toc = [1:18 20:29 31 32]; %table of contents for bad traces file
bad_traces_index = find(bad_traces_toc == transect_num);

if isempty(bad_traces_index)
    error('Transect name not found in bad_attrib file, so max valid pri of attrib files cannot be determined')
end

end

