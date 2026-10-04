function f = dashboard(m,varargin)
% DASHBOARD Six-panel overview; returns a standard exportable MATLAB figure.
d=data(m); o=options(varargin{:});
f=figure('Name',['G2 results | ' d.name],'NumberTitle','off','Color','w','Position',[80 80 1350 800]);
tl=tiledlayout(f,2,3,'TileSpacing','compact','Padding','compact');
g2vis.plot_model(d,'Axes',nexttile(tl),'LocalAxes',o.LocalAxes,'Supports',o.Supports);
g2vis.plot_load(d,'Axes',nexttile(tl),'Values',o.Values,'Supports',o.Supports);
g2vis.plot_displacements(d,'Axes',nexttile(tl),'Ratio',o.Ratio,'Component',o.Component,'Values',o.Values,'Supports',o.Supports);
for c={'N','V','M'}
    g2vis.section_force_diagram_2d(d,c{1},'Axes',nexttile(tl),'Ratio',o.Ratio,'Values',o.Values,'Supports',o.Supports,'Invert',o.Invert);
end
% The shared heading names the model; short tile headings avoid unit-label overlap.
for ax=findall(f,'Type','axes')'
    label=get(get(ax,'Title'),'String');
    prefix=[d.name ' | '];
    if ischar(label)&&startsWith(label,prefix)
        title(ax,label(numel(prefix)+1:end),'Interpreter','none');
    end
end
stateLabel=sprintf('lambda = %.5g [1]',d.lambda);
if isfield(d,'time'), stateLabel=sprintf('t = %.5g [%s]',d.time,unit_label(d,'Time')); end
title(tl,[d.name ' | ' stateLabel],'Interpreter','none','Color',[.1 .1 .1]);
end
