function [SRG_results] = ...
    repick_results_interp(transect_name, results_dir, save_dir, radar_dir)
%%repick a transect -- the transect name should be in the form "bXX", where
%%XX is a two-digit integer with a leading zero if necessary

%%this function calls repick_batch_interp.m and is called by a script such as 
%%do_much_repick.

%%overall, this function loads a BAS pick file (e.g., b02Bot_results.mat)
%%and uses the BAS picks as input to a repicker function repick_batch_interp.m.
%%This function iteratively calls the repicker, collects the results, and
%%resaves them 

%%Note the related file repick_results.m which does repicking without
%%interpolating additional picks, as this function does

%retrieve necessary parameters from results
results_file_name = [transect_name 'Bot_results.mat'];
curr_dir = cd(results_dir);
results = load(results_file_name);
cd(curr_dir)
results = results.results; %remove wrapper
res_pri = results.PriNum;
res_lat = results.Lat;
res_long = results.Long;

%%Guarding against max pick pri > max_attrib_pri
load bad_attrib_traces.mat
bad_traces_index = transect_to_bad_attrib_index(transect_name);
%Attribute of max pri in transect's attribute files. This will be either
%the last trace in the last attribute chunk or the last trace before a pri
%reset occurs.
max_attrib_pri = bad_traces(bad_traces_index).last_good_pri;
max_attrib_pri = min(max_attrib_pri, max_attrib_pri); 

%Discard picks with pris greater than the maximum pri of the transect's
%attribute files. This should be equivalent to discarding those picks that
%can't be matched to geolocated radar data.
res_pri = res_pri(res_pri <= max_attrib_pri);


%%Guarding against min pick pri < min attrib pri
cd /data/cees/amhilger/BBAS_PIG/rawIndotM/
load([transect_name 'priIndex.mat'])
min_attrib_pri = priIndex(1);
%Discard picks with pris less than the first pri of the transect's
%atttribute files. 
res_pri = res_pri(res_pri >= min_attrib_pri);
res_lat = res_lat(res_pri >= min_attrib_pri & res_pri <= max_attrib_pri);
res_long = res_long(res_pri >= min_attrib_pri & res_pri <= max_attrib_pri);
cd(curr_dir)

%Discard first and last results in transect to ensure sufficient radar data
%for repicks
res_pri = res_pri(5:end-5);
res_lat = res_lat(5:end-5);
res_long = res_long(5:end-5);

cd ../BEDMAP
all_path_dist = pathdistps(res_lat, res_long, 'km'); %distance in km
cd(curr_dir)

%number of batches of around 1000 repicks each
num_batches = ceil(length(res_pri)/1000);
%actual number of repicks in each batch
batch_size = floor(length(res_pri)/num_batches);

%estimate of maximum interps given interpolation distance of 5 m. 
max_num_interps = ceil((all_path_dist(end)-all_path_dist(1))/0.005);
repick_pri = zeros(max_num_interps, 1);
repick_power = zeros(max_num_interps, 1);
repick_sample = zeros(max_num_interps, 1);
repick_noise_floor = zeros(max_num_interps, 1);
interp_surf_pick = zeros(max_num_interps, 1);
repick_path_dist = zeros(max_num_interps, 1);
repick_is_interp = zeros(max_num_interps, 1);
repick_lat = zeros(max_num_interps, 1);
repick_long = zeros(max_num_interps, 1);
repick_clear = zeros(max_num_interps, 1);
last_index = 0; %initializing last_index so first_index starts at 1

%for each batch
for i = 1:num_batches
    pri_min = res_pri((i-1)*batch_size+1);
    if i ~= num_batches
        pri_max = res_pri(i*batch_size);
    else %for last batch
        pri_max = res_pri(end);
    end
    %call the repicker function for a batch
    [batch_pri, batch_power, batch_sample, batch_noise_floor, ...
        batch_surf_pick, batch_path_dist, batch_is_interp] = ...
        repick_batch_interp(transect_name, pri_min, pri_max, ...
                            results_dir, radar_dir);
    %adjust the indices of the output results file
    first_index = last_index+1;
    last_index = first_index + length(batch_power) - 1;
    %place the output of the batch repicker in a results array according to
    %the updated indices first_index and last_index
    repick_pri(first_index:last_index) = batch_pri;
    repick_power(first_index:last_index) = batch_power;
    repick_sample(first_index:last_index) = batch_sample;
    repick_noise_floor(first_index:last_index) = batch_noise_floor;
    interp_surf_pick(first_index:last_index) = batch_surf_pick;
    repick_path_dist(first_index:last_index) = batch_path_dist;
    repick_is_interp(first_index:last_index) = batch_is_interp;
    
    %lookup latitude, longitude, and terrain clearance from attributes file
    %because repick_batch does not interpolate these
    [batch_lat, batch_long, batch_clear] = ...
        get_interp_attrib(transect_name, pri_min, pri_max, batch_pri);
    repick_lat(first_index:last_index) = batch_lat;
    repick_long(first_index:last_index) = batch_long;
    repick_clear(first_index:last_index) = batch_clear;

end
%remove zeros from end of arrays
repick_pri = repick_pri(1:last_index);
repick_power = repick_power(1:last_index); 
repick_sample = repick_sample(1:last_index);
repick_noise_floor = repick_noise_floor(1:last_index);
interp_surf_pick = interp_surf_pick(1:last_index);
repick_path_dist = repick_path_dist(1:last_index);
repick_is_interp = repick_is_interp(1:last_index);
repick_lat = repick_lat(1:last_index);
repick_long = repick_long(1:last_index);
repick_clear = repick_clear(1:last_index);

disp('Done repicking. Saving repicks with trimmed results.')

%place results arrays into the SRG_results structure
SRG_results = trim_results_by_pri(results, min(res_pri), max(res_pri));
SRG_results.repick_pri = repick_pri;
SRG_results.repick_power = repick_power;
SRG_results.repick_sample = repick_sample;
SRG_results.noise_floor = repick_noise_floor;
SRG_results.interp_surf_pick = interp_surf_pick;
SRG_results.repick_path_dist = repick_path_dist;
SRG_results.is_interp = repick_is_interp;
SRG_results.repick_lat = repick_lat;
SRG_results.repick_long = repick_long;
SRG_results.repick_clear = repick_clear;

%save the SRG_results structure
cd(save_dir)
save_name = [transect_name '_SRG_interp_repick.mat'];
save(save_name, 'SRG_results')
cd(curr_dir)

end


function [interp_lat, interp_long, interp_clear] = ...
    get_interp_attrib(transect_name, min_pri, max_pri, interp_pri)

attrib_struct = get_attrib(transect_name, min_pri, max_pri);
transect_pri = attrib_struct.priNum;
transect_lat = attrib_struct.lat;
transect_long = attrib_struct.long;
transect_clear = attrib_struct.clearance;

interp_lat = zeros(length(interp_pri),1);
interp_long = zeros(length(interp_pri),1);
interp_clear = zeros(length(interp_pri),1);

%pull lat, long, and clearance from attribute file
for i = 1:length(interp_pri)
    index = find(transect_pri == interp_pri(i));
    % there are skips of 3600 pri in the attribute file. This corresponds
    % to a skip of roughly 100m distance in latitude
    if isempty(index) %if no exact match, find closest
        upper = transect_pri(find(transect_pri > interp_pri(i), 1));
        lower = transect_pri(find(transect_pri < interp_pri(i), 1, 'last'));
        if isempty(lower) && isempty(upper)
            disp(['Not found: interp pri ' num2str(interp_pri(i))])
            disp('No nearby pris found')
        elseif isempty(lower) || ...
                upper - interp_pri(i) < interp_pri(i) - lower
            index = find(transect_pri > interp_pri(i), 1);
            disp(['Not found: interp pri ' num2str(interp_pri(i))])
            disp(['Closest found: ' num2str(upper)])
        elseif isempty(upper) || ...
               upper - interp_pri(i) >= interp_pri(i) - lower
            index = find(transect_pri < interp_pri(i), 1, 'last');
            disp(['Not found: interp pri ' num2str(interp_pri(i))])
            disp(['Closest found: ' num2str(lower)])
        end
    end
    interp_lat(i) = transect_lat(index);
    interp_long(i) = transect_long(index);
    interp_clear(i) = transect_clear(index);
        
    
end

end

