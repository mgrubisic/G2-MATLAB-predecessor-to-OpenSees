function [ax,h,scale] = plot_defo(m,varargin)
% PLOT_DEFO Interpolated displaced shape with optional displacement colors.
d=data(m); o=options(varargin{:}); ids=selection(d,o);
[curves,scale]=g2vis.deformed_coordinates(d,varargin{:});
[realcurves,~]=g2vis.deformed_coordinates(d,'Scale',1,'Points',o.Points,'Elements',ids);
ax=prepare(d,o,sprintf('Deformation | |u| [%s] (scale %.4g [1])',unit_label(d,'Length'),scale)); h=gobjects(0);
for i=ids
    xy=d.xyz(d.elements{i}.nodes,:); c=curves{i};
    if o.Undeformed, plot(ax,xy(:,1),xy(:,2),'--','Color',[.65 .65 .65]); end
    h(end+1)=plot(ax,c(:,1),c(:,2),'Color',o.Color,'LineWidth',o.LineWidth);
    if o.Values
        r=linspace(0,1,o.Points)'; base=(1-r)*xy(1,:)+r*xy(2,:);
        u=realcurves{i}-base;
        g2vis.label_values(ax,c,sqrt(sum(u.^2,2)),o.Color);
    end
end
supports(ax,d,o);
axis(ax,'padded');
end
