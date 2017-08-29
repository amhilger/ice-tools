function [is_outlier] = isoutlier_mstd(input_data, window_len)
%This function indicates whether each element of input_data is an outlier
%by determining whether it is within 3 median absolute deviations of the
%median. The median and median average deviation are calculated using a
%centered moving average window of length window_len


%moving average median is a built-in function - yay
mov_median = movmedian(input_data, window_len, 'omitnan');
mov_st_dev = movstd(input_data, window_len, 'omitnan');

%use three MAD from median criteria to detect outliers
is_outlier = ( abs(input_data-mov_median) > 3*mov_st_dev );

end

