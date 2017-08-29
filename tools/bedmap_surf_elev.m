function [surf_elev] = bedmap_surf_elev(lat_or_x, lon_or_y)

%gives surface elevation in m (WGS84) from BEDMAP2 interpolated along the
%(lat, lon) or (x,y) given by the inputs. Each should be a vector and would
%typically give the positions of a transect or portion thereof.
orig_dir = pwd;
cd ../BEDMAP

%this assumes either both are (lat, lon) or both are ps (x, y) coordinates.
%Doesn't havndle mixed case
if islatlon(lat_or_x, lon_or_y)
    [x,y] = ll2ps(lat_or_x, lon_or_y);
else 
    x = lat_or_x; y = lon_or_y;
end

%get the value grid from BEDMAP for the area corresponding to the transect's
%easts and norths
[bmx, bmy, bm_surf] = ... %pad with 5 km extra to ensure good interp
    bedmap2_data('surfacew',x, y, 5,'xy');
%interpolate the along-transect value from the gridded BEDMAP
%values
surf_elev = interp2(bmx, bmy, bm_surf, ...
                    x, y, 'linear');
                
cd(orig_dir)