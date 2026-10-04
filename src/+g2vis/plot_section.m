function [ax,h,values] = plot_section(m,component,varargin)
% PLOT_SECTION Committed curvature / axial strain at actual integration points.
d=data(m); o=options(varargin{:}); ids=selection(d,o);
if ~ismember(lower(char(component)),{'curvature','strain'})
    error('G2Vis:Component','Use curvature or strain.');
end
quantity='Curvature'; if strcmpi(component,'strain'), quantity='Strain'; end
label=sprintf('%s [%s]',char(component),unit_label(d,quantity));
ax=prepare(d,o,label); h=gobjects(0); values=cell(size(d.elements));
cla(ax); hold(ax,'on'); axis(ax,'normal'); offset=0;
for i=ids
    e=d.elements{i};
    if ~isfield(e,'nsecs'), continue; end
    n=e.nsecs; start=7;
    if strcmpi(component,'strain'), start=7+n; end
    v=e.response(start:start+n-1); x=offset+(e.xip(:)+1)*e.length/2;
    h(end+1)=plot(ax,x,v,'-o','DisplayName',sprintf('Element %d',i),'LineWidth',o.LineWidth);
    values{i}=[x v(:)]; offset=offset+e.length;
    if o.Values, g2vis.label_values(ax,[x v(:)],v(:)); end
end
if isempty(h), error('G2Vis:Section','Selected elements have no fiber sections.'); end
xlabel(ax,['Distance along selected elements [' unit_label(d,'Length') ']'],'Interpreter','none');
ylabel(ax,label,'Interpreter','none');
legend(ax,h,'Location','best','Box','off','Color','none','TextColor',[.15 .15 .15]); grid(ax,'on');
end
