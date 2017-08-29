function [results] = ...
    repick_results_agg(transect_name, results_dir, save_dir, radar_dir)
%%repick a transect -- the transect name should be in the form "bXX", where
%%XX is a two-digit integer with a leading zero if necessary

%%this function calls repick_batch_agg.m and is called by do_much_repick.

%%this function repicks for aggregated bed power within range determined by Fresnel zone (see radar Tom Jordan paper)

%retrieve necessary parameters from results
results_file_name = [transect_name '_results.mat'];
curr_dir = cd(results_dir);
load(results_file_name);
cd(curr_dir)
res_pri = results.pri;


%%Guarding against max pick pri > max_attrib_pri
load bad_attrib_traces.mat
bad_traces_index = transect_to_bad_attrib_index(transect_name);
%Attribute of max pri is transect's attribute files. This will be either
%the last trace in the last attribute chunk or the last trace before a pri
%reset occurs.
max_attrib_pri = bad_traces(bad_traces_index).last_good_pri;
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
cd(curr_dir)



%Discard first and last results in transect to ensure sufficient radar data
%for repicks
res_pri = res_pri(5:end-5);




%number of batches of around 1000 repicks each
num_batches = ceil(length(res_pri)/1000);
%actual number of repicks in each batch
batch_size = floor(length(res_pri)/num_batches);


repick_max_pow = zeros(size(res_pri));
repick_mp_sample = zeros(size(res_pri));
repick_noise_floor = zeros(size(res_pri));
repick_agg_pow = zeros(size(res_pri));
repick_ft_range = zeros(size(res_pri));
last_index = 0; %initializing last_index so first_index starts at 1

%for each batch
for i = 1:num_batches
    pri_min = res_pri((i-1)*batch_size+1);
    if i ~= num_batches
        pri_max = res_pri(i*batch_size);
    else
        pri_max = res_pri(end);
    end
    [batch_max_pow, batch_mp_sample, batch_noise_floor, ...
	 	    batch_agg_pow, batch_ft_range] = ...
        repick_batch_agg(transect_name, pri_min, pri_max, ...
                     results_dir, radar_dir);
    first_index = last_index+1;
    last_index = first_index + length(batch_max_pow) - 1;
    repick_max_pow(first_index:last_index) = batch_max_pow;
    repick_mp_sample(first_index:last_index) = batch_mp_sample;
    repick_noise_floor(first_index:last_index) = batch_noise_floor;
    repick_agg_pow(first_index:last_index) = batch_agg_pow;
    repick_ft_range(first_index:last_index) = batch_ft_range;
end

disp('Done repicking. Saving repicks with trimmed results.')
%place results arrays into the results structure
results = trim_results_by_pri(results, min(res_pri), max(res_pri));
results.max_pow = repick_max_pow;
results.max_pow_sample = repick_mp_sample;
results.noise_floor = repick_noise_floor;
results.agg_pow = repick_agg_pow;
results.ft_range = repick_ft_range;
results.abrupt = results.max_pow./results.agg_pow;

cd(save_dir)
save_name = [transect_name '_results.mat'];
save(save_name, 'results')
cd(curr_dir)



end

