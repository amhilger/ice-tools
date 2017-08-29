function [bad_traces] = check_attrib(transect_name, data_dir)

orig_dir = cd(data_dir);
chunk_names_list = dir([transect_name 'attrib*']);
num_chunks = length(chunk_names_list);

bad_velo_array = [];
bad_velo_chunks = [];
pri_reset_array = [];
pri_reset_chunks = [];
pri_jump_index = [];
pri_jump_values = [];
pri_jump_chunks = [];

for i = 1:num_chunks
    chunk_name = chunk_names_list(i).name;
    a = load(chunk_name);
    attrib_array = a.attrib_array;
    bad_velo = find(attrib_array(7,:) < 0);
    bad_velo_array = [bad_velo_array bad_velo];
    bad_velo_chunks = [bad_velo_chunks i*ones(1, length(bad_velo))];
    
    delta_pri = attrib_array(1,2:end) - attrib_array(1, 1:end-1);
    %resets occur when pri decreases between two traces
    %incremented so that pri_reset gives index of first bad trace
    pri_reset = find(delta_pri < 0) + 1;
    pri_reset_array = [pri_reset_array pri_reset];
    pri_reset_chunks = [pri_reset_chunks i*ones(1, length(pri_reset))];
    %jumps occur when pri increases by more than 50 between two traces
    pri_jump = find(delta_pri > 50) + 1;
    pri_jump_values = [pri_jump_values delta_pri(pri_jump-1)];
    pri_jump_index = [pri_jump_index pri_jump];
    pri_jump_chunks = [pri_jump_chunks i*ones(1, length(pri_jump))];
end

if ~isempty(pri_reset_array) && ~isempty(bad_velo_array)
    if min(bad_velo_array) < min(pri_reset_array)
        first_bad_trace = min(bad_velo_array);
        bad_traces.last_good_chunk = min(bad_velo_chunks);
    else
        first_bad_trace = min(pri_reset_array);
        bad_traces.last_good_chunk = min(pri_reset_chunks);
    end
elseif ~isempty(bad_velo_array)
    first_bad_trace = min(bad_velo_array);
    bad_traces.last_good_chunk = min(bad_velo_chunks);
elseif ~isempty(pri_reset_array)
    first_bad_trace = min(pri_reset_array);
    bad_traces.last_good_chunk = min(pri_reset_chunks);
else
    first_bad_trace = [];
    bad_traces.last_good_chunk = num_chunks;
end

last_chunk_name = chunk_names_list(bad_traces.last_good_chunk);
% disp(bad_traces.last_good_chunk)
 % disp(last_chunk_name)
load(last_chunk_name.name)
if ~isempty(first_bad_trace)
    bad_traces.last_good_trace = first_bad_trace - 1;
else
    bad_traces.last_good_trace = size(attrib_array, 2);
end
bad_traces.last_good_pri = attrib_array(1,bad_traces.last_good_trace);

    
    

bad_traces.bad_velo = bad_velo_array;
bad_traces.bad_velo_chunks = bad_velo_chunks;
bad_traces.pri_reset = pri_reset_array;
bad_traces.pri_reset_chunks = pri_reset_chunks;
bad_traces.pri_jump_index = pri_jump_index;
bad_traces.pri_jump_value = pri_jump_values;
bad_traces.pri_jump_chunks = pri_jump_chunks;

cd(orig_dir)

end

