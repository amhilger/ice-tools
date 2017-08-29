function [ax2] = plot_one_overlay(ax2, plot_x, plot_y, plot_data)
%plots a transect of data -- if there are large gaps in the transect, then
%this should be called for each subtransect

if isempty(plot_data)
    return
end

plot_z = zeros(size(plot_x));

surface(ax2, [plot_x,plot_x],[plot_y,plot_y], ...
        [plot_z,plot_z],[plot_data,plot_data],...
        'facecol','no',...
        'edgecol','interp',...
        'linew',2);

end