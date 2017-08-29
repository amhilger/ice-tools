function results = standardize_fields(results)

field_names = fieldnames(results);
for i = 1:length(field_names)
    new_name = rename_field(field_names{i});
    %if field_name not found in below dictionary, new_name is an empty
    %string, and the field is preserved in results
    if ~isempty(new_name) 
        results.(new_name) = results.(field_names{i});
        results = rmfield(results, field_names{i});
    end
end
    
end

function new_name = rename_field(old_name)

if any(strcmp(old_name, {'repick_lat', 'Lat','lats'}))
    new_name = 'lat';
elseif any(strcmp(old_name, {'repick_long', 'Long','longs'}))
    new_name = 'long';
elseif any(strcmp(old_name, {'repick_pri', 'PriNum'}))
    new_name = 'pri';
elseif strcmp(old_name, 'noisefloor')
    new_name = 'noise_floor';
elseif any(strcmp(old_name, {'repick_power','rawpower','bed_power'}))
    new_name = 'bed_pow';
elseif any(strcmp(old_name, {'derived_thick', 'iceThickness','thick','ice_thick'}))
    new_name = 'rdr_thick';
elseif strcmp(old_name, 'atten')
    new_name = 'atten_rate';
elseif strcmp(old_name, 'reflectivity')
    new_name = 'reflect';
elseif strcmp(old_name, 'fitdist')
    new_name = 'fit_distance';
elseif any(strcmp(old_name, {'repick_path_dist','adapt_path_dist','pathdist'}))
    new_name = 'rdr_dist';
elseif strcmp(old_name, 'C0')
    new_name = 'C_0';
elseif strcmp(old_name, 'C_min')
    new_name = 'C_min';
elseif strcmp(old_name, 'unc')
    new_name = 'atten_unc';
elseif strcmp(old_name, 'Eht')
    new_name = 'rdr_height';
elseif any(strcmp(old_name, {'resHt', 'repick_clear','clear'}))
    new_name = 'rdr_clear';
elseif any(strcmp(old_name, {'surfPickLoc'}))
    new_name = 'srf_pik_sample';
elseif any(strcmp(old_name, {'botPickLoc'}))
    new_name = 'bed_pik_sample';
elseif any(strcmp(old_name, {'surfElev'}))
    new_name = 'srf_height';
elseif any(strcmp(old_name, {'bedElev'}))
    new_name = 'bed_height';
else
    new_name = '';
end

end