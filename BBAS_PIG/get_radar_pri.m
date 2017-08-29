function [sar_out] = get_radar_pri(transect_name, min_pri, max_pri, data_dir)
%%retrieves sar data corresponding to pri range


%find chunk and trace corresponding to min and max pri
[min_chunk, min_trace] = pri_to_chunk(transect_name, min_pri);
[max_chunk, max_trace] = pri_to_chunk(transect_name, max_pri);

%change to directory containing processed SAR data
if ~exist('data_dir', 'var')
    data_dir = '/data/cees/amhilger/BBAS_PIG/SAR_processed_aligned';
    disp(['Warning: data directory not specified. Using ' data_dir])
end

orig_dir = cd(data_dir); 


if min_chunk == max_chunk %retrieving a single chunk
    chunk_name = [transect_name 'radarChunk' ...
                  num2str(min_chunk, '%03i') '.mat'];
    radar_struct = load(chunk_name);
    radar_chunk = radar_struct.SAR_out;          
    sar_out = radar_chunk(:, min_trace:max_trace);
    
else %retrieving multiple chunks
    %number of full chunks to retrieve
    full_chunks = max_chunk - min_chunk - 1;
    %number of traces in first chunk
    first_chunk_traces = 25000 - min_trace + 1;

    sar_out = zeros(1250, full_chunks*25000 + first_chunk_traces + max_trace);
    for i = 1 : 2+full_chunks
        chunk_name = [transect_name 'radarChunk' ...
                    num2str(min_chunk+i-1, '%03i') '.mat'];
        radar_struct = load(chunk_name);
        radar_chunk = radar_struct.SAR_out;
        if i == 1
            sar_out(:, 1 : first_chunk_traces) = ...
                radar_chunk(:, min_trace : end);
        elseif i == 2+full_chunks
            sar_out(:, end - max_trace + 1 : end) = ...
                radar_chunk(:, 1 : max_trace);
        else
            first_index = first_chunk_traces + 1 + 25000*(i-2);
            last_index = first_index + size(radar_chunk, 2) - 1;
            sar_out(:, first_index : last_index) = radar_chunk;
        end
    end
end

cd(orig_dir)