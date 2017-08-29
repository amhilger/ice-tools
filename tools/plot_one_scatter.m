function [ax2] = plot_one_scatter(ax2, plot_x, plot_y, plot_data)
%plots a transect of data -- if there are large gaps in the transect, then
%this should be called for each subtransect

if isempty(plot_data)
    return
end

scatter(plot_x, plot_y, 5*ones(size(plot_x)), plot_data, 'filled');

end