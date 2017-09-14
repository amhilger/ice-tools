
results_dir = [pwd '/results_aligned_5dBsnr'];
save_dir = [pwd '/agg_repick_noMA'];
orig_dir = cd(save_dir); cd(orig_dir)
radar_dir = [pwd '/SAR_processed_aligned'];

cd ../tools
transect_names = get_transect_names(results_dir);
cd(orig_dir)

for i = 1:length(transect_names)
    repick_results_agg_noMA(transect_names{i}, results_dir, save_dir, radar_dir); 
end
