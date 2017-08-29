function [] = read_bin_data(bin_file, bin_dir, save_dir, n_samples)
%parses and saves a binary file

orig_dir = cd(bin_dir);
transect_name = bin_file(1:3);


batch_size = 25000; %number of traces per batch

file_id = fopen(bin_file, 'rb');
chunk_num = 1;

while ~feof(file_id)
    raw_data = fread(file_id, [2*n_samples, batch_size], 'float32');
    real_data = raw_data(1 : n_samples, :);
    imag_data = raw_data(n_samples+1 : end, :);
    chunk_data = complex(real_data, imag_data);
    chunk_name = [transect_name 'dataChunk' num2str(chunk_num, '%03i') '.mat'];
    disp(['Saving ' chunk_name])
    cd(save_dir)
    save(chunk_name, 'chunk_data')
    cd(bin_dir)
    chunk_num = chunk_num + 1;
end

fclose(file_id);

cd(orig_dir)



end

