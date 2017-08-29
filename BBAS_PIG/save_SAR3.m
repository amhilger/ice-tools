function [] = save_SAR3(transect_name, data_dir, out_dir, num_chunks_man)
%does SAR processing for each radar chunk. Assumes attributes chunks, data
%chunks, and pri index files are in the same directory data_dir. The
%processed files are saved to the directory out_dir. 

orig_dir = cd(data_dir);
if ~exist('num_chunks_man', 'var')
    index_name = [transect_name 'priIndex.mat'];
    index = load(index_name);
    index = index.priIndex; 
    num_chunks = length(index);
else
    num_chunks = num_chunks_man;
end
N = 70; %number of coherent summations
M = 280; %number of incoherent averages 

for i = 1:num_chunks
    if i == 1
        chunk_name = [transect_name 'dataChunk' num2str(i, '%03i') '.mat'];
        struct = load(chunk_name);
        if isfield(struct, 'chunk_data')
            chunk_data = struct.chunk_data;
        else
            chunk_data = struct.chunk_val;
        end
    else %if not processing first chunk, set current chunk to next chunk
         %loaded in previous iteration
        chunk_data = next_chunk_data;
    end
    if i ~= num_chunks %if not processing last chunk, load next chunk
        next_chunk_name = ...
            [transect_name 'dataChunk' num2str(i+1, '%03i') '.mat'];
        next_struct = load(next_chunk_name);
        if isfield(next_struct, 'chunk_data')
            next_chunk_data = next_struct.chunk_data;
        else
            next_chunk_data = next_struct.chunk_val;
        end
    end
    cd(orig_dir)
    %calculate main chunk of results
    [~, ~, SAR_out] = ...
        unfocusedSAR3(chunk_data, N, M);
    if i ~= num_chunks %if not last chunk
        %calculate result for last N+M traces of current chunk by
        %processing with first N+M traces of next chunk
        inter_chunk = [chunk_data( : , end-N-M+1 : end ), ...
                       next_chunk_data( :, 1 : N+M )];
        %the below line discards the pulse compressed and coherently
        %summed radargrams. only the incoherently averaged portion is
        %saved.
        [~, ~, inter_SAR_out] = ...  
            unfocusedSAR3(inter_chunk, N, M);
        %modify the left hand side of the above equation to save the
        %desired radar processing output
        SAR_out = [SAR_out inter_SAR_out];
    end
    
    cd(out_dir)
    save_name = [transect_name 'radarChunk' num2str(i, '%03i') '.mat'];
    disp(['Saving ' save_name])
    save(save_name, 'SAR_out')
    cd(data_dir)
end

cd(orig_dir)

