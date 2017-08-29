function [heading] = calc_heading_1km(x, y, rdr_dist)
%calculates heading in degrees between 0 and 360

%%NB: when making any comparisons between headings, any difference should
%%be mod 360 to account for wraparound of northword pointing lines
assert(length(x) == length(y))
assert(length(x) == length(rdr_dist))

dist_thresh = 1000; %1 km

heading = zeros(length(x), 1);
for i = 1:length(x)
    first = find(rdr_dist <= rdr_dist(i) - 0.5*dist_thresh, 1, 'last');
    last  = find(rdr_dist >= rdr_dist(i) + 0.5*dist_thresh, 1, 'first');
    if isempty(first), first = 1;               end
    if isempty(last ), last  = length(x); end
%     if (x(last) - x(first)) < 0
%         %if westward bound, add 180 deg to heading
%         heading(i) = 180 + atand((y(last) - y(first))/(x(last) - x(first)));
%     else
    heading(i) = atand((y(last) - y(first))/(x(last) - x(first)));

end


end

