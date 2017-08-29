function [ice_thick] = bedmap_thick(lat_or_x, lon_or_y)

%gives ice thickness from BEDMAP2 interpolated along the (lat, lon) or
%(x,y) given by the inputs. Each should be a vector and would typically
%give the positions of a transect or portion thereof.
orig_dir = pwd;
cd ../BEDMAP

%this assumes either both are lat, lon or both are ps xy coordinates.
%Doesn't havndle mixed case
if islatlon(lat_or_x, lon_or_y)
    [x,y] = ll2ps(lat_or_x, lon_or_y);
else 
    x = lat_or_x; y = lon_or_y;
end

%get the thickness grid from BEDMAP for the area corresponding to the transect's
%easts and norths
[bmx, bmy, bmthick] = ... %pad with 5 km extra to ensure good interp
    bedmap2_data('thick',x, y, 5,'xy');
%interpolate the along-transect thickness from the gridded BEDMAP
%thickensses
ice_thick = interp2(bmx, bmy, bmthick, ...
                    x, y, 'linear');
                
cd(orig_dir)