results_dir = '/data/cees/amhilger/BBAS_PIG/results';
save_dir = '/data/cees/amhilger/BBAS_PIG/results_aligned';
radar_dir = '/data/cees/amhilger/BBAS_PIG/SAR_processed_aligned';


for i = [18]%18 is incomplete [1:18 20:29 31 32]
    transect_name = ['b' num2str(i, '%02i')];
    disp(['Repicking ' transect_name]) 
    repick_results(transect_name, results_dir, save_dir, radar_dir);
end
