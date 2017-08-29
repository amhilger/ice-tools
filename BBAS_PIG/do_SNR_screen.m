load_dir = '/data/cees/amhilger/BBAS_PIG/results_aligned';
save_dir = '/data/cees/amhilger/BBAS_PIG/results_aligned_5dBsnr';



for i = [1:18 20:29 31 32]
    transect_name = ['b' num2str(i, '%02i')];
    isInterp = 0;
    SNR_threshold = 5;
    screen_results_for_SNR(transect_name, SNR_threshold, ...
                           load_dir, save_dir, isInterp);
    
end
