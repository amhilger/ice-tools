function peakiness = peakiness_of(f_c, abrupt_max, abrupt, ...
                                       f_c_ref, abrupt_max_ref) 
%center frequency must be in Hz


n_ice = 1.782;
c_light = 2.99792e8; %m/s

%scalar function where g is abbreviation in abruptness formula
g = @(rms, freq_ctr) 4*pi*rms*freq_ctr*n_ice/c_light;
%rms based on typical values for 60 - 150 MHz radar
rms = 0:0.001:0.50;

%determine the abruptness function of rms for reference radar (see Peters
%05' for correct equation)
abrupt_rms_ref = abrupt_max_ref*exp(-g(rms, f_c_ref).^2) .* ...
                    besseli(0,g(rms, f_c_ref).^2/2).^2;
%linearly scale reference abruptness to peakiness index
peaky_ref = abrupt_rms_ref/max(abrupt_rms_ref);


%determine abruptness function of rms for input radar
abrupt_rms_in = abrupt_max*exp(-g(rms, f_c).^2) .* ...
                    besseli(0,g(rms, f_c).^2/2).^2;
%back solve the actual rms values corresponding to the input
rms_in = interp1(abrupt_rms_in, rms, abrupt);
%determine the peakiness corresponding to input rms values
peakiness = interp1(rms, peaky_ref, rms_in);

end