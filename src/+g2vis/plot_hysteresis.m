function [ax,h,values]=plot_hysteresis(m,node,direction,varargin)
% PLOT_HYSTERESIS Nodal restoring force against displacement through time.
if isa(m,'model'), history=visualHistory(m); else, history=m; end
if ~iscell(history)||isempty(history), error('G2Vis:History','Expected snapshot history.'); end
d=data(history{end}); o=options(varargin{:});
validateattributes(node,{'numeric'},{'scalar','integer','positive','<=',size(d.u,1)});
validateattributes(direction,{'numeric'},{'scalar','integer','positive','<=',size(d.u,2)});
values=zeros(numel(history),2);
for i=1:numel(history), values(i,:)=[history{i}.u(node,direction) history{i}.restoringForces(node,direction)]; end
xunit='Length'; yunit='Force'; if direction==3, xunit='Rotation'; yunit='Moment'; end
ax=prepare(d,o,sprintf('Restoring response | node %d, DOF %d',node,direction)); axis(ax,'normal');
h=plot(ax,values(:,1),values(:,2),'Color',o.Color,'LineWidth',o.LineWidth);
if o.Values, g2vis.label_values(ax,values,values(:,2),o.Color); end
axis(ax,'padded');
xlabel(ax,['Relative displacement [' unit_label(d,xunit) ']'],'Interpreter','none');
ylabel(ax,['Restoring force / moment [' unit_label(d,yunit) ']'],'Interpreter','none');
end
