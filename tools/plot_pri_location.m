function [f] = plot_pri_location(results, pri_min, pri_max)
%plots the transect between pri min and pri max using the BAS picks results

lat = results.Lat(results.PriNum >= pri_min & ...
                  results.PriNum <= pri_max);
long = results.Long(results.PriNum >= pri_min & ...
                    results.PriNum <= pri_max);
pri = results.PriNum(results.PriNum >= pri_min & ...
                     results.PriNum <= pri_max);
                 
cd('/data/cees/amhilger/MEASURES/')
[easts, norths] = ll2ps(lat, long);

orig_dir = cd('/data/cees/amhilger/UTIG/');
f = figure;
plot_contour(f, mean(lat,'omitnan'), mean(long,'omitnan'));
hold on
[velo_ax, ~] = plot_velo(f, mean(lat,'omitnan'), mean(long,'omitnan'));
                              
over_ax = axes(f);
plot_one_overlay(over_ax, easts, norths, pri);
over_cb = colorbar(over_ax,'Position',[.85 .11 .0675 .815]);
ylabel(over_cb, 'PRI') %line units

combine_plots(velo_ax, over_ax)


cd(orig_dir)



end

