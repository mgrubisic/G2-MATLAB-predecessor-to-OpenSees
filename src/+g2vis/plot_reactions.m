function [ax,h] = plot_reactions(m,varargin)
% PLOT_REACTIONS Constrained-DOF reactions including distributed loads.
d=data(m); o=options(varargin{:}); ax=prepare(d,o,'Reactions');
g2vis.plot_model(d,'Axes',ax,'NodeLabels',o.NodeLabels,'ElementLabels',false,'Supports',o.Supports,'Color',[.6 .6 .6]);
title(ax,sprintf('%s | Reactions: F [%s], M [%s]',d.name,unit_label(d,'Force'),unit_label(d,'Moment')),'Interpreter','none');
h=arrows(ax,d.xyz,d.reactions,span(d),o,d.units); axis(ax,'padded');
end
