
load_dir = [pwd '/agg_filter'];
orig_dir = pwd;

cd ../tools
transect_names = get_transect_names(load_dir); cd(orig_dir)

st_dev = zeros(size(transect_names));
mu = zeros(size(transect_names));

for i = 1:length(transect_names)
    cd(load_dir)
    data_name = [transect_names{i} '_results.mat'];
    disp(data_name); load(data_name)
    
    %downsample to 1 pik per km
    st_dev(i) = std(results.peakiness,'omitnan');
    mu(i) = mean(results.peakiness, 'omitnan'); 
end

cd(orig_dir)
close(figure(1)); figure(1); histogram(st_dev, 10)
title('Transect Standard Deviation')
close(figure(2)); figure(2); histogram(mu, 10)
title('Transect Mean')