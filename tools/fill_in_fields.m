function [results] = fill_in_fields(results)
%this fills in fields that may have gotten lost in shuffle

if ~isfield(results, 'easts') || ~isfield(results, 'norths')
    cd ../BEDMAP
    [results.easts, results.norths] = ll2ps(results.lat, results.long);
    cd ../tools
end

if ~isfield(results, 'lat') || ~isfield(results, 'long')
    cd ../BEDMAP
    [results.lat, results.long] = ps2ll(results.easts, results.norths);
    cd ../tools
end

if ~isfield(results, 'bm_thick')
    results.bm_thick = bedmap_thick(results.easts, results.norths);
end

if ~isfield(results, 'rdr_geo_pow')
    results.rdr_geo_pow = geo_correct_power(results.bed_pow, ...
                                      results.rdr_clear, ...
                                      results.rdr_thick);
end

if ~isfield(results, 'bm_geo_pow')
    results.bm_geo_pow = geo_correct_power(results.bed_pow, ...
                                      results.rdr_clear, ...
                                      results.bm_thick);
end

if isfield(results, 'geo_pow')
    results = rmfield(results, 'geo_pow');
end



if ~isfield(results, 'bm_srf_height')
    results.bm_srf_height = bedmap_surf_elev(results.easts, results.norths);
end

if ~isfield(results, 'bm_bed_height')
    results.bm_bed_height = bedmap_bed_elev(results.easts, results.norths);
end



if ~isfield(results, 'rdr_dist')
    results.rdr_dist = [0; cumsum(hypot(diff(results.easts), ...
                                       diff(results.norths)))];
end

if ~isfield(results, 'heading')
    results.heading = calc_heading_1km(results.easts, ...
                                       results.norths, ...
                                       results.rdr_dist);
end

                                   
end

