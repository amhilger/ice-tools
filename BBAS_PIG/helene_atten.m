%This file is 
load attenuation.mat
%This file is attenuation in dB/km. x_m and y_m are in meters
load meanattenuation.mat

%surface(x_m, y_m, meanattenuation_grid)

m = size(attenuation_grid,1); 
n = size(attenuation_grid,2);

gx = conv2([1 0 -1; 2 0 -2; 1 0 -1], attenuation_grid); 
gx = gx(3:m+2, 3:n+2);
gy = conv2([1 2 1; 0 0 0; -1 -2 -1], attenuation_grid);
gy = gy(3:m+2, 3:n+2);
Gmag = sqrt(gx.^2 + gy.^2);

surface(x_m, y_m, Gmag)


