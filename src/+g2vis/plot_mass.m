function [ax,h]=plot_mass(m,varargin)
% PLOT_MASS Assembled mass diagonal and element mass/length; no double counting.
d=data(m); o=options(varargin{:}); ax=prepare(d,o,'Mass distribution');
g2vis.plot_model(d,'Axes',ax,'Supports',o.Supports,'ElementLabels',false,'NodeLabels',false,'Color',[.6 .6 .6]);
if ~isfield(d,'massDiagonal'), error('G2Vis:Mass','Snapshot does not contain masses.'); end
h=gobjects(0); color=[.20 .60 .35];
for i=1:size(d.xyz,1)
    mass=d.massDiagonal(i,:); if ~any(mass), continue; end
    xy=d.xyz(i,:); h(end+1)=plot(ax,xy(1),xy(2),'o','Color',color,'MarkerSize',10,'LineWidth',1.5);
    if o.Values
        label=sprintf(' m_x=%.4g, m_y=%.4g [%s]',mass(1:2),unit_label(d,'Mass'));
        if numel(mass)==3&&mass(3)~=0
            label=[label sprintf('\n J=%.4g [%s]',mass(3),unit_label(d,'RotationalInertia'))];
        end
        text(ax,xy(1),xy(2),label,'Color',color,'Interpreter','none','FontSize',8);
    end
end
for i=selection(d,o)
    if d.massPerLength(i)>0&&o.Values
        xy=mean(d.xyz(d.elements{i}.nodes,:),1);
        text(ax,xy(1),xy(2),sprintf(' mu=%.4g [%s] (%s)',d.massPerLength(i), ...
            unit_label(d,'MassPerLength'),d.massForm{i}),'Color',color,'Interpreter','none','FontSize',8);
    end
end
title(ax,[d.name ' | Assembled mass diagonal; distributed mu [' unit_label(d,'MassPerLength') ']'], ...
    'Interpreter','none'); axis(ax,'padded');
end
