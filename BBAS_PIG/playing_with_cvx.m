n_ice = 1.7845;
%unit_fact = 22/299.8*2; %22 MHz sampling, speed of light, two-way travel

cvx_begin
    variable unit_fact %dcOffset(size(results.resHt))
    minimize ( norm( unit_fact*(results.iceThickness*n_ice + results.resHt) - results.botPickLoc) ) 
    subject to
        %dcOffset >= 0
cvx_end