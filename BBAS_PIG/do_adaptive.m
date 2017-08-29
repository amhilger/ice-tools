function do_adaptive(transect_num)

results_dir = '/data/cees/amhilger/BBAS_PIG/results_interp';
save_dir    = '/data/cees/amhilger/BBAS_PIG/results_interp/adapt_tight_atten';


transect_name = ['b' num2str(transect_num, '%02i')];
disp(['Fitting attenuation rates for ' transect_name])
adaptive_bed_power(transect_name, results_dir, save_dir);

end

       

