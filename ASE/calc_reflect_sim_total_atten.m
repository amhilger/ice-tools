function [reflect, total_atten] = ...
    calc_reflect_sim_total_atten(easts, norths, geo_power) 
%interpolate attenuation rate from Helene's data and calculate
%reflectivity as well as uncertainty in reflectivity

%in contrast to calc_reflect_sim_atten, this uses thicknesses from BEDMAP
%as well as their associated uncertainties to derive 
load attenuation.mat

attenuation_grid(attenuation_grid < 0) = NaN;
%interpolate attenuation rates along the transect from the grid
total_atten = interp2(x_m, y_m, attenuation_grid, easts, norths, ...
                'linear', NaN);
%set the negative attenuation rates (from outside the domain) to NaN;
%before this step, they are set to -99
total_atten(total_atten < 0) = NaN;
disp([num2str(length(total_atten(isnan(total_atten)))) ' outside domain'])





%calculate reflectivity using the total two-way attenuationcd
reflect = geo_power + total_atten;

 