orig_dir = cd('../tools');
results_dir = '/data/cees/amhilger/UTIG/piks_lo_hi_filtered';



save_dir  = '/data/cees/amhilger/UTIG/radargram';
%test that save_dir exists
cd(save_dir); cd(orig_dir); cd ../tools
tr_names = get_transect_names(results_dir, {'X','Y','DRP'});