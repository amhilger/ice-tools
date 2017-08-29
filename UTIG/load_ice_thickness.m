function [ice_thick, ice_thick_lo] = load_ice_thickness(transect_name, flag_neg_thick)
%Determines ice thickness, assuming 50 MHz sampling rate

c = 3e8;
n_ice = 1.782; %corresponds to 168.375 m/us ice velocity, 
% as used in Holt 2006

if ~exist('flag_neg_thick', 'var')
    flag_neg_thick = true;
end

[bed_delay, bed_delay_lo] = load_bed_delay(transect_name);
[~, surf_delay] = load_rdr_clear(transect_name);

if length(bed_delay) ~= length(bed_delay_lo)
%     a = find(isnan(bed_delay));
%     b = find(isnan(bed_delay_lo));
%     keyboard
    bed_delay = bed_delay(1:length(bed_delay_lo)); 
    disp('Truncating hi-gain bed delays to length of low-gain bed delays')
end

%By matching indexes of Nans, confirmed extra samples in X67a bed_delay are
%all at end, so can match up by truncating
ice_thick = (bed_delay-surf_delay)*20e-9*c/n_ice/2;
ice_thick_lo = (bed_delay_lo-surf_delay)*20e-9*c/n_ice/2;

if any(ice_thick < 0)
    disp(['Warning: negative ice thickness, worst is: ' ...
          num2str(min(ice_thick))])
    if flag_neg_thick
        disp(['Setting ' num2str(length(find(isnan(ice_thick)))) ...
            ' out of ' num2str(length(ice_thick)) ' piks to NaN'])
        disp(['Average negative thickness: ' ...
            num2str(mean(ice_thick(ice_thick < 0),'omitnan')) ' m'])
        ice_thick(ice_thick < 0) = NaN;
    end
end

if any(ice_thick_lo < 0)
    ice_thick_lo(ice_thick_lo < 0) = NaN;
end

