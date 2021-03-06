orig_dir = pwd;
file_id = fopen('vries.txt');
file_contents = textscan(file_id, ...
                         '%*f %f %f %f %f %f %f %f %f %f %f %f %f %s', 178);
                     
volc_lat = file_contents{5}; volc_lon = file_contents{6};
volc_conf = file_contents{12};

cd ../BEDMAP
[volc_x, volc_y] = ll2ps(volc_lat, volc_lon); 

new_volc = cellfun(@(s) strcmp(s, 'No'), file_contents{13});

cd ../tools
close(figure(6)); figure(6)
%plot the new volcanoes as stars
scatter(volc_x(new_volc), volc_y(new_volc), ...
        30*ones(size(volc_x(new_volc))), volc_conf(new_volc), ...
        'filled','p')
cb = colorbar; ylabel(cb, 'Confidence')
hold on
%plot the old volcanoes as circles
scatter(volc_x(~new_volc), volc_y(~new_volc), ...
        20*ones(size(volc_x(~new_volc))), volc_conf(~new_volc), ...
        'filled','o')
    
cd(orig_dir)

f = figure(1); ax1 = gca;
ase_volc_x = volc_x(volc_x >= ax1.XLim(1) & ...
                    volc_x <= ax1.XLim(2) & ...
                    volc_y >= ax1.YLim(1) & ...
                    volc_y <= ax1.YLim(2));
ase_volc_y = volc_y(volc_x >= ax1.XLim(1) & ...
                    volc_x <= ax1.XLim(2) & ...
                    volc_y >= ax1.YLim(1) & ...
                    volc_y <= ax1.YLim(2));
ase_volc_conf = volc_conf(volc_x >= ax1.XLim(1) & ...
                          volc_x <= ax1.XLim(2) & ...
                          volc_y >= ax1.YLim(1) & ...
                          volc_y <= ax1.YLim(2));
figure(1); hold on
scatter(ase_volc_x, ase_volc_y, ...
        64*ones(size(ase_volc_x)),'k','filled','p')