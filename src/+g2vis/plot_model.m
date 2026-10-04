function [ax,h] = plot_model(m,varargin)
% PLOT_MODEL Geometry, node/element labels, supports, releases, local axes.
d=data(m); o=options(varargin{:}); ids=selection(d,o);
ax=prepare(d,o,'Model'); h=gobjects(0); s=span(d);
for i=ids
    e=d.elements{i}; xy=d.xyz(e.nodes,:);
    h(end+1)=plot(ax,xy(:,1),xy(:,2),'-','Color',o.Color,'LineWidth',o.LineWidth);
    mid=mean(xy,1);
    if o.ElementLabels
        label=mid+s*.035*[-e.tangent(2) e.tangent(1)];
        text(ax,label(1),label(2),sprintf('e%d (%d)',i,e.type),'Color',o.Color, ...
            'FontSize',9,'HorizontalAlignment','center');
    end
    if o.LocalAxes
        t=e.tangent; n=[-t(2) t(1)];
        quiver(ax,mid(1),mid(2),s*.07*t(1),s*.07*t(2),0,'Color',[.8 .2 .1]);
        quiver(ax,mid(1),mid(2),s*.07*n(1),s*.07*n(2),0,'Color',[.2 .6 .2]);
    end
    if isfield(e,'r') && e.r>0
        ends=find([ismember(e.r,[1 3]) ismember(e.r,[2 3])]);
        plot(ax,xy(ends,1),xy(ends,2),'o','MarkerFaceColor','w','Color',o.Color,'MarkerSize',8);
    end
end
plot(ax,d.xyz(:,1),d.xyz(:,2),'.','Color',[.15 .15 .15],'MarkerSize',12);
for i=1:size(d.xyz,1)
    xy=d.xyz(i,:);
    if o.NodeLabels, text(ax,xy(1)+s*.012,xy(2)+s*.012,num2str(i),'FontSize',9,'Color',[.15 .15 .15]); end
end
supports(ax,d,o);
axis(ax,'padded');
end
