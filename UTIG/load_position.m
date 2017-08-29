function [pik_easts, pik_norths] = load_position(transect_name)

top_dir = '/data/schroeder/Andrew_ASE/targ/ASE1/';
ztim_dir = 'CMP/pik1/THW/SJB2/';
pos_dir = 'FOC/MEP_Development/S1_POS/THW/SJB2/';

ztim_load_dir = [top_dir ztim_dir transect_name];
xy_load_dir = [top_dir pos_dir transect_name];

orig_dir = cd(ztim_load_dir); 
ztim_file_id = fopen('ztims');
if ztim_file_id == -1
    pik_easts = NaN; pik_norths = NaN;
    cd(orig_dir); return
end
ztim_contents = textscan(ztim_file_id, '(%d, %f, %f)');
pik_days = ztim_contents{2};
pik_times = ztim_contents{3};
%this handles the case of a ztim rollover
if pik_days(1) ~= pik_days(end) %assume monotonicity
    assert(ztim_contents{1}(1) == ztim_contents{1}(end))
    pik_times = pik_times + (pik_days-pik_days(1))*24*3600*1e4;
end



cd(xy_load_dir)
xy_file_id = fopen('ztim_xyhd');
if xy_file_id == -1
    pik_easts = NaN; pik_norths = NaN;
    cd(orig_dir); return
end
xy_contents = textscan(xy_file_id, '(%d, %f, %f) %f %f %*[^\n]');
dd = xy_contents{2};
tt = xy_contents{3}; 
if ~isempty(dd(dd ~= dd(1))) %if day change causes time rollover
    %assert year change -> no day rollover
    assert(xy_contents{1}(1) == xy_contents{1}(end))
    %
    tt = tt + (dd-dd(1))*24*3600*1e4;
end
ee = xy_contents{4};
nn = xy_contents{5};
%remove outliers based on 10 second window
MA_window = ceil(10e4/mean(diff(tt)));
ee_filt = medfilt1(ee, MA_window, 'omitnan','truncate');
nn_filt = medfilt1(nn, MA_window, 'omitnan','truncate');

%applied 3 standard deviation outlier test - 
% ee_outliers = isoutlier_mstd(ee_filt, MA_window);
% nn_outliers = isoutlier_mstd(nn_filt, MA_window);
% disp([num2str(sum(ee_outliers)) ' easts outliers'])
% disp([num2str(sum(nn_outliers)) ' norths outliers'])

%changed from spline to linear because the former is very inaccurate when
%interpolating in a region where all the points are removed as outliers
pik_easts = interp1(tt, ee_filt, pik_times, 'linear', NaN);
pik_norths = interp1(tt, nn_filt, pik_times, 'linear', NaN);

cd(orig_dir)


