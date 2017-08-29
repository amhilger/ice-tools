function matches = deduplicate(matches, dist_thresh, transect_names)
%deplicates a list of matches. A match is considered a candidate duplicate
%if it within dist_thresh (in meters) of another match, both matches being
%xovers between the same transect pair. The match having the lowest xover
%among a set of candidate matches is retained, and the others are removed.


is_duplicate = zeros(size(matches.dist));
for i = 1:length(transect_names)
    %iterate over all i,j combinations
    for j = (i+1):length(transect_names)
        %find row numbers of all matches between transects i and j. 
        dup_rows = find(any(matches.ts == i,2) & any(matches.ts == j,2));
        if ~isempty(dup_rows)
            %enumerate all permutations between identified rows
            [pairA, pairB] = meshgrid(dup_rows,dup_rows);
            %reshape into a list where each column is one member of the
            %pair
            pairs = [reshape(pairA,[],1) reshape(pairB,[],1)];
            %remove duplicate pairs
            pairs = pairs(pairs(:,2) > pairs(:,1) ,:);
            %compute distance between each pair
            dist = hypot(diff(matches.easts(pairs),1,2), ...
                         diff(matches.norths(pairs),1,2));
            %filter to pairs closer than distance threshold
            close_pairs = pairs(dist <= dist_thresh,:);
            %indicates which column has the larger xover distance
            far_match = floor(1.5 + sign(diff(matches.dist(close_pairs'),1,1))/2);
            %set is_duplicate to true for the duplicate match that has
            %the farther x_over distance
            for k = 1:length(far_match)
                is_duplicate(close_pairs(k,far_match(k))) = 1;
            end
            assert(size(close_pairs,1) == length(far_match))
        end
    end
end
disp(['Removing ' num2str(sum(is_duplicate)) ' duplicates from ' ...
    num2str(length(matches.dist)) ' matches'])
%remove the duplicates 
matches = structfun(@(field) field(~is_duplicate,:), matches, ...
                    'UniformOutput', false);

end
    