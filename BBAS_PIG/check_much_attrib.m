data_dir = '/data/cees/amhilger/BBAS_PIG/rawIndotM';
close all

transect_nums = [1:18 20:29 31 32];

bad_traces = struct([]);


for i = 1:length(transect_nums)
    transect_name = ['b' num2str(transect_nums(i), '%02i')];
    disp(['Checking velo and pri of ' transect_name]) 
    transect_bad_traces = check_attrib(transect_name, data_dir);
    transect_bad_traces.transect_name = transect_name;
    bad_traces = [bad_traces; transect_bad_traces];
end

save('bad_attrib_traces.mat','bad_traces')

cd(data_dir)

for i = 1:length(transect_nums)
    reset_pris = bad_traces(i).pri_reset;
    reset_chunks = bad_traces(i).pri_reset_chunks;
    for j = 1:length(reset_chunks)
        chunk_name = ['b' num2str(transect_nums(i), '%02i') ...
            'attribChunk' num2str(reset_chunks(j), '%03i') '.mat'];
        disp(chunk_name)
        cd /data/cees/amhilger/BBAS_PIG/rawIndotM/
        a = load(chunk_name);
        attrib_array = a.attrib_array;
        neg_velo = find(attrib_array(7,:) < 0);
        disp('Negative Velocity trace range within chunk')
        disp(min(neg_velo))
        disp(max(neg_velo))
        
        neg_velo_lats = [attrib_array(2, neg_velo)];
        neg_velo_longs = [attrib_array(2, neg_velo)];
        cd /data/cees/amhilger/BEDMAP
        neg_velo_dist = pathdistps(neg_velo_lats, neg_velo_longs);
        disp(['Distance (km) spanned by negative velocities: ' ...
            num2str(max(neg_velo_dist)/1000) ])
    end
end

cd /data/cees/amhilger/BBAS_PIG/