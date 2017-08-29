function [SRG_results] = ...
    repick_results(transect_name, results_dir, save_dir, radar_dir)
%%repick a transect -- the transect name should be in the form "bXX", where
%%XX is a two-digit integer with a leading zero if necessary

%%this function calls repic_batch.m and is called by do_much_repick.

%retrieve necessary parameters from results
results_file_name = [transect_name 'Bot_results.mat'];
curr_dir = cd(results_dir);
results = load(results_file_name);
cd(curr_dir)
results = results.results; %remove wrapper
res_pri = results.PriNum;


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


repick_power = zeros(size(res_pri));
repick_sample = zeros(size(res_pri));
repick_noise_floor = zeros(size(res_pri));
last_index = 0; %initializing last_index so first_index starts at 1

%for each batch
for i = 1:num_batches
    pri_min = res_pri((i-1)*batch_size+1);
    if i ~= num_batches
        pri_max = res_pri(i*batch_size);
    else
        pri_max = res_pri(end);
    end
    [batch_power, batch_sample, batch_noise_floor] = ...
        repick_batch(transect_name, pri_min, pri_max, ...
                     results_dir, radar_dir);
    first_index = last_index+1;
    last_index = first_index + length(batch_power) - 1;
    repick_power(first_index:last_index) = batch_power;
    repick_sample(first_index:last_index) = batch_sample;
    repick_noise_floor(first_index:last_index) = batch_noise_floor;
end

disp('Done repicking. Saving repicks with trimmed results.')
%place results arrays into the SRG_results structure
SRG_results = trim_results_by_pri(results, min(res_pri), max(res_pri));
SRG_results.repick_power = repick_power;
SRG_results.repick_sample = repick_sample;
SRG_results.noise_floor = repick_noise_floor;

cd(save_dir)
save_name = [transect_name '_SRG_repick.mat'];
save(save_name, 'SRG_results')
cd(curr_dir)



end

