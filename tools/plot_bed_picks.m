function [] = plot_bed_picks(pick_sample, pick_pri, pick_line_color)
%call this function only after plotSAR result

%If color not specified, default to black
if ~exist('pick_line_color', 'var')
    pick_line_color = 'k';
end

hold on
line(pick_pri, pick_sample, 'Color', pick_line_color)

hold off


end

