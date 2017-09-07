function [bed_delay, bed_delay_lo] = load_bed_delay(transect_name)
%returns a vector of bed delays from the UTIG data. For entries where
%no pick is found ('x' in the file), the returned array's entry is NaN.

%this can be combined with the surface height info to determine ice
%thickness

top_dir = '/data/schroeder/Andrew_ASE/targ/ASE1/';
pik_dir = 'PIK/ase1/THW/SJB2/';


load_dir = [top_dir pik_dir transect_name];
orig_dir = cd(load_dir); 

%if file not found, return NaN
bed_file_id = fopen('MagLoResInco2.bed');
bed_file_id_lo = fopen('MagLoResInco1.bed');
if bed_file_id == -1
    bed_delay = NaN;
else
    bed_contents = textscan(bed_file_id, ...
                        '%s %f %*[^\n]', 'TreatAsEmpty', 'x');
    num_lines = length(bed_contents{1});
    bed_delay = zeros(num_lines, 1); 
    out_index = 1;
    %need to make sure number of empty piks is consistent to ensure alignment
    for i = 1:num_lines
        if bed_contents{1}{i} == 'P'
            bed_delay(out_index) = bed_contents{2}(i);
            out_index = out_index+1;
        end
    end
    %strip empty values from end of array
    bed_delay = bed_delay(bed_delay ~= 0);
end

if bed_file_id_lo == -1
    bed_delay_lo = NaN;
else
    bed_contents_lo = textscan(bed_file_id_lo, ...
                        '%s %f %*[^\n]', 'TreatAsEmpty', 'x');
    num_lines = length(bed_contents_lo{1});
    bed_delay_lo = zeros(num_lines, 1); 
    out_index = 1;
    %need to make sure number of empty piks is consistent to ensure alignment
    for i = 1:num_lines
        if bed_contents_lo{1}{i} == 'P'
            bed_delay_lo(out_index) = bed_contents_lo{2}(i);
            out_index = out_index+1;
        end
    end
    %strip empty values from end of array
    bed_delay_lo = bed_delay_lo(bed_delay_lo ~= 0);
end

if length(bed_delay) ~= length(bed_delay_lo)
    bed_delay = bed_delay(1:length(bed_delay_lo)); 
    disp('Truncating hi-gain bed delays to length of low-gain bed delays')
end



cd(orig_dir)


end

