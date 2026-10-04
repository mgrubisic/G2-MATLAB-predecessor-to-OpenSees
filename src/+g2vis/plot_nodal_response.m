function [ax,h]=plot_nodal_response(m,quantity,varargin)
% PLOT_NODAL_RESPONSE Nodal velocity/acceleration colors on displaced geometry.
% Fields between nodes are linearly interpolated, not recovered continuum fields.
d=data(m); o=options(varargin{:}); quantity=validatestring(quantity, ...
    {'velocity','acceleration','absoluteAcceleration'});
if ~isfield(d,quantity), error('G2Vis:DynamicHistory','Response requires a transient snapshot.'); end
unit='Acceleration'; if strcmp(quantity,'velocity'), unit='Velocity'; end
direction=[];
switch lower(char(o.Component))
    case 'magnitude'
    case 'x', direction=1;
    case 'y', direction=2;
    case 'rotation'
        if size(d.u,2)<3, error('G2Vis:Component','Rotation requires three DOFs.'); end
        direction=3; unit='AngularAcceleration';
        if strcmp(quantity,'velocity'), unit='AngularVelocity'; end
    otherwise, error('G2Vis:Component','Use magnitude, x, y or rotation.');
end
label=sprintf('%s %s [%s]',quantity,char(o.Component),unit_label(d,unit));
ax=prepare(d,o,label); [curves,~]=g2vis.deformed_coordinates(d,varargin{:});
r=linspace(0,1,o.Points)'; h=gobjects(0); allvalues=[];
for i=selection(d,o)
    nodes=d.elements{i}.nodes; q=d.(quantity)(nodes,:);
    q=(1-r)*q(1,:)+r*q(2,:);
    if isempty(direction), values=sqrt(sum(q(:,1:2).^2,2)); else, values=q(:,direction); end
    c=curves{i};
    h(end+1)=surface(ax,[c(:,1) c(:,1)],[c(:,2) c(:,2)],zeros(numel(r),2),[values values], ...
        'FaceColor','none','EdgeColor','interp','LineWidth',o.LineWidth);
    allvalues=[allvalues;values]; %#ok<AGROW>
    if o.Values, g2vis.label_values(ax,c,values,o.Color); end
end
view(ax,2); colormap(ax,parula(256)); cb=colorbar(ax); cb.Color=[.15 .15 .15];
cb.Label.String=label; cb.Label.Interpreter='none';
if ~isempty(allvalues)
    lo=min(allvalues); hi=max(allvalues); if hi==lo, hi=lo+max(1,abs(lo))*eps*16; end
    clim(ax,[lo hi]);
end
supports(ax,d,o); axis(ax,'padded');
end
