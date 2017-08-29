function [attrib_struct] = attrib_array_to_struct(attrib_array)
%converts array of attributes to structure

attrib_struct.priNum = attrib_array(1,:);
attrib_struct.lat = attrib_array(2,:);
attrib_struct.long = attrib_array(3,:);
attrib_struct.clearance = attrib_array(4,:);
attrib_struct.surf_elev = attrib_array(5,:);
attrib_struct.distance = attrib_array(6,:);
attrib_struct.velo = attrib_array(7,:);




end

