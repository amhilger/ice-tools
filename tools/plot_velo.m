function [over_ax, cb1] = plot_velo(f, avg_lat, avg_long, map_size)
% plot semi-transparent velocity underlay. Use with plot_one_overlay
% repeatedly to plot flight lines.


if ~exist('avg_lat','var')
    avg_lat = -77.5;
end
if ~exist('avg_long','var')
    avg_long = -112;
end

if ~exist('map_size', 'var')
    map_size = 800; %km
end
    
% If f given, plot in figure f. Otherwise, create new figure
if ~exist('f','var')
    f = figure;
else
    figure(f)
end

orig_dir = cd('../MEASURES');
mapzoomps(avg_lat, avg_long, 'size', map_size)
measuresps('speed','log','alpha',0.5)

hold on
measuresps('gl','Color','k')

graticule_lats = floor(avg_lat)-5:ceil(avg_lat)+5;
graticule_lats = graticule_lats(graticule_lats>-90); %remove lats beyond 90 S
graticule_longs = (floor(avg_long)-30):(ceil(avg_long)+30);
graticuleps(graticule_lats, graticule_longs,'k:','linewidth',0.5)
over_ax = gca;
cb1 = colorbar(over_ax,'Position',[.08 .11 .0675 .815]);
ylabel(cb1, 'log_{10}(m/yr)') %underlay units

cd(orig_dir)