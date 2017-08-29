function [bed_pow_lo, bed_pow_hi] = load_bed_power(transect_name)
%returns a vector of bed delays from the UTIG data. For entries where
%no pick is found ('x' in the file), the returned array's entry is NaN.

%this can be combined with the surface height info to determine ice
%thickness

top_dir = '/data/schroeder/Andrew_ASE/targ/ASE1/';
pik_dir = 'PIK/ase1/THW/SJB2/';


load_dir = [top_dir pik_dir transect_name];
orig_dir = cd(load_dir); 

%if file not found, return NaN
lo_file_id = fopen('MagLoResInco1.bed');
hi_file_id = fopen('MagLoResInco2.bed');

if lo_file_id == -1
    bed_pow_lo = NaN;
else
    lo_contents = textscan(lo_file_id, ...
                        '%s %f %u %u %f', 'TreatAsEmpty', 'x');
    num_lo_lines = length(lo_contents{1});
    bed_pow_lo = zeros(num_lo_lines, 1); 
    out_index = 1;
    %need to make sure number of empty piks is consistent to ensure alignment
    for i = 1:num_lo_lines
        if lo_contents{1}{i} == 'P'
            bed_pow_lo(out_index) = lo_contents{5}(i);
            out_index = out_index+1;
        end
    end
    %strip empty values from end of array
    bed_pow_lo = bed_pow_lo(bed_pow_lo ~= 0);
    bed_pow_lo = bed_pow_lo/2000; %convert from milli-dBcounts to dB
end

if hi_file_id == -1
    bed_pow_hi = NaN;
else
    hi_contents = textscan(hi_file_id, ...
                        '%s %f %u %u %f', 'TreatAsEmpty', 'x');
    num_hi_lines = length(hi_contents{1});
    bed_pow_hi = zeros(num_hi_lines, 1); 
    out_index = 1;
    %need to make sure number of empty piks is consistent to ensure alignment
    for i = 1:num_hi_lines
        if hi_contents{1}{i} == 'P'
            bed_pow_hi(out_index) = hi_contents{5}(i);
            out_index = out_index+1;
        end
    end
    %strip empty values from end of array
    bed_pow_hi = bed_pow_hi(bed_pow_hi ~= 0);
    bed_pow_hi = bed_pow_hi/2000; %convert from milli-dBcounts to dB
end

if length(bed_pow_lo) ~= length(bed_pow_hi)
%     a = find(isnan(bed_pow_hi));
%     b = find(isnan(bed_pow_lo));
%     keyboard
    bed_pow_hi = bed_pow_hi(1:length(bed_pow_lo));
    disp('Truncating hi-gain bed power to length of low-gain bed power')
end




cd(orig_dir)


end

