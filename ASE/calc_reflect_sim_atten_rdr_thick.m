function [reflect, atten] = ...
    calc_reflect_sim_atten_rdr_thick(easts, norths, ice_thick, geo_power) 
%interpolate attenuation rate from Helene's data and calculate
%reflectivity
load meanattenuation.mat

atten = interp2(x_m, y_m, meanattenuation_grid, easts, norths, ...
                'spline', NaN);
atten(atten < 0) = NaN;
disp([num2str(length(atten(isnan(atten)))) ' outside domain'])
reflect = geo_power + 2*atten.*ice_thick/1000;