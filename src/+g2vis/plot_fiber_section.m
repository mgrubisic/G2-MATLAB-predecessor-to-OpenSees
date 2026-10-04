function [ax,h,values] = plot_fiber_section(m,element,section,varargin)
% PLOT_FIBER_SECTION Exact G2 fiber strips colored by committed stress/strain.
% Component: stress (default), strain, or material (yield state code).
d=data(m); o=options(varargin{:});
validateattributes(element,{'numeric'},{'scalar','integer','>=',1,'<=',numel(d.elements)});
e=d.elements{element};
if ~isfield(e,'secs'), error('G2Vis:Section','Element %d has no fiber section.',element); end
validateattributes(section,{'numeric'},{'scalar','integer','>=',1,'<=',e.nsecs});
sec=struct(e.secs(section)); fibers=sec.fibers;
ax=prepare(d,o,sprintf('Element %d / section %d',element,section));
switch lower(char(o.Component))
    case {'magnitude','stress'}, component='stress'; quantity='Stress';
    case 'strain', component='strain'; quantity='Strain';
    case 'material', component='material state'; quantity='MaterialState';
    otherwise, error('G2Vis:Component','Use stress, strain or material.');
end
label=sprintf('%s [%s]',component,unit_label(d,quantity));
title(ax,sprintf('%s | Element %d / section %d | %s',d.name,element,section,label),'Interpreter','none');
cla(ax); hold(ax,'on'); h=gobjects(0); values=zeros(numel(fibers),3);
for j=1:numel(fibers)
    fiber=fibers(j); y=-fiber.as(1);
    % Original section dimensions are retained in the element's material data.
    dim=e.sectionDimensions;
    if abs(y)>dim(1)/2-dim(3), width=dim(2); else, width=dim(4); end
    height=fiber.ar/width;
    switch lower(char(o.Component))
        case {'magnitude','stress'}, v=fiber.pr.sc;
        case 'strain', v=fiber.pr.es;
        case 'material', v=fiber.pr.cd;
        otherwise, error('G2Vis:Component','Use stress, strain or material.');
    end
    h(end+1)=patch(ax,[-width/2 width/2 width/2 -width/2], ...
        y+[-height/2 -height/2 height/2 height/2],v,'EdgeColor',[.25 .25 .25]);
    values(j,:)=[y fiber.ar v];
    if o.Values
        text(ax,0,y,sprintf('%.4g',v),'FontSize',8,'HorizontalAlignment','center', ...
            'Color',[.15 .15 .15],'Tag','G2VisValue','HandleVisibility','off');
    end
end
axis(ax,'equal'); axis(ax,'padded'); colormap(ax,parula(256)); cb=colorbar(ax);
cb.Color=[.15 .15 .15];
cb.Label.String=label; cb.Label.Interpreter='none';
xlabel(ax,['Section width [' unit_label(d,'Length') ']'],'Interpreter','none');
ylabel(ax,['Section depth (local y) [' unit_label(d,'Length') ']'],'Interpreter','none');
end
