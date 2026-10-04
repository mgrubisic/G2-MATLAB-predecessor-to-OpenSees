function f=dynamic_dashboard(m,node,direction)
% DYNAMIC_DASHBOARD Peak shape, displacement, velocity, acceleration, input and hysteresis.
if isa(m,'model'), history=visualHistory(m); else, history=m; end
if ~iscell(history)||isempty(history)||~isfield(history{end},'time')
    error('G2Vis:DynamicHistory','Expected transient history.');
end
peak=cellfun(@(d) max(vecnorm(d.u(:,1:2),2,2)),history); [~,i]=max(peak);
f=figure('Name',['G2 dynamics | ' history{end}.name],'NumberTitle','off','Color','w','Position',[80 80 1350 800]);
tl=tiledlayout(f,2,3,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl); g2vis.plot_defo(history{i},'Axes',ax);
title(ax,sprintf('Peak shape | t=%.4g [%s]',history{i}.time,history{i}.units.Time),'Interpreter','none');
for component={'displacement','velocity','absoluteAcceleration','groundAcceleration'}
    ax=nexttile(tl); g2vis.plot_time_history(history,node,direction,'Axes',ax,'Component',component{1});
    title(ax,get(get(ax,'YLabel'),'String'),'Interpreter','none');
end
ax=nexttile(tl); g2vis.plot_hysteresis(history,node,direction,'Axes',ax); title(ax,'Restoring force vs. displacement');
title(tl,[history{end}.name ' | nonlinear transient response'],'Interpreter','none','Color',[.15 .15 .15]);
end
