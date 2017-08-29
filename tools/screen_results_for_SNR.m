function [] = screen_results_for_SNR(transect_name, SNR_threshold, ...
                                     load_dir, save_dir, isInterp)
%loads results file and removes entries with SNR less than SNR_threshold 

assert(~strcmp(load_dir, save_dir)) %load_dir ~= save_dir

%load repick_results
orig_dir = cd(load_dir);
if isInterp
    repick_name = [transect_name '_SRG_interp_repick.mat'];
else
    repick_name = [transect_name '_SRG_repick.mat'];
end    
load(repick_name)


noise_floor = SRG_results.noise_floor;
bed_power = SRG_results.repick_power;
SNR = bed_power - noise_floor;
good_picks = find(SNR >= SNR_threshold);

fields = fieldnames(SRG_results);

for i = 1:length(fields)
    if length(SRG_results.(fields{i})) == length(SNR)
        SRG_results.(fields{i}) = SRG_results.(fields{i})(good_picks);
    end
end

disp([transect_name ' initial length: ' num2str(length(SNR))])
disp(sprintf([num2str(SNR_threshold) ' dB SNR screen filters to length ' ...
      num2str(length(good_picks)) '\n']))

cd(save_dir);
if isInterp
    save_name = [transect_name '_SRG_interp_repick.mat'];
else
    save_name = [transect_name '_SRG_repick.mat'];
end  

save(save_name, 'SRG_results')
cd(orig_dir)


end