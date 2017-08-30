function [lo_radar, hi_radar] = load_incoh_radar(transect_name)

%%
depth = 3200; %number of fast time samples
radar_dir = '/data/schroeder/Andrew_ASE/targ/ASE1/CMP/pik1/THW/SJB2/';

orig_dir = cd([radar_dir transect_name]);
hi_file_id = fopen('MagLoResInco2');
%read all values as column vector, assume values stored in big-endian
%32-bit integer format
hi_radar   = fread(hi_file_id,Inf,'int32',0,'b');
%reshape into 3200 x N array, with N traces and 3200 fast-time samples
%per trace
hi_radar   = reshape(hi_radar, depth, []);
%convert from milli-dB counts to dB
hi_radar = hi_radar/2000;

%load the lo-gain data and convert to dB, same as above
lo_file_id = fopen('MagLoResInco1');
lo_radar   = fread(lo_file_id,Inf,'int32',0,'b');
lo_radar   = reshape(lo_radar, depth, []);
lo_radar = lo_radar/2000;

cd(orig_dir)


