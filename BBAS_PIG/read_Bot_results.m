function [results] = read_Bot_results(file_name, input_dir, save_dir)

original_folder = cd(input_dir);

%designed with respect to a "bottom" results file. 

%get the file id of the .txt file
file_id = fopen(file_name);
%start reading the comma-separate text file, discarding the header row
textscan(file_id,'%*s',18,'Delimiter',',');
%read file file, discarding flight number
scanned_results = textscan(file_id, ...
    '%f %f %f %*s %f %f %f %f %f %f %f %f %f %f %f %f %f %f', ...
    'Delimiter',',');
fclose(file_id);
temp  = cell2mat(scanned_results);

results.traceNum = temp(:,1); % trace number, some have been discarded
results.Long = temp(:,2); %longitude, projection tbd
results.Lat = temp(:,3); %latitude, projection tbd
results.resTime = temp(:,4); % presumably time of day in [s]
results.PriNum = temp(:,5); % pulse repitition interval index number
results.Eht = temp(:,6); % Radar altitude, [m] (estimated?)
results.resHt = temp(:,7); % Ground clearance, [m]
results.surfElev = temp(:,8); % Surface height, [m]
results.bedClass = temp(:,9); % BAS classification of bed, presumably material based
results.bedElev = temp(:,10); % Bed elevation, [m]
results.iceThickness = temp(:,11); % Ice thickness, [m]
results.surfPickLoc = temp(:,12); % Surface pick location, sample index
results.botPickLoc = temp(:,13); % Bed pick location, sample index
results.FB_spikiness = temp(:,14); 
results.FB_energy = temp(:,15);
results.Trc_energy = temp(:,16);
results.pre_FB_energy = temp(:,17);

save_name = [file_name(1:3) 'Bot_results.mat'];
cd(save_dir)
save(save_name, 'results')

cd(original_folder);
%}

end

