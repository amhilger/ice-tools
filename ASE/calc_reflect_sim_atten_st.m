load meanattenuation.mat

results_dir = ...
    '/data/cees/amhilger/BBAS_PIG/slice_results/uncurved_5dBsnr/';
save_dir = results_dir;
transects = [1:18 20:29 31 32];

cd(results_dir)
load sliceIndex.mat

n_ice = 1.78;
c_light = 2.99792e8; %m/s
f_sample = 22e6; %MHz



for i = 1:length(transects)
    disp(' '); disp(['Transect b' num2str(transects(i),'%02i')])
    for j = 1:num_sub_trans(i) %for each sub transect
        disp(['Sub ' num2str(j, '%03i')])
        transect_name = ['b' num2str(transects(i), '%02i') ...
                         '_interp_repick_sub' ...
                         num2str(j, '%03i') '.mat'];
        cd(results_dir)
        load(transect_name)
        cd /data/cees/amhilger/BEDMAP
        [xr,yr] = ll2ps(SRG_results.repick_lat, SRG_results.repick_long);

        %correct power for geometric spreading losses
        delta_t = (SRG_results.repick_sample - ...
                   SRG_results.interp_surf_pick)/(2*f_sample); 
        derived_thick = c_light/n_ice*delta_t;
        geo_correction = 10*log10(2*(SRG_results.repick_clear + ...
                                     derived_thick/n_ice));
        geo_corr_pow = SRG_results.repick_power + geo_correction;

        %interpolate attenuation rate from Helene's data and calculate
        %reflectivity
        disp(['X repick: ' num2str(min(xr)) ' to ' num2str(max(xr))])
        disp(['Y repick: ' num2str(min(yr)) ' to ' num2str(max(yr))])
        disp(['X grid: ' num2str(min(x_m)) ' to ' num2str(max(x_m))])
        disp(['Y grid: ' num2str(min(y_m)) ' to ' num2str(max(y_m))])
        atten = interp2(x_m, y_m, meanattenuation_grid, xr, yr, ...
                        'spline', NaN);
        disp([num2str(length(atten(isnan(atten)))) ' outside domain'])
        reflect = geo_corr_pow + atten.*derived_thick/1000;

        %add calculated variables to structure
        SRG_results.derived_thick = derived_thick;
        SRG_results.geo_power = geo_corr_pow;
        SRG_results.sim_atten = atten;
        SRG_results.reflect_sim_atten = reflect;

        %save structure
        save_name = ['b' num2str(transects(i), '%02i') ...
                      '_sim_atten_results_sub' ...
                      num2str(j, '%03i') '.mat'];
        cd(save_dir)
        save(save_name, 'SRG_results')
    end
end

