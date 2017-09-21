
starts_with_str = {'DRP','X','Y','b'};
orig_dir = pwd;
load_dir = [pwd '/piks_agg_xover_filter'];
save_dir = [pwd '/piks_agg_xover_filter'];
results_name = '_results.mat';

cd ../tools
tr_names = get_transect_names(load_dir, starts_with_str);

f_c_ref = 150e6; %MHz, reference to BAS

for i = 1:length(tr_names)
    disp(tr_names{i})
    cd(load_dir); load([tr_names{i} results_name])
    
    switch results.survey_num(1)
        case 1 %UTIG
            abrupt_max = 0.165; f_c = 60e6;
        case 2 %BAS
            abrupt_max = 0.255; f_c = 150e6;
        otherwise
            error('Unrecognized survey number')
    end
    cd(orig_dir); cd ../tools
    [results.peakiness, ...
     results.rms_norm] = peakiness_of(abrupt_max, ...
                                      results.abrupt);
    cd(save_dir); save([tr_names{i} results_name],'results')
end

cd(orig_dir)