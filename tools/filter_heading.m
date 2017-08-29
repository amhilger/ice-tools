function [pass_bool] = filter_heading(heading, rdr_dist)
%outputs a boolean array indicating whether each pik passes a filter
%heading criterion. Piks where the heading has changed more than two
%degrees between piks 1 km apart.

%heading is in degrees, with the headings ranging from -90 to 90 degrees.
%This is so that parallel flights have the same "heading" even though
%they're actually 180 degrees off from each other. If the headings follow a
%different convention, wraparound won't be handled correctly

dist_thresh = 1000; %1 km
heading_thresh = 2; %deg

%we'll use an approximation here based on the average pik spacing
assert(length(heading) == length(rdr_dist))

%meters between piks
pik_spacing = (rdr_dist(end)-rdr_dist(1))/length(heading);
pik_window = ceil(dist_thresh/pik_spacing);

pass_bool = zeros(length(heading),1);
for i = 1:length(heading)
    first = max(1,i-pik_window);
    last  = min(i+pik_window, length(heading));
    pass_bool(i) = ~any(heading(first:last) - heading(i) >= heading_thresh);
end

