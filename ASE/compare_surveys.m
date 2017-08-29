orig_dir = pwd;
cd ../; data_dirA = [pwd '/UTIG/xover_lo_hi_filtered'];
data_dirB = [pwd '/BBAS_PIG/xover_filtered_5dBsnr'];
cd ./tools

starts_with_strA = {'X','Y','DRP'};
starts_with_strB = {'b'};

tr_namesA = get_transect_names(data_dirA, starts_with_strA);
tr_namesB = get_transect_names(data_dirB, starts_with_strB);

for i = 