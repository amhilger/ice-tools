% this verifies that the meanattenuation_grid is an average attenuation
% rate in dB/km, and that attenuation_grid is the total attenuation in dB.
% By itself, it doesn't solve the 1-way vs 2-way question.
orig_dir = cd('/data/cees/amhilger/BBAS_PIG');


load attenuation.mat
load meanattenuation.mat

attenuation_grid(attenuation_grid < 0) = NaN;
meanattenuation_grid(meanattenuation_grid < 0) = NaN;

cd ../BEDMAP
[bmx, bmy, bmthick] = ...
    bedmap2_data('thick', x_m, y_m,'xy');
[X_M, Y_M] = meshgrid(x_m, y_m);
bm_interp_thick = interp2(bmx, bmy, bmthick, ...
                          X_M, Y_M, 'linear');
resid = attenuation_grid - 2*meanattenuation_grid.*bm_interp_thick/1000;
figure; histogram(resid(:))





cd(orig_dir)

