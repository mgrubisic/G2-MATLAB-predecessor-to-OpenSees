function ziemian_elcentro_plots(history,s)
% ZIEMIAN_ELCENTRO_PLOTS Plot a live or saved complete earthquake history.
% load('results/ziemian_elcentro_results.mat');
% ziemian_elcentro_plots(dynamicResult.History,earthquakeSummary)
responseFigure(s);
[~,peakStep]=max(abs(s.RoofDisplacement));
g2vis.dashboard(history{peakStep});
g2vis.dynamic_dashboard(history,9,1);
g2vis.plot_mass(history{end});
g2vis.plot_time_history(history,9,1,'Component','absoluteAcceleration');
g2vis.plot_fiber_section(history{s.CriticalStep},s.CriticalElement,s.CriticalSection,'Component','stress');
g2vis.plot_fiber_section(history{s.CriticalStep},s.CriticalElement,s.CriticalSection,'Component','material');
g2vis.plot_section(history{s.CriticalStep},'curvature','Elements',s.CriticalElement);
g2vis.viewer(history);
g2vis.anim_defo(history(1:10:end),'Delay',.02);
end
function responseFigure(s)
f=figure('Name','Ziemian | ElCentro earthquake response','Position',[80 80 1350 950]); g2vis.style_light(f);
tl=tiledlayout(f,3,2,'TileSpacing','compact','Padding','compact');
title(tl,'Ziemian | ElCentro | displacements relative to gravity equilibrium');
ax=nexttile; plot(ax,s.RecordTime,s.RecordG,'LineWidth',1); grid(ax,'on');
xlabel(ax,'Time [s]'); ylabel(ax,'Ground acceleration [g]'); title(ax,'ElCentro input');
g2vis.label_values(ax,[s.RecordTime s.RecordG],s.RecordG);
ax=nexttile; plot(ax,s.Time,s.RoofDisplacement,'LineWidth',1); grid(ax,'on');
xlabel(ax,'Time [s]'); ylabel(ax,'Roof displacement [m]');
g2vis.label_values(ax,[s.Time s.RoofDisplacement],s.RoofDisplacement);
ax=nexttile; plot(ax,s.Time,s.BaseShear,'LineWidth',1); grid(ax,'on');
xlabel(ax,'Time [s]'); ylabel(ax,'Base shear [kN]');
g2vis.label_values(ax,[s.Time s.BaseShear],s.BaseShear);
ax=nexttile; curves=plot(ax,s.Time,100*s.StoryDriftRatio,'LineWidth',1); grid(ax,'on');
xlabel(ax,'Time [s]'); ylabel(ax,'Maximum absolute story drift [%]');
legend(ax,{'Story 1 [%]','Story 2 [%]'},'Box','off','Color','none');
for j=1:2, g2vis.label_values(ax,[s.Time 100*s.StoryDriftRatio(:,j)],100*s.StoryDriftRatio(:,j),curves(j).Color); end
ax=nexttile; plot(ax,s.RoofDisplacement,-s.BaseShear,'LineWidth',1); grid(ax,'on');
xlabel(ax,'Roof displacement [m]'); ylabel(ax,'Negative base shear [kN]');
title(ax,'Global force-displacement response');
g2vis.label_values(ax,[s.RoofDisplacement -s.BaseShear],-s.BaseShear);
ax=nexttile; plot(ax,s.Time,s.PlasticFibers,'LineWidth',1); grid(ax,'on');
xlabel(ax,'Time [s]'); ylabel(ax,'Fibers currently yielding [1]');
g2vis.label_values(ax,[s.Time s.PlasticFibers],s.PlasticFibers);
end
