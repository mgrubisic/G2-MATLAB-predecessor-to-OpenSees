function [ax,h] = plot_load(m,varargin)
% PLOT_LOAD Applied nodal forces/moments and uniform element loads.
% Unsolved models show the reference load at lambda=1.
d=data(m); o=options(varargin{:}); ax=prepare(d,o,'Loads');
g2vis.plot_model(d,'Axes',ax,'NodeLabels',o.NodeLabels,'ElementLabels',false,'Supports',o.Supports,'Color',[.6 .6 .6]);
title(ax,sprintf('%s | Loads: F [%s], M [%s], w [%s]',d.name, ...
    unit_label(d,'Force'),unit_label(d,'Moment'),unit_label(d,'DistributedLoad')),'Interpreter','none');
lambda=d.lambda; if ~d.solved, lambda=1; end
forces=lambda*d.loads;
if isfield(d,'analysis')&&strcmp(d.analysis,'transient')
    forces=d.applied;
    title(ax,sprintf('%s | Effective loads incl. ground inertia: F [%s], M [%s]', ...
        d.name,unit_label(d,'Force'),unit_label(d,'Moment')),'Interpreter','none');
end
h=arrows(ax,d.xyz,forces,span(d),o,d.units);
ids=selection(d,o); centers=[]; forces=[];
for i=ids
    e=d.elements{i}; w=e.uniform;
    if ~d.solved && isfield(e,'q')
        % Before solution compute the same effective loads as element state.
        w=[0 -e.q(1)]; if e.type==2, w(1)=2*e.q(2); end
    end
    if any(w~=0)
        xy=d.xyz(e.nodes,:); t=e.tangent; n=[-t(2) t(1)];
        r=linspace(.1,.9,5)'; c=(1-r)*xy(1,:)+r*xy(2,:);
        f=w(1)*t+w(2)*n;
        centers=[centers;c]; forces=[forces;repmat(f,5,1)]; %#ok<AGROW>
        mid=mean(xy,1);
        if o.Values, text(ax,mid(1),mid(2),sprintf(' w=[%.4g, %.4g] %s',w,unit_label(d,'DistributedLoad')),'FontSize',8,'Color',o.Color,'Interpreter','none'); end
    end
end
if ~isempty(centers)
    labels=o; labels.Values=false;
    h=[h arrows(ax,centers,forces,span(d),labels,d.units)];
end
axis(ax,'padded');
end
