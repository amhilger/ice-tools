


orig_dir = pwd;
transect_names = get_transects();
maxmax_ztim = 0;

for i = 1:length(transect_names);
    disp(transect_names{i})
    [dist, alt, clear] = ...
        load_clear_dist(transect_names{i});
    

%    [easts, norths] = load_position(transect_names{i});
%     bed_pow_stuff = load_bed_power(transect_names{i});
%     if length(bed_pow_stuff) == 1 
%     %if max(bed_pow_stuff) - min(bed_pow_stuff) >= 72 %dB dynamic range
%         %verify that correct dB conversion factor used 
%         disp(transect_names{i})
%         disp(length(bed_pow_stuff))
%         disp(max(bed_pow_stuff) - min(bed_pow_stuff))
%     end
%     surf_stuff = load_surf_height(transect_names{i});
%     bed_stuff = load_bed_delay(transect_names{i});
%     if length(surf_stuff) ~= length(bed_stuff)
%         disp([transect_names{i} ': surf - ' num2str(length(surf_stuff)) ... 
%               '; bed - ' num2str(length(bed_stuff))])
%     end
end

