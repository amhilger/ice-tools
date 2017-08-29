function [structure] = duplicate_scalar_fields(structure)
%Finds scalar fields (ie fields of length 1) in a structure, and duplicates
%those scalar fields to be as long as the longest field in structure.

%Assumes structure contains fields that are vectors or scalars. 
%Scalar fields are duplicated into column vector fields. 

L = max(structfun(@(x) length(x),structure));

fields = fieldnames(structure);
for i = 1:length(fields);
    if length(structure.(fields{i})) == 1
        structure.(fields{i}) = structure.(fields{i})*ones(L,1);
    end
end


end

