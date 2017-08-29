load_dir = '/data/cees/amhilger/UTIG/sim_atten_bm_thick';
orig_dir = cd(load_dir);
cd(orig_dir)

%this aggregates all the bed powers, geometrically corrected powers, and
%reflectivites into some arrays. This is useful for making histograms or
%looking at transect-wide stats (percentiles, mean, min, max)

avg_lat = -77.5; avg_long = -110;
M = 100; %downsampling factor
transect_names = get_transects();

all_bed_pow = zeros(length(transect_names)*1000);
all_geo_pow = zeros(length(transect_names)*1000);
all_reflect_mean_atten = zeros(length(transect_names)*1000);
all_reflect_total_atten = zeros(length(transect_names)*1000);

save_index = 1;
cd(load_dir)
for i = 1:length(transect_names)
    disp(transect_names{i})

    load([transect_names{i} '_results.mat'])
    L = length(results.bed_pow);
    all_bed_pow(save_index:save_index+L-1) = ...
        results.bed_pow;
    all_geo_pow(save_index:save_index+L-1) = ...
        results.geo_pow;
    all_reflect_mean_atten(save_index:save_index+L-1) = ...
        results.reflect_mean_atten;
    all_reflect_total_atten(save_index:save_index+L-1) = ...
        results.reflect_total_atten;
    save_index = save_index + L;
    
end

all_bed_pow = all_bed_pow(1 : save_index - 1);
all_geo_pow = all_geo_pow(1 : save_index - 1);
all_reflect_mean_atten = all_reflect_mean_atten(1 : save_index - 1);
all_reflect_total_atten = all_reflect_total_atten(1 : save_index - 1);


cd(orig_dir)

