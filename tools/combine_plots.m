function [] = combine_plots(ax1, ax2)

linkaxes([ax1, ax2])
ax2.Visible = 'off';
colormap(ax1, 'parula')
colormap(ax2, 'jet')
set([ax1, ax2], 'Position', [.15 .11 .7 .815]);

end