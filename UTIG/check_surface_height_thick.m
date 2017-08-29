close all
orig_dir = cd('/data/cees/amhilger/UTIG/sim_atten');
%transect_names = get_transects();

load('X09a_results.mat')


cd /data/cees/amhilger/BEDMAP/
[bmx, bmy, bmsurf] = ...
    bedmap2_data('surfacew',results.easts,results.norths,'xy');
bm_interp_surf = interp2(bmx,bmy,bmsurf, ...
                         results.easts,results.norths, 'spline');
figure; histogram(bm_interp_surf - results.srf_height)
title('Surface height residuals')
figure; plot(bm_interp_surf); hold on;  plot(results.srf_height)
title('Surface Height'); legend('Bedmap interpolation','Radar calculated')

%%
cd /data/cees/amhilger/BEDMAP/
[bmx, bmy, bmthick] = ...
    bedmap2_data('thick', results.easts,results.norths,'xy');
bmi_thick = interp2(bmx, bmy, bmthick, ...
                    results.easts, results.norths, 'spline');
[bmx, bmy, bmunc] = ...
    bedmap2_data('beduncertainty', results.easts,results.norths,'xy');
bmi_unc = interp2(bmx, bmy, bmunc, ...
                  results.easts, results.norths, 'spline');
figure; histogram(bmi_thick - results.ice_thick)
title('Ice thickness residuals')
dist = results.rdr_dist/1000;
figure; plot(dist, bmi_thick, 'k', ...
             dist, results.ice_thick,'r',...
             dist, bmi_thick + bmi_unc,'k--', ...
             dist, bmi_thick - bmi_unc,'k--')
title('Ice thickness'); legend('Bedmap interpolation','Radar calculated')
xlabel('km along track')
cd(orig_dir)


outliers_above = results.ice_thick - bmi_thick - bmi_unc; 
%if +, then above uncertainty bound
outliers_below = results.ice_thick - bmi_thick + bmi_unc; 
% -, then below uncertainty bound

out_resid = [outliers_above(outliers_above > 0); ...
             outliers_below(outliers_below < 0)];

figure; histogram(out_resid)