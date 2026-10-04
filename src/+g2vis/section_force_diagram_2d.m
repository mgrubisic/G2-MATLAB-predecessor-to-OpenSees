function [ax,h,scale,values] = section_force_diagram_2d(m,component,varargin)
% SECTION_FORCE_DIAGRAM_2D Filled N/V/M diagrams in each local y direction.
% M uses the opposite graphical direction; numerical values keep their signs.
% Invert=true mirrors M relative to that default; N/V are unaffected.
d=data(m); o=options(varargin{:}); ids=selection(d,o);
c=find(strcmpi(char(component),{'N','V','M'}));
if isempty(c), error('G2Vis:Component','Force component must be N, V or M.'); end
values=cell(1,numel(d.elements)); xx=values; peak=0;
for i=ids
    [f,xx{i}]=g2vis.section_force_distribution_2d(d,i,o.Points);
    values{i}=f(:,c); peak=max(peak,max(abs(values{i})));
end
scale=o.Scale;
if isempty(scale), scale=0; if peak>0, scale=o.Ratio*span(d)/peak; end, end
ax=prepare(d,o,[upper(char(component)) ' diagram']); h=gobjects(0);
allvalues=vertcat(values{ids});
quantity='Force'; if c==3, quantity='Moment'; end
title(ax,sprintf('%s | %s [%s] [%.4g, %.4g]',d.name,upper(char(component)),unit_label(d,quantity),min(allvalues),max(allvalues)), ...
    'Interpreter','none','Color',[.1 .1 .1]);
for i=ids
    e=d.elements{i}; xy=d.xyz(e.nodes,:);
    t=diff(xy)/norm(diff(xy)); n=[-t(2) t(1)];
    r=xx{i}/e.length;
    base=(1-r)*xy(1,:)+r*xy(2,:);
    direction=1;
    if c==3, direction=-1; if o.Invert, direction=1; end, end
    curve=base+direction*scale*values{i}*n;
    plot(ax,base(:,1),base(:,2),'-','Color',[.6 .6 .6]);
    if o.Fill
        patch(ax,[base(1,1);curve(:,1);base(end,1)],[base(1,2);curve(:,2);base(end,2)], ...
            o.Color,'FaceAlpha',.18,'EdgeColor','none');
    end
    h(end+1)=plot(ax,curve(:,1),curve(:,2),'Color',o.Color,'LineWidth',o.LineWidth);
    plot(ax,[base(1,1) curve(1,1) NaN base(end,1) curve(end,1)], ...
        [base(1,2) curve(1,2) NaN base(end,2) curve(end,2)],'Color',o.Color);
    if o.Values
        g2vis.label_values(ax,curve,values{i},o.Color);
    end
end
supports(ax,d,o);
axis(ax,'padded');
end
