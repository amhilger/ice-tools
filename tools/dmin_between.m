function [traceA, traceB, dmin] = dmin_between(A_candidates, ...
                                             B_candidates, ...
                                             xA, yA, xB, yB)
%enumerates all candidate pairs, calculates distance between each pair, and
%returns pair having minimal distance. A_candidates and B_candidates are
%nx1 vectors indicating the indices of candidates in two transect segments.
%xA and xB are the eastings of the corresponding transect segments, and yA
%and yB are the northings of the corresponding transect segments

%traceA and traceB are indexed with respect to transect segment, so
%translation to full transect indices is necessary

%quick return for 1-d case
if length(A_candidates) == 1 && length(B_candidates) == 1
    traceA = A_candidates; traceB = B_candidates;
    dmin = hypot(xA(traceA)-xB(traceB),yA(traceA)-yB(traceB)); return
end

%default return for when either or both candidate lists are empty
if isempty(A_candidates) || isempty(B_candidates)
    traceA = []; traceB = []; dmin = Inf; return
end


%enumerate every combination between the A candidates and the B candidates
[Aindices, Bindices] = meshgrid(A_candidates, B_candidates);
%columnate each enumeration and combine into an nx2 array where each row
%corresponds to one of the enumerated pairs
pair_indices = [reshape(Aindices, [], 1) reshape(Bindices, [], 1)];

%compute distance for each pair
dist = hypot(xA(pair_indices(:,1)) - xB(pair_indices(:,2)), ...
             yA(pair_indices(:,1)) - yB(pair_indices(:,2)));


%compute minimum distance
[dmin, pair] = min(dist);

if dmin == Inf %if no candidates found
    traceA = []; 
    traceB = [];
else
    %pair gives row of pair_indices containing index in
    %A_candidates/B_candidates 
    % of minimal distance traceA and traceB
    traceA = pair_indices(pair,1);
    traceB = pair_indices(pair,2);
end


end