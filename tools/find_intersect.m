function [traceA, traceB, x_int, y_int] = ...
    find_intersect(coeffA, coeffB, x_edgeA, x_edgeB, y_edgeA, y_edgeB)
%finds the intersection of two transect lines. Returns the index of the
%trace corresponding to the closest x (easting) and y (northing) points. 
%If the lines do not intersect, then traceA and traceB return as empty arrays

%returning a NaN trace signifies that no x or y edge was available to
%check, so a more exhaustive check must be done

%%lats and longs should be column matrices

%if slopes differ by more than 0.01, skip (to make up 15 km grid spacing
%over 400 km survey width, need slope difference of 0.0375. Using tangents
%normalizes the orientation such that one slope is zero and the other slope
%is given by the left hand side of the logical expression
if abs(tan(atan(coeffA(2)) - atan(coeffB(2)))) < 0.01 
    traceA = []; traceB = []; return
end

%find intersection
x_int = (coeffB(1) - coeffA(1))/(coeffA(2) - coeffB(2));
y_int = coeffA(2)*x_int + coeffA(1);
%check that y intersections match
assert(norm((coeffA(2)-coeffB(2))*x_int + coeffA(1) - coeffB(1)) < 1e-3) 


%select between east and north edges for A
if isempty(x_edgeA)
    if isempty(y_edgeA)
        edgeA = [];
    else
        edgeA = y_edgeA; queryA = y_int;
    end
elseif isempty(y_edgeA)
    edgeA = x_edgeA; queryA = x_int;
else
    if abs(x_edgeA(2) - x_edgeA(end-1)) > abs(y_edgeA(2) - y_edgeA(end-1))
        %if xA is more spreadout than yA, then use xA
        edgeA = x_edgeA; queryA = x_int;
    else
        edgeA = y_edgeA; queryA = y_int;
    end
end
%select between east and north edges for B
if isempty(x_edgeB)
    if isempty(y_edgeB)
        edgeB = []; 
    else
        edgeB = y_edgeB; queryB = y_int;
    end
elseif isempty(y_edgeB)
    edgeB = x_edgeB; queryB = x_int;
else
    if abs(x_edgeB(2) - x_edgeB(end-1)) > abs(y_edgeB(2) - y_edgeB(end-1))
        %if xB is more spreadout than yB, then use xB
        edgeB = x_edgeB; queryB = x_int;
    else
        edgeB = y_edgeB; queryB = y_int;
    end
end



%Use discretize to find indices of closest points on transect segments A
%and B
if ~isempty(edgeA)
    if edgeA(end) > edgeA(1) %if in ascending order
        traceA = discretize(queryA, edgeA);
    else %if in descending order
        traceA = length(edgeA) - discretize(queryA, edgeA(end:-1:1));
        %We have to convert the index from the reversed edges array to the
        %index in the x/y vector. NB: edgeA is one longer than corresponding
        %x/y vector, so we have implicitly subtracted 1 here
    end
else
    traceA = NaN;
end
if ~isempty(edgeB)
    if edgeB(end) > edgeB(1) %if in ascending order 
        traceB = discretize(queryB, edgeB); 
    else
        traceB = length(edgeB) - discretize(queryB, edgeB(end:-1:1));
        %We have to convert the index from the reversed edges array to the
        %index in the x/y vector. NB: edgeA is one longer than corresponding
        %x/y vector, so we have implicitly subtracted 1 here
    end
else
    traceB = NaN;
end

