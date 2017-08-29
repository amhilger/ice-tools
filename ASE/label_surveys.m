
starts_with_strA = {'DRP','X','Y'};
starts_with_strB = {'b'};
orig_dir = pwd;
data_dir = [pwd '/atten_fit2d_ri_10km'];
results_name = '_results.mat';

cd ../tools
tr_namesA = get_transect_names(data_dir, starts_with_strA);
tr_namesB = get_transect_names(data_dir, starts_with_strB);

cd(data_dir)
%label the UTIG transects 1
for i = 1:length(tr_namesA)
    disp(tr_namesA{i})
    load([tr_namesA{i} results_name])
%     results.survey_num = results.tr_num;
%     results = rmfield(results,'tr_num');
    results.survey_num = 1*ones(length(results.bed_pow),1);
    save([tr_namesA{i} results_name],'results')
end

%label the BAS transects 2
for i = 1:length(tr_namesB)
    disp(tr_namesB{i})
    load([tr_namesB{i} results_name])
%     results.survey_num = results.tr_num;
%     results = rmfield(results,'tr_num');
    results.survey_num = 2*ones(length(results.bed_pow),1);
    save([tr_namesB{i} results_name],'results')
end