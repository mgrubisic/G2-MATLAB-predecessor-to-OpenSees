function [ax,h,values] = plot_history(m,node,direction,varargin)
% PLOT_HISTORY Load factor against a physical node DOF, not equation numbers.
if isa(m,'model'), history=visualHistory(m); else, history=m; end
if ~iscell(history)||isempty(history), error('G2Vis:History','Expected a model or snapshot history.'); end
if isfield(history{end},'time')
    [ax,h,values]=g2vis.plot_time_history(history,node,direction,varargin{:}); return;
end
d=data(history{end}); o=options(varargin{:});
validateattributes(node,{'numeric'},{'scalar','integer','>=',1,'<=',size(d.u,1)});
validateattributes(direction,{'numeric'},{'scalar','integer','>=',1,'<=',size(d.u,2)});
values=zeros(numel(history),2);
for i=1:numel(history), values(i,:)=[history{i}.u(node,direction) history{i}.lambda]; end
quantity='Length'; if direction==3, quantity='Rotation'; end
ax=prepare(d,o,sprintf('Node %d, DOF %d [%s]',node,direction,unit_label(d,quantity))); axis(ax,'normal');
h=plot(ax,values(:,1),values(:,2),'-o','Color',o.Color,'LineWidth',o.LineWidth);
if o.Values, g2vis.label_values(ax,values,values(:,2),o.Color); end
xlabel(ax,['Displacement / rotation [' unit_label(d,quantity) ']'],'Interpreter','none');
ylabel(ax,'Load factor [1]','Interpreter','none');
end
