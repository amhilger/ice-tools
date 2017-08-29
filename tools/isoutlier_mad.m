function [is_outlier] = isoutlier_mad(input_data, window_len)
%This function indicates whether each element of input_data is an outlier
%by determining whether it is within 3 median absolute deviations of the
%median. The median and median average deviation are calculated using a
%centered moving average window of length window_len


if mod(window_len, 2) == 0 %if window length is even
    MA_lower = -window_len/2; %lower half ends at previous entry
    MA_upper = window_len/2-1; %upper half starts at current entry
else %window length is odd
    MA_lower = -(window_len-1)/2; %lower half ends at previous entry
    MA_upper = (window_len-1)/2;  %upper half begins at next entry
end

%moving average median is a built-in function - yay
mov_median = movmedian(input_data, window_len, 'omitnan');

%moving median average deviation not a built-in function until R2017a--boo
%this omits NaN entries of input_data in calculation
mov_med_dev = zeros(size(input_data)); %initialize moving MAD
%calculate first and last indices where window shrinks at edges to avoid
%out of bounds indexing errors
first_index = max(1, MA_lower + (1:length(input_data)));
last_index = min(length(input_data), MA_upper + (1:length(input_data)));
%identify non-NaN entries that we can use in the calculation
for i = 1:length(mov_med_dev) 
    %calculate over non-NaN entries within the moving average window
    %calculate MAD - basically L1 version of standard deviation
    mov_med_dev(i) = median( abs( ...
        input_data(~isnan(input_data(first_index(i):last_index(i)))) - ...
        mov_median(i) ) );
end

%use three MAD from median criteria to detect outliers
is_outlier = ( abs(input_data-mov_median) > 3*mov_med_dev );

end

