function [A_r] = downsample_data(A, M)
%downsamples data A of length N by a factor of M, resulting in output A_r
%of length floor(N/M) + 1. The function averages every M data points. The
%last point corresponds to a partial average of the last  the length of the
%input data are not divisible by M.

%this function will columnate data in a row format. In other words, the
%columns of the output will correspond to field, and the rows will
%correspond to entry

if size(A,1) < size(A,2) %if # rows < # cols
    A = A'; %assume data in field-row + entry-column format, 
    % and tranpose to field-column + entry-row format
end

if size(A,2) == 1 %if in column format
    %reshape into matrix having M rows, take mean along each column, and
    %transpose the result
    %A_r contains the first N*M entries, where N = floor(length(A)/M)
    A_r = mean( reshape( A(1:end-mod(length(A),M)),M,[] ), 1,'omitnan' )';
    if mod(length(A),M) ~= 0 %if data length is not multiple of M
        %the end of the data (of length < M) is averaged with itself and
        %concatenated with the data averaged above
        A_r = [A_r; mean(A(end-mod(length(A),M)+1:end), 'omitnan')];
    end
else %if in matrix format
    A_r = zeros(size(A));
    %recursively downsample each column
    for i = 1:size(A,2)
        A_r(:,i) = downsample_data(A(:,i), M);
    end
end

end

