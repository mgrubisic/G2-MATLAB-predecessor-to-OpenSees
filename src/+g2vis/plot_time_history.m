function [ax,h,values]=plot_time_history(m,node,direction,varargin)
% PLOT_TIME_HISTORY Physical time against displacement, velocity, acceleration,
% absoluteAcceleration, groundAcceleration, reaction or residualNorm.
if isa(m,'model'), history=visualHistory(m); else, history=m; end
if ~iscell(history)||isempty(history)||~all(cellfun(@(d) isfield(d,'time'),history))
    error('G2Vis:DynamicHistory','Expected a transient history.');
end
d=data(history{end}); o=options(varargin{:}); component=lower(char(o.Component));
if strcmp(component,'magnitude'), component='displacement'; end
validateattributes(node,{'numeric'},{'scalar','integer','positive','<=',size(d.u,1)});
validateattributes(direction,{'numeric'},{'scalar','integer','positive','<=',size(d.u,2)});
quantity='Length'; field='u'; label='Relative displacement';
switch component
    case {'displacement','u'}
        if direction==3, quantity='Rotation'; label='Relative rotation'; end
    case {'velocity','v'}
        field='velocity'; quantity='Velocity'; label='Relative velocity';
        if direction==3, quantity='AngularVelocity'; end
    case {'acceleration','a'}
        field='acceleration'; quantity='Acceleration'; label='Relative acceleration';
        if direction==3, quantity='AngularAcceleration'; end
    case 'absoluteacceleration'
        field='absoluteAcceleration'; quantity='Acceleration'; label='Absolute acceleration';
        if direction==3, quantity='AngularAcceleration'; end
    case 'groundacceleration'
        if direction>2, error('G2Vis:Component','Ground acceleration is translational.'); end
        field='groundAcceleration'; quantity='Acceleration'; label='Ground acceleration';
    case 'reaction'
        field='reactions'; quantity='Force'; label='Support reaction';
        if direction==3, quantity='Moment'; end
    case 'residualnorm'
        field='residualNorm'; quantity='Force'; label='Equilibrium residual norm';
    otherwise, error('G2Vis:Component','Unknown time-history component.');
end
values=zeros(numel(history),2);
for i=1:numel(history)
    s=history{i};
    if strcmp(field,'groundAcceleration'), value=s.(field)(direction);
    elseif strcmp(field,'residualNorm'), value=s.(field);
    else, value=s.(field)(node,direction); end
    values(i,:)=[s.time value];
end
ax=prepare(d,o,sprintf('%s | node %d, DOF %d',label,node,direction)); axis(ax,'normal');
h=plot(ax,values(:,1),values(:,2),'Color',o.Color,'LineWidth',o.LineWidth);
if o.Values, g2vis.label_values(ax,values,values(:,2),o.Color); end
axis(ax,'padded');
xlabel(ax,['Time [' unit_label(d,'Time') ']'],'Interpreter','none');
ylabel(ax,[label ' [' unit_label(d,quantity) ']'],'Interpreter','none');
if strcmp(component,'residualnorm')&&size(d.u,2)==3
    ylabel(ax,sprintf('Residual norm [%s, %s components]', ...
        unit_label(d,'Force'),unit_label(d,'Moment')),'Interpreter','none');
end
end
