function [] = plotSARresult(radar_data, x_param, x_name, isPower)
%makes a radargram using radar_data, a 2d array where each column is a
%trace (ie returns from a particular transmitted chirp pulse) and each row
%is a fast time sample (first row is earliest sample after pulse, last row
%is last sample after pulse until next transmitted pulse)

%plot parameters
plotDepthMin = 1; % upper depth for plots (fast time sample #)
plotDepthMax = 1250; % lower depth for plots (fast time sample #)
plot_y = [plotDepthMin plotDepthMax];
cbarmin = 100; % lower limit for color scale on plots
cbarmax = 200; % upper limit for color scale on plots

%x_param is an array of data for the x-axis (e.g., PRI, time, along-track
%distance). x_param needs to be the same length as the number of traces in
%the radar data
if ~exist('x_param', 'var')
    x_param = 1:size(radar_data,1);
end
%x_name is a string used to label the x-axis
if ~exist('x_name', 'var')
    x_name = '';
end

%By default, assume plotting SAR power (as in SAR result)
if ~exist('isPower', 'var')
    isPower = 1;
end
if isPower ~= 0 && isPower ~= 1
    error('isPower should be a binary value')
end

%set scaling factor for dB scale
%defaults to 10 (assuming radar_data is power measurement)
%becomes 20 if radar_data represents amplitude
dbScale = 10*(2-isPower); 




%%% plot radar data %%%
[~, trace_len] = size(radar_data);
plot_x = [min(x_param), x_param(trace_len)];
plot_C = dbScale*log10(abs(radar_data(plotDepthMin:plotDepthMax,:)));
imagesc(plot_x, plot_y, plot_C, [cbarmin,cbarmax])
xlabel(x_name)
ylabel('Fast-time samples')
cb = colorbar();
ylabel(cb, 'dB')