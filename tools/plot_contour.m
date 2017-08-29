function [under_ax] = plot_contour(f, avg_lat, avg_long, map_size, N)
% plot contours every 400 m from -2500 to 3500 m. Use with plot_one_overlay
% repeatedly to plot flight lines.

contour_vert_res = 200;

if ~exist('avg_lat','var')
    avg_lat = -77.5;
end
if ~exist('avg_long','var')
    avg_long = -112;
end
if ~exist('N','var')
    N = 500; %horizontal resolution of contours 
    %N = 500 and mapsize = 1000 km -> 2km horizontal contour resolution
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

orig_dir = cd('../BEDMAP');
mapzoomps(avg_lat, avg_long, 'size', map_size)
xi = linspace(f.Children.XLim(1), f.Children.XLim(2), N);
yi = linspace(f.Children.YLim(1), f.Children.YLim(2), N);

[bmx, bmy, bm_bedz] = bedmap2_data('bedw',xi,yi,'xy');
cd ../MEASURES/
measuresps('gl','k')
mapzoomps(avg_lat, avg_long, 'size', map_size)
hold on
contour(bmx, bmy, bm_bedz, -2500:contour_vert_res:3500, ...
        'LineColor', [0.5 0.5 0.5], 'LineWidth', 0.3)


graticule_lats = floor(avg_lat)-5:ceil(avg_lat)+5;
graticule_lats = graticule_lats(graticule_lats>-90); %remove lats beyond 90 S
graticule_longs = floor(avg_long)-30:ceil(avg_long)+30;
graticuleps(graticule_lats, graticule_longs,'k:','linewidth',0.5)
under_ax = gca;


cd(orig_dir)

end