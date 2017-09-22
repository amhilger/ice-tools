function [peakiness, rms_norm] = peakiness_of(abrupt_max, abrupt)
%{this function computes the peakiness (system independent abruptness)
based on the max abruptness of the radar system and the abruptness observed 
from a transect %}

%abruptness and peakiness are a function of g, which is the wavelength-
%normalized rms height multiplied by a scaling prefactor:  
% g = @(rms, freq_ctr) 4*pi*rms*freq_ctr*n_ice/c_light;

n_ice = 1.782;
% c_light = 2.99792e8; %m/s

%reference values of g covering peakiness from 1 (g = 0) to 0.01 (g ~= 5)
g_ref = 0:0.001:5;

%determine the abruptness function of rms for reference radar (see Peters
%05' and TJ in prep)
abrupt_rms_sys = abrupt_max*exp(-g_ref.^2) .* besseli(0,g_ref.^2/2).^2;
%linearly scale reference abruptness to peakiness index
peaky_ref = exp(-g_ref.^2) .* besseli(0,g_ref.^2/2).^2;



%back solve the actual rms values corresponding to the input
g_in = interp1(abrupt_rms_sys, g_ref, abrupt);
rms_norm = g_in/(4*pi*n_ice); %rms roughness normalized by wavelength
%determine the peakiness corresponding to input rms values
peakiness = interp1(g_ref, peaky_ref, g_in);
 
end
