function [out_indexes, fit_coeff] = linear_segmentize(easts, norths, ...
                                             error_threshold, min_seg_len)
%turns a set of x,y coordinates into a set of line segments. easts and
%norths are expected to correspond to a reasonably smooth curve that an
%airplane could fly 

%%basically, the transect is fit with lines from beginning to end. As
%%a segment grows, we do a linear fit and calculate worst error in the norths direction,
%%and ensure this worst error is below the error threshold. This is the worst case error when the line is sloped in
%%the east direction. For other line slope direcitons, the actual error
%%will be less than the threshold. The segment endpoint is determined using
%%a binary search to find the maximum segment length while keeping the
%%error below the threshold.

%%if this function throws rank deficient regression warnings, check that
%%easts and norths correspond to moving data. If easts and norths contain a
%%sequence of stationary points, this will yield a bad regression

N = length(easts);
    

start_indexes = zeros(ceil(length(easts)/min_seg_len),1);
end_indexes   = zeros(size(start_indexes));
fit_coeff     = zeros(length(start_indexes),2);
save_idx = 1;

first = 1;

while first < N
    max_good = min(first + ceil(min_seg_len/2), N-1);
    min_bad = Inf;
    %use a binary search, where the success criteria is whether the error
    %of the linear approximation is acceptable
    while min_bad - max_good > 1 && max_good < N
        if min_bad == Inf %if we haven't found a bad fit yet
            last = min(first + (max_good-first)*2+1, N); %try a bigger fit
        else %once we find a bad fit, go halfway between them
            assert(min_bad > max_good)
            last = floor((min_bad + max_good)/2);
        end
        %do the regression
        
        is_mono_easts = all(diff(easts(first:last)) > 0) || ...
                        all(diff(easts(first:last)) < 0);
        is_mono_norths = all(diff(norths(first:last)) > 0) || ...
                         all(diff(norths(first:last)) < 0);
        if ~is_mono_easts && ~is_mono_norths %if both aren't monotonic, fit has failed
            min_bad = last; continue %no need to check regression
        end
                   
        b = regress(norths(first:last), ...
                        [ones(length(first:last),1) ...
                         easts(first:last)]);
        %compute the error
        approx_n = b(2)*easts(first:last) + b(1);
        approx_err = max(abs(approx_n - norths(first:last)));
        if approx_err <= error_threshold
            max_good = last; %we have a successful fit
        else
            min_bad = last; %we have a failed fit
        end
    end
    %once min_bad and max_good converge (or when last == len(transect)), we
    %save the indices and regression parameters
    start_indexes(save_idx) = first;
    end_indexes(save_idx) = last;
    b = regress(norths(first:last), ...
                        [ones(length(first:last),1) ...
                         easts(first:last)]);
    fit_coeff(save_idx,:) = b';
    save_idx = save_idx + 1;
    %disp(['Fitted ' num2str(first) ' to ' num2str(last)])
    %on we go to the next segment
    first = last + 1;
end

%clean the trailing zeros from output vectors
start_indexes = start_indexes(start_indexes ~= 0);
end_indexes = end_indexes(end_indexes ~= 0);
fit_coeff = fit_coeff(start_indexes ~= 0, :);

%disp(['Fitted into ' num2str(length(start_indexes)) ' segments'])

%handles the case where last segment fits so that N-1 works but N doesn't.
%In this case, we through N into last segment and accept being slightly
%over error threshold.
if end_indexes(end) == N-1
    end_indexes(end) = N;
end  
assert(end_indexes(end) == N)

out_indexes = [start_indexes end_indexes];
