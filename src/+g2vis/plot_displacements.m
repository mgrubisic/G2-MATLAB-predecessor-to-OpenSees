function [ax,h] = plot_displacements(m,varargin)
% PLOT_DISPLACEMENTS Continuous displacement colors on interpolated curves.
d=data(m); o=options(varargin{:}); ids=selection(d,o);
[curves,scale]=g2vis.deformed_coordinates(d,varargin{:});
[realcurves,~]=g2vis.deformed_coordinates(d,'Scale',1,'Points',o.Points,'Elements',ids);
quantity='Length'; if strcmpi(o.Component,'rotation'), quantity='Rotation'; end
label=sprintf('%s [%s]',char(o.Component),unit_label(d,quantity));
ax=prepare(d,o,sprintf('%s displacement (scale %.4g [1])',label,scale));
h=gobjects(0); allvalues=[];
r=linspace(0,1,o.Points)';
for i=ids
    xy=d.xyz(d.elements{i}.nodes,:); base=(1-r)*xy(1,:)+r*xy(2,:);
    du=realcurves{i}-base; c=curves{i};
    switch lower(char(o.Component))
        case 'magnitude', v=sqrt(sum(du.^2,2));
        case 'x', v=du(:,1);
        case 'y', v=du(:,2);
        case 'rotation'
            if size(d.u,2)<3, error('G2Vis:Component','Rotation requires three DOFs per node.'); end
            v=(1-r)*d.u(d.elements{i}.nodes(1),3)+r*d.u(d.elements{i}.nodes(2),3);
        otherwise, error('G2Vis:Component','Use magnitude, x, y or rotation.');
    end
    if o.Undeformed, plot(ax,xy(:,1),xy(:,2),'--','Color',[.7 .7 .7]); end
    h(end+1)=surface(ax,[c(:,1) c(:,1)],[c(:,2) c(:,2)],zeros(numel(v),2),[v v], ...
        'FaceColor','none','EdgeColor','interp','LineWidth',o.LineWidth);
    allvalues=[allvalues;v]; %#ok<AGROW>
    if o.Values, g2vis.label_values(ax,c,v,o.Color); end
end
view(ax,2); colormap(ax,parula(256)); cb=colorbar(ax); cb.Color=[.15 .15 .15]; cb.Label.String=label; cb.Label.Interpreter='none';
if ~isempty(allvalues)
    lo=min(allvalues); hi=max(allvalues);
    if hi==lo, hi=lo+max(1,abs(lo))*eps*16; end
    clim(ax,[lo hi]);
end
supports(ax,d,o); axis(ax,'padded');
end
