cd /data/cees/amhilger/UTIG

avg_lat = -77.5; avg_long = -110;
M = 100; %downsampling factor
transect_names = get_transects();


%% velocity underlay
orig_dir = cd('/data/cees/amhilger/MEASURES');

f = gcf; close(f); figure
measuresps('speed','log','alpha',0.5)
mapzoomps(avg_lat, avg_long, 'size', 1000)
hold on
measuresps('gl','Color','k')

graticule_lats = floor(avg_lat)-5:ceil(avg_lat)+5;
graticule_lats = graticule_lats(graticule_lats>-90); %remove lats beyond 90 S
graticule_longs = floor(avg_long)-20:ceil(avg_long)+20;
graticuleps(graticule_lats, graticule_longs,'k:','linewidth',0.5)
velo_ax = gca;
cb1 = colorbar(velo_ax,'Position',[.08 .11 .0675 .815]);
ylabel(cb1, 'm/yr') %underlay units


%% overlay
flt_ax = axes;
hold on; cd(orig_dir)

for i = 1:length(transect_names)
    disp(transect_names{i})
    cd /data/cees/amhilger/UTIG
    ice_thick = load_ice_thickness(transect_names{i}); 
    %[srf_ht, ~] = load_surf_height(transect_names{i});
    [easts, norths] = load_position(transect_names{i});
    [~, ~, rdr_clear] = load_clear_dist(transect_names{i});
    bed_pow = load_bed_power(transect_names{i});
    cd ../BBAS_PIG
    geo_pow = geo_correct_power(bed_pow, rdr_clear, ice_thick);
    %[reflect, ~, ~, ~, ~] = ...
    %    fit_attenuation_rate(bed_pow, ice_thick, rdr_clear); 

    cd /data/cees/amhilger/UTIG
    east_r = downsample_data(easts,M);
    north_r = downsample_data(norths,M);
    geo_pow_r = downsample_data(geo_pow,M);
    plot_one_overlay(flt_ax, east_r, north_r, geo_pow_r);
    
end

cb2 = colorbar(flt_ax,'Position',[.85 .11 .0675 .815]);
ylabel(cb2, 'dB') %line units

combine_plots(velo_ax, flt_ax)
    

