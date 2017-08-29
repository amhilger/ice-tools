function [reflect, atten, reflect_unc] = ...
    calc_reflect_sim_atten_bm_thick(easts, norths, geo_power) 
%interpolate attenuation rate from Helene's data and calculate
%reflectivity as well as uncertainty in reflectivity

%in contrast to calc_reflect_sim_atten, this uses thicknesses from BEDMAP
%as well as their associated uncertainties to derive 
load meanattenuation.mat

meanattenuation_grid(meanattenuation_grid < 0) = NaN;
%interpolate attenuation rates along the transect from the grid
atten = interp2(x_m, y_m, meanattenuation_grid, easts, norths, ...
                'linear', NaN);
%set the negative attenuation rates (from outside the domain) to NaN;
%before this step, they are set to -99
atten(atten < 0) = NaN;
disp([num2str(length(atten(isnan(atten)))) ' outside domain'])

cd /data/cees/amhilger/tools

bmi_thick = bedmap_thick(easts, norths);

cd ../BEDMAP
%get the gridded uncertainty in the bed height -- this uncertainty term will tend
%to dominate the uncertainty in the surface height
[bmx, bmy, bmunc] = ...
    bedmap2_data('beduncertainty', easts,norths,'xy');
%interpolate the along-transect bed uncertainty 
bmi_unc = interp2(bmx, bmy, bmunc, ...
                  easts, norths, 'linear');

%calculate reflectivity using the one-way attenuation, converting the
%ice thickness from meters to km
reflect = geo_power + 2*atten.*bmi_thick/1000;

%23m surface uncertainty in West Antarctica, per Fretwell 2013 BEDMAP2
reflect_unc = hypot(23,bmi_unc)*2.*atten/1000;
%add bed and surface uncertainties in quadrature and amplify by attenuation
%rate

%%more ideally we'd have an attenuation rate uncertainty to combine with
%%these as well (adding % errors in quadrature b/c multiplication). 