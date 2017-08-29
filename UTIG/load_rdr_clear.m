function [rdr_clear, surf_delay] = load_rdr_clear(transect_name)
%returns a vector of surface depths from the UTIG data. For entries where
%no pick is found ('x' in the file), the returned array's entry is NaN.

top_dir = '/data/schroeder/Andrew_ASE/targ/ASE1/';
pik_dir = 'PIK/ase1/THW/SJB2/';


load_dir = [top_dir pik_dir transect_name];
orig_dir = cd(load_dir); 

%if file not found, return NaN
srf_file_id = fopen('MagLoResInco1.srf');
if srf_file_id == -1
    rdr_clear = NaN;
    surf_delay = NaN;
    cd(orig_dir)
    return
end

srf_contents = textscan(srf_file_id, ...
                    '%s %f %*[^\n]', 'TreatAsEmpty', 'x');
num_lines = length(srf_contents{1});
surf_delay = zeros(num_lines, 1); 
out_index = 1;
%need to make sure number of empty piks is consistent to ensure alignment
for i = 1:num_lines
    if srf_contents{1}{i} == 'P'
        surf_delay(out_index) = srf_contents{2}(i);
        out_index = out_index+1;
    end
end
%strip empty values from end of array
surf_delay = surf_delay(surf_delay ~= 0);
%convert to height (in m?) using formula from Dusty's 3-ring binder
c_light = 3e8;
%add -17.5 to surf_delay
rdr_clear = (-17.5+surf_delay)*20e-9*c_light/2;
%sampling rate appears to be 1/20e-9 = 50 MHz; offset of 17.5 samples

if any(rdr_clear <= 0)
    disp(['Warning: negative clearance, worst is: ' ...
              num2str(min(rdr_clear))])
    disp(['Setting ' num2str(length(find(isnan(rdr_clear)))) ...
            ' negative clearances to NaN'])
    rdr_clear(rdr_clear <= 0) = NaN;
    
end

cd(orig_dir)


end

