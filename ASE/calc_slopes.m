orig_dir = pwd;
starts_with_str = {'DRP','X','Y', 'b'};
data_dir = [pwd '/atten_fit2d_ri_10km'];
save_dir = [pwd '/slopes'];
results_name = '_results.mat';

five_point = @(x) (-x(1)+8*x(2)-8*x(4)+x(5))/12; 

cd ../tools
tr_names = get_transect_names(data_dir, starts_with_str);

survey = combine_results(data_dir, tr_names, results_name);

cd ../BEDMAP 
%return 5 extra km
[x_bed, y_bed, z_bed] = bedmap2_data('bedw', ...
                                     survey.easts, survey.norths, ...
                                     5, 'xy');
[x_srf, y_srf, z_srf] = bedmap2_data('surfacew', ...
                                     survey.easts, survey.norths, ...
                                     5, 'xy');

%calculate gradients - these are units of km/m because bedmap returns 1 km
%grid
[del_bed_x, del_bed_y] = gradient(z_bed);
[del_srf_x, del_srf_y] = gradient(z_srf);

%calculate overall gradient -
% divide by 1000 to ensure consistent bed units
del_bed = hypot(del_bed_x, del_bed_y)/1000;
del_srf = hypot(del_srf_x, del_srf_y)/1000;

%load each transect and interpolate slopes
for i = 1:length(tr_names)
    disp(tr_names{i})
    cd(data_dir)
    load([tr_names{i} results_name])
    %interpolate slopes at each point from calculated slopes
    results.bed_slope = interp2(x_bed, y_bed, del_bed, ...
                                results.easts, results.norths);
    results.srf_slope = interp2(x_srf, y_srf, del_srf, ...
                                results.easts, results.norths);
    %save data
    cd(save_dir)
    save([tr_names{i} results_name],'results')
end

cd(orig_dir)
