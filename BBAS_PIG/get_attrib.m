function [attrib_struct] = get_attrib(transect_name, min_pri, max_pri)
%%retrieves attribute array corresponding to pri range

[min_chunk, min_trace] = pri_to_chunk(transect_name, min_pri);
[max_chunk, max_trace] = pri_to_chunk(transect_name, max_pri);

%number of full chunks to retrieve
full_chunks = max_chunk - min_chunk - 1;
%number of traces in first chunk
first_chunk_traces = 25000 - min_trace + 1;



orig_dir = cd('./rawIndotM');                     


attrib_array = zeros(11, full_chunks*25000 + first_chunk_traces + max_trace);
for i = 1 : 2+full_chunks
    chunk_name = [transect_name 'attribChunk' ...
                num2str(min_chunk+i-1, '%03i') '.mat'];
    attrib = load(chunk_name);
    attrib_chunk = attrib.attrib_array;
    if i == 1
        attrib_array(:, 1 : first_chunk_traces) = ...
            attrib_chunk(:, min_trace : end);
    elseif i == 2+full_chunks
        attrib_array(:, end - max_trace + 1 : end) = ...
            attrib_chunk(:, 1 : max_trace);
    else
        first_index = first_chunk_traces + 1 + 25000*(i-2);
        last_index = first_index + size(attrib_chunk, 2) - 1;
        attrib_array(:, first_index : last_index) = attrib_chunk;
    end
end

cd(orig_dir)
attrib_struct = attrib_array_to_struct(attrib_array);

