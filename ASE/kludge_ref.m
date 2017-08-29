orig_dir = pwd;
adapt_dir = [pwd '/sep_adapt'];
calib_dir = [pwd '/cross_calib'];
save_dir = [pwd '/kludge'];
cd ../tools
tr_names = get_transect_names(adapt_dir);

for i = 1:length(tr_names)
    disp(tr_names{i})
    cd(calib_dir)
    load([tr_names{i} '_results.mat'])
    gp = results.geo_pow_calib;
    cd(adapt_dir)
    load([tr_names{i} '_results.mat'])
    results.reflect = gp + 2*results.atten_rate.*results.rdr_thick;
    cd(save_dir)
    save([tr_names{i} '_results.mat'],'results')
    
end
    
    

cd(orig_dir)