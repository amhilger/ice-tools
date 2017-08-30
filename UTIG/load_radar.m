orig_dir = cd('../tools');
results_dir = '/data/cees/amhilger/UTIG/piks_lo_hi_filtered';


radar_dir = '/data/schroeder/Andrew_ASE/targ/ASE1/CMP/pik1/THW/SJB2/';
save_dir  = '/data/cees/amhilger/UTIG/radargram';
%test that save_dir exists
cd(save_dir); cd(orig_dir); 
tr_names = get_transect_names(radar_dir, {'X','Y','DRP'});

for i = 1:1% length(tr_names)
    cd([radar_dir tr_names{i}])
    hi_file_id = fopen('MagLoResInco1');
    %read all values as column vector, assume values stored in big-endian
    %32-bit integer format
    hi_radar   = fread(hi_file_id,Inf,'int32',0,'b');
    assert( mod(length(hi_radar), 3200) == 0)
    %reshape into 3200 x N array, with N traces and 3200 fast-time samples
    %per trace
    hi_radar   = reshape(hi_radar,[],3200)';
    
    
    %lo_file_id = fopen('MagLoResInco2');
    cd(save_dir)
    save([tr_names{i} '_radar.mat'], 'hi_radar')
end

imagesc(10*log10(hi_radar))


