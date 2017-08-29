orig_dir = pwd;
load_dir = [pwd '/piks_lo_hi'];

cd ../tools
transect_names = get_transect_names(load_dir);
survey = combine_results(load_dir, transect_names, '_results.mat', false);
cd ../BBAS_PIG

% nf_lo = zeros(length(transect_names,1));
% nf_hi = zeros(length(transect_names,1));
% sat_lo = zeros(length(transect_names,1));
% sat_hi = zeros(length(transect_names,1));
delt_mu = zeros(length(transect_names),1);
delt_std = zeros(length(transect_names),1);

nf_lo = 60; %dB
sat_lo = 80; %dB

cd(load_dir)
for i = 1:length(transect_names)
    load([transect_names{i} '_results.mat'])
    delta = results.bed_pow_hi - results.bed_pow_lo;
    delt_mu(i) = mean(delta(results.bed_pow_lo < sat_lo & ...
                            results.bed_pow_lo > nf_lo), 'omitnan');
    delt_std(i) = std(delta(results.bed_pow_lo < sat_lo & ...
                            results.bed_pow_lo > nf_lo), 'omitnan');
end

close all
figure; histogram(delt_mu, 20)
figure; histogram(delt_std, 20)

cd(orig_dir)
    
    