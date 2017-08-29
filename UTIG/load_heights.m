function [rdr_dist, rdr_height, srf_height] = ...
    load_heights(transect_name)
%loads distance, aircraft height, and aircraft clearance

%%don't use this distance it is in ft and is ocassionally non-monotonic
%%-- use the BEDMAP distance instead

%transect names is a cell containing strings for each transect name. It is
%assumed that transect_names will only include transects for which the
%necessary ztim and ztim_DNhH files are available. Use get_transects() to
%screen out transects with missing data.



top_dir = '/data/schroeder/Andrew_ASE/targ/ASE1/';
ztim_dir = 'CMP/pik1/THW/SJB2/';
pos_dir = 'FOC/MEP_Development/S1_POS/THW/SJB2/';

ztim_load_dir = [top_dir ztim_dir transect_name];
xy_load_dir = [top_dir pos_dir transect_name];

orig_dir = cd(ztim_load_dir); 
ztim_file_id = fopen('ztims');
if ztim_file_id == -1
    rdr_dist = NaN; rdr_height = NaN; rdr_clear = NaN;
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
xy_file_id = fopen('ztim_DNhH');
if xy_file_id == -1
    rdr_dist = NaN; rdr_height = NaN; rdr_clear = NaN;
    cd(orig_dir); return
end
xy_contents = textscan(xy_file_id, '(%d, %f, %f) %d %f %f %f');
dd = xy_contents{2};
tt = xy_contents{3};
if ~isempty(dd(dd ~= dd(1))) %if day change causes time rollover
    %assert year change -> no day rollover
    assert(xy_contents{1}(1) == xy_contents{1}(end))
    %
    tt = tt + (dd-dd(1))*24*3600*1e4;
end
DD = xy_contents{5};
HH = xy_contents{6};
hh = xy_contents{7};
%remove outliers based on 10 second window
MA_window = ceil(10e4/mean(diff(tt)));
DD_filt = medfilt1(DD, MA_window, 'omitnan','truncate');
HH_filt = medfilt1(HH, MA_window, 'omitnan','truncate');
hh_filt = medfilt1(hh, MA_window, 'omitnan','truncate');

%apply 3 StDev outlier test
cd /data/cees/amhilger/tools
DD_outliers = isoutlier_mstd(DD_filt, MA_window);
HH_outliers = isoutlier_mstd(HH_filt, MA_window);
hh_outliers = isoutlier_mstd(hh_filt, MA_window);

% disp([num2str(sum(DD_outliers)) ' distance outliers'])
% disp([num2str(sum(HH_outliers)) ' altitude outliers'])
% disp([num2str(sum(hh_outliers)) ' clearance outliers'])

%interpolate pik distance, aircraft height, and aircraft clearance from
%filtered data in the POS directory, where the interpolation position is
%determined by comparing the pik times in the ztim file against the
%corresponding times in the POS directory
rdr_dist = interp1(tt(~DD_outliers), DD_filt(~DD_outliers), ...
                   pik_times, 'linear',NaN);
rdr_height = interp1(tt(~HH_outliers), HH_filt(~HH_outliers), ...
                   pik_times, 'linear',NaN);
srf_height = interp1(tt(~hh_outliers), hh_filt(~hh_outliers), ...
                   pik_times, 'linear',NaN);



cd(orig_dir)


