function tests = test_g2vis
% Numerical and graphical regression checks, using independent beam solutions.
tests=functiontests(localfunctions);
end

function setupOnce(t)
t.TestData.root=fileparts(fileparts(mfilename('fullpath')));
addpath(t.TestData.root); setup_g2;
t.TestData.visible=get(groot,'defaultFigureVisible');
set(groot,'defaultFigureVisible','off');
end
function teardownOnce(t)
set(groot,'defaultFigureVisible',t.TestData.visible); close all;
end
function teardown(~), close all; end

function m = beam(type,material,bound,loads)
m=model({'Analytic beam',[0 0;10 0],bound,[1 2 type],{material},loads});
end
function m = solve(m)
evalc('m=linearAnalysis(m);');
end

function testInitialModelAndZeroScaling(t)
m=beam(2,[200 2 3],[1 1 1;0 0 0],zeros(2,3));
d=visualData(m); verifySize(t,d.u,[2 3]); verifyFalse(t,d.solved);
[curves,s]=g2vis.deformed_coordinates(m); verifyEqual(t,s,0);
verifyEqual(t,curves{1}([1 end],:),d.xyz);
g2vis.plot_model(m,'LocalAxes',true); plot(m,'Legacy title',0);
end

function testCantileverTipLoad(t)
E=200; I=3; L=10; P=1;
m=solve(beam(2,[E 2 I],[1 1 1;0 0 0],[0 0 0;0 -P 0]));
d=visualData(m);
verifyEqual(t,d.u(2,2),-P*L^3/(3*E*I),'AbsTol',1e-12);
verifyEqual(t,d.reactions(1,:),[0 P P*L],'AbsTol',1e-12);
[c,s]=g2vis.deformed_coordinates(m,'Scale',1,'Points',41); x=c{1}(:,1);
verifyEqual(t,s,1); verifyEqual(t,c{1}(:,2),-P*x.^2.*(3*L-x)/(6*E*I),'AbsTol',1e-12);
[f,x]=g2vis.section_force_distribution_2d(m,1);
verifyEqual(t,f(:,1),zeros(size(x)),'AbsTol',1e-12);
verifyEqual(t,f(:,2),P*ones(size(x)),'AbsTol',1e-12);
verifyEqual(t,f(:,3),-P*(L-x),'AbsTol',1e-12);
verifyLessThan(t,norm(d.residual(d.bound==0)),1e-10);
end

function testUniformLoadSimplySupported(t)
E=200; I=3; L=10; w=2;
m=solve(beam(2,[E 2 I w 0],[1 1 0;0 1 0],zeros(2,3)));
d=visualData(m); verifyEqual(t,d.reactions(:,2),[w*L/2;w*L/2],'AbsTol',1e-12);
[f,x]=g2vis.section_force_distribution_2d(m,1);
verifyEqual(t,f(:,2),w*(L/2-x),'AbsTol',1e-12);
verifyEqual(t,f(:,3),w*x.*(L-x)/2,'AbsTol',1e-12);
c=g2vis.deformed_coordinates(m,'Scale',1);
expected=-w*x.*(L^3-2*L*x.^2+x.^3)/(24*E*I);
verifyEqual(t,c{1}(:,2),expected,'AbsTol',1e-12);
end

function testFixedBeamInteriorDisplacement(t)
E=200; I=3; L=10; w=2;
m=solve(beam(2,[E 2 I w 0],ones(2,3),zeros(2,3)));
c=g2vis.deformed_coordinates(m,'Scale',1);
verifyEqual(t,c{1}(21,2),-w*L^4/(384*E*I),'AbsTol',1e-12);
[~,s]=g2vis.deformed_coordinates(m); verifyGreaterThan(t,s,0);
end

function testReleasedEnds(t)
E=200; I=3; L=10; w=2;
for release=1:3
    m=solve(beam(3,[E 2 I release w],ones(2,3),zeros(2,3)));
    d=visualData(m); f=d.elements{1}.endForces;
    if ismember(release,[1 3]), verifyEqual(t,f(3),0,'AbsTol',1e-12); end
    if ismember(release,[2 3]), verifyEqual(t,f(6),0,'AbsTol',1e-12); end
    c=g2vis.deformed_coordinates(m,'Scale',1);
    verifyLessThan(t,min(c{1}(:,2)),0);
    if release==3
        verifyEqual(t,c{1}(21,2),-5*w*L^4/(384*E*I),'AbsTol',1e-12);
    end
end
end

function testRotatedBeam(t)
E=200; I=3; L=10; P=1; angle=.7;
tangent=[cos(angle) sin(angle)]; normal=[-sin(angle) cos(angle)];
loads=[0 0 0;-P*normal 0];
m=model({'Rotated beam',[0 0;L*tangent],[1 1 1;0 0 0],[1 2 2],{[E 2 I]},loads}); m=solve(m);
c=g2vis.deformed_coordinates(m,'Scale',1); x=linspace(0,L,41)';
expected=x*tangent-P*x.^2.*(3*L-x)/(6*E*I)*normal;
verifyEqual(t,c{1},expected,'AbsTol',1e-12);
d=visualData(m); verifyEqual(t,d.reactions(1,1:2),P*normal,'AbsTol',1e-12);
end

function testAxialTruss(t)
m=solve(beam(1,[200 2],[1 1 1;0 1 1],[0 0 0;4 0 0]));
d=visualData(m); verifyEqual(t,d.u(2,1),.1,'AbsTol',1e-12);
f=g2vis.section_force_distribution_2d(m,1);
verifyEqual(t,f(:,1),4*ones(41,1),'AbsTol',1e-12);
verifyEqual(t,f(:,2:3),zeros(41,2),'AbsTol',1e-12);
end

function testAllElementFamilies(t)
types=[1 2 3 4 5 6 8 12 13 15];
materials={[200 2],[200 2 3],[200 2 3 1],[2 10 .01], ...
    [200 .02 10 2],[200 .02 10 2],[200 .02 10 2 3], ...
    [12 10 3 10 3 3 200 36 .02 3],[12 10 3 10 3 3 200 36 .02 3],[200 2]};
for i=1:numel(types)
    b=[1 1 1;0 1 1]; load=[0 0 0;.01 0 0];
    if types(i)==15, b=b(:,1:2); load=load(:,1:2); end
    m=beam(types(i),materials{i},b,load);
    evalc('[m,plt,plte]=variableloadNR(m,[2 1 1.5 20 1e-8],[],[]);');
    verifyEmpty(t,plt); verifyEmpty(t,plte);
    d=visualData(m); verifyTrue(t,all(isfinite(d.elements{1}.endForces)));
    verifyLessThan(t,norm(d.residual(d.bound==0)),1e-7);
    g2vis.deformed_coordinates(m);
    if types(i)==15
        [~,lines]=g2vis.section_force_diagram_2d(m,'N','Scale',0);
        xplot=get(lines(1),'XData');
        verifyEqual(t,xplot([1 end]),[0 10],'AbsTol',1e-12);
    end
end
end

function testUniformSolverCompatibility(t)
m=beam(2,[200 2 3],[1 1 1;0 0 0],[0 0 0;0 -1 0]);
evalc('[plt,plte,out]=simpleNewtonRaphson(m,[3 .5 5 1e-9],2,1);');
verifyEqual(t,plt(:,1),[0;.5;1;1.5]); verifySize(t,plte,[4 1]);
h=visualHistory(out); verifyEqual(t,numel(h),4);
verifyEqual(t,h{end}.lambda,1.5);
evalc('[plt2,~,out2]=modifiedNR(m,[3 .5 5 1e-9],2,1);');
verifyEqual(t,plt2,plt,'AbsTol',1e-12);
verifyEqual(t,visualData(out2).u,visualData(out).u,'AbsTol',1e-12);
end

function testFailedStepNotRecorded(t)
m=beam(2,[200 2 3],[1 1 1;0 0 0],[0 0 0;0 -1 0]);
evalc('[plt,plte,out]=simpleNewtonRaphson(m,[3 1 1 1e-9],2,1);');
verifySize(t,plt,[1 2]); verifySize(t,plte,[1 1]);
verifyEqual(t,numel(visualHistory(out)),1); verifyFalse(t,visualData(out).solved);
end

function testPlottingDoesNotChangeState(t)
m=solve(beam(2,[200 2 3 2 0],[1 1 0;0 1 0],zeros(2,3)));
before=visualData(m); history=visualHistory(m);
f=g2vis.dashboard(m); g2vis.plot_reactions(m); g2vis.plot_defo(m,'Scale',0);
for comp={'x','y','rotation'}, g2vis.plot_displacements(m,'Component',comp{1}); end
g2vis.plot_history(m,2,3);
verifyEqual(t,visualData(m),before); verifyEqual(t,visualHistory(m),history);
tmp=[tempname '.png']; cleanup=onCleanup(@() delete(tmp)); %#ok<NASGU>
exportgraphics(f,tmp); verifyGreaterThan(t,dir(tmp).bytes,1000);
end

function testViewerCallbacks(t)
m=solve(beam(2,[200 2 3],[1 1 1;0 0 0],[0 0 0;0 -1 0]));
f=g2vis.viewer(m); popup=findobj(f,'Style','popupmenu'); choices=get(popup,'String');
for i=1:numel(choices)
    set(popup,'Value',i); cb=get(popup,'Callback'); cb(popup,[]);
end
slider=findobj(f,'Style','slider'); set(slider,'Value',1); cb=get(slider,'Callback'); cb(slider,[]);
verifyTrue(t,isgraphics(f));
end

function testAnimationGif(t)
m=solve(beam(2,[200 2 3],[1 1 1;0 0 0],[0 0 0;0 -1 0]));
tmp=[tempname '.gif']; cleanup=onCleanup(@() delete(tmp)); %#ok<NASGU>
g2vis.anim_defo(m,'Filename',tmp,'Delay',0);
info=imfinfo(tmp); verifyEqual(t,numel(info),2);
end

function testCommittedFiberViewsAndControls(t)
material=[12 10 3 10 3 3 200 36 .02 3];
m=beam(12,material,[1 1 1;0 0 0],[0 0 0;0 1 0]);
evalc('[m,~,~]=variableloadNR(m,[2 1 1.5 10 1e-8],[],[]);');
before=visualData(m); e=before.elements{1};
[~,~,v]=g2vis.plot_fiber_section(m,1,2,'Component','strain');
verifyEqual(t,sum(v(:,2)),120,'AbsTol',1e-12);
sec=struct(e.secs(2)); kappa=sec.vs(1); axial=sec.vs(2);
verifyEqual(t,v(:,3),axial-v(:,1)*kappa,'AbsTol',1e-12);
g2vis.plot_section(m,'curvature'); g2vis.plot_section(m,'strain');
f=g2vis.viewer(m); popup=findobj(f,'Tag','G2VisMode'); choices=get(popup,'String');
for i=1:numel(choices), set(popup,'Value',i); cb=get(popup,'Callback'); cb(popup,[]); end
section=findobj(f,'Tag','G2VisFiberSection'); set(section,'Value',3); cb=get(section,'Callback'); cb(section,[]);
verifyEqual(t,visualData(m),before);
end

function testInvalidRequests(t)
m=beam(2,[200 2 3],[1 1 1;0 0 0],zeros(2,3));
verifyError(t,@() g2vis.section_force_diagram_2d(m,'wrong'),'G2Vis:Component');
verifyError(t,@() g2vis.plot_model(m,'Elements',99),'G2Vis:Elements');
verifyError(t,@() g2vis.plot_section(m,'curvature'),'G2Vis:Section');
verifyError(t,@() g2vis.plot_fiber_section(m,1,1),'G2Vis:Section');
end

function testMomentDiagramMirrorsGeometryOnly(t)
m=solve(beam(2,[200 2 3],[1 1 1;0 0 0],[0 0 0;0 -1 0]));
[ax,h,s,v]=g2vis.section_force_diagram_2d(m,'M','Scale',2);
verifyEqual(t,s,2);
verifyEqual(t,get(h(1),'YData')',-2*v{1},'AbsTol',1e-12);
verifyEqual(t,v{1}(1),-10,'AbsTol',1e-12);
labels=findall(ax,'Tag','G2VisValue'); strings=get(labels,'String');
verifyTrue(t,any(strcmp(strings,' -10')));
% N and V retain their previous graphical direction.
[~,h,s,v]=g2vis.section_force_diagram_2d(m,'V','Scale',2);
verifyEqual(t,get(h(1),'YData')',s*v{1},'AbsTol',1e-12);
end

function testSupportAnchorsAndDefaults(t)
xyz=[0 0;10 0;20 0;30 0]; bound=[1 1 1;1 1 0;0 1 0;1 0 0];
m=model({'Support anchors',xyz,bound,[1 2 2;2 3 2;3 4 2],repmat({[200 2 3]},3,1),zeros(4,3)});
for kind={'model','defo','displacements','M'}
    switch kind{1}
        case 'model', ax=g2vis.plot_model(m);
        case 'defo', ax=g2vis.plot_defo(m);
        case 'displacements', ax=g2vis.plot_displacements(m);
        case 'M', ax=g2vis.section_force_diagram_2d(m,'M');
    end
    symbols=findall(ax,'Tag','G2VisSupport'); verifyNumElements(t,symbols,4);
    for symbol=symbols'
        info=get(symbol,'UserData'); x=get(symbol,'XData'); y=get(symbol,'YData');
        if info.Node==4
            verifyEqual(t,min(x),info.Anchor(1),'AbsTol',1e-12);
        else
            verifyEqual(t,max(y),info.Anchor(2),'AbsTol',1e-12);
            verifyLessThan(t,min(y),info.Anchor(2));
        end
    end
end
ax=g2vis.plot_defo(m,'Supports',false);
verifyEmpty(t,findall(ax,'Tag','G2VisSupport'));
ax=g2vis.section_force_diagram_2d(m,'M','Supports',false);
verifyEmpty(t,findall(ax,'Tag','G2VisSupport'));
end

function testConcentratedMomentHasDirectedHead(t)
for moment=[-10 10]
    m=beam(2,[200 2 3],[1 1 1;0 0 0],[0 0 0;0 0 moment]);
    ax=g2vis.plot_load(m); head=findall(ax,'Tag','G2VisMomentArrowhead');
    verifyNumElements(t,head,1); info=get(head,'UserData');
    verifyEqual(t,info.Moment,moment);
    x=get(head,'XData'); y=get(head,'YData');
    verifyGreaterThan(t,polyarea(x,y),0);
    radial=[x(1)-10 y(1)]; direction=info.Direction;
    verifyEqual(t,sign(radial(1)*direction(2)-radial(2)*direction(1)),sign(moment));
    m=solve(m); ax=g2vis.plot_reactions(m);
    verifyNumElements(t,findall(ax,'Tag','G2VisMomentArrowhead'),1);
end
end

function testLightStyleAndTransparentLegend(t)
material=[12 10 3 10 3 3 200 36 .02 3];
m=beam(12,material,[1 1 1;0 0 0],[0 0 0;0 1 0]);
f=figure('Color','k'); ax=axes('Parent',f,'Color','k');
g2vis.plot_section(m,'curvature','Axes',ax);
verifyEqual(t,get(f,'Color'),[1 1 1]); verifyEqual(t,get(ax,'Color'),[1 1 1]);
lg=findall(f,'Type','legend'); verifyNumElements(t,lg,1);
verifyEqual(t,char(get(lg,'Box')),'off'); verifyEqual(t,get(lg,'Color'),'none');
verifyEqual(t,get(lg,'TextColor'),[.15 .15 .15]);
% Legends subsequently created by callers inherit the same style.
other=axes('Parent',f); plot(other,1:3,'DisplayName','Curve'); lg=legend(other,'show');
verifyEqual(t,get(other,'Color'),[1 1 1]);
verifyEqual(t,get(lg,'Color'),'none'); verifyEqual(t,char(get(lg,'Box')),'off');
end

function testDefaultValuesIncludingZeroDiagrams(t)
m=solve(beam(2,[200 2 3],[1 1 1;0 0 0],[0 0 0;0 -1 0]));
f=g2vis.dashboard(m); axesList=findall(f,'Type','axes');
forceAxes=0;
for ax=axesList'
    label=get(get(ax,'Title'),'String');
    if startsWith(label,'N [')||startsWith(label,'V [')||startsWith(label,'M [')
        forceAxes=forceAxes+1;
        verifyNotEmpty(t,findall(ax,'Tag','G2VisValue'));
        verifyNotEmpty(t,findall(ax,'Tag','G2VisSupport'));
    end
end
verifyEqual(t,forceAxes,3);

ax=g2vis.section_force_diagram_2d(m,'N'); labels=findall(ax,'Tag','G2VisValue');
verifyEqual(t,get(labels(1),'String'),' 0');
ax=g2vis.section_force_diagram_2d(m,'M','Values',false);
verifyEmpty(t,findall(ax,'Tag','G2VisValue'));
end

function testOptionalInvertKeepsSignedValues(t)
m=solve(beam(2,[200 2 3],[1 1 1;0 0 0],[0 0 0;0 -1 0]));
[~,h,s,v]=g2vis.section_force_diagram_2d(m,'M','Scale',2);
defaultY=get(h(1),'YData');
[ax,h,s2,v2]=g2vis.section_force_diagram_2d(m,'M','Scale',2,'invert',true);
verifyEqual(t,get(h(1),'YData'),-defaultY,'AbsTol',1e-12);
verifyEqual(t,s2,s); verifyEqual(t,v2,v);
labels=findall(ax,'Tag','G2VisValue'); verifyTrue(t,any(strcmp(get(labels,'String'),' -10')));
[~,h,~,v3]=g2vis.section_force_diagram_2d(m,'V','Scale',2,'Invert',true);
verifyEqual(t,get(h(1),'YData')',2*v3{1},'AbsTol',1e-12);
f=g2vis.viewer(m); mode=findobj(f,'Tag','G2VisMode'); list=get(mode,'String');
set(mode,'Value',find(strcmp(list,'M'))); cb=get(mode,'Callback'); cb(mode,[]);
invert=findobj(f,'Tag','G2VisInvert'); verifyEqual(t,get(invert,'Value'),0);
set(invert,'Value',1); cb=get(invert,'Callback'); cb(invert,[]);
end

function testMetricImperialUnitDefinitions(t)
metric=g2vis.units;
verifyEqual(t,metric.System,'Metric'); verifyEqual(t,metric.Length,'m');
verifyEqual(t,metric.Force,'kN'); verifyEqual(t,metric.Mass,'tonne');
verifyEqual(t,metric.Moment,'kN*m'); verifyEqual(t,metric.Stress,'kN/m^2');
verifyEqual(t,metric.Density,'tonne/m^3'); verifyEqual(t,metric.SI.Mass,1000);
imperial=g2vis.units('Imperial'); verifyEqual(t,imperial.Mass,'slug');
verifyEqual(t,imperial.SI.Mass,14.5939029372064,'RelTol',1e-12);
inchKip=g2vis.units('Imperial','Length','in','Force','kip');
verifyEqual(t,inchKip.Stress,'ksi'); verifyEqual(t,inchKip.Moment,'kip*in');
verifyEqual(t,inchKip.Mass,'kip*s^2/in');
verifyEqual(t,g2vis.convert_units(1,'Length',inchKip,metric),.0254,'AbsTol',1e-15);
verifyEqual(t,g2vis.convert_units(int32(120),'Length',inchKip,metric),3.048,'AbsTol',1e-12);
verifyEqual(t,g2vis.convert_units(1,'Force',inchKip,metric),4.4482216152605,'AbsTol',1e-12);
verifyEqual(t,g2vis.convert_units(1,'Moment',inchKip,metric),.112984829027617,'AbsTol',1e-12);
verifyEqual(t,g2vis.convert_units(1,'Stress',inchKip,metric),6894.75729316836,'RelTol',1e-12);
verifyEqual(t,g2vis.convert_units([1 2],'Strain',inchKip,metric),[1 2]);
verifyError(t,@() g2vis.units('Metric','Length','in'),'G2Vis:Units');
verifyError(t,@() g2vis.convert_units(1,'Unknown',metric,imperial),'G2Vis:Quantity');
end

function testModelUnitMetadataPreservesNumerics(t)
a={'Units model',[0 0;10 0],[1 1 1;0 0 0],[1 2 2],{[200 2 3]},[0 0 0;0 -1 0]};
metric=solve(model(a)); imperial=solve(model([a {g2vis.units('Imperial','Length','in','Force','kip')}]));
md=visualData(metric); id=visualData(imperial);
verifyEqual(t,md.u,id.u); verifyEqual(t,md.elements{1}.endForces,id.elements{1}.endForces);
verifyEqual(t,md.units.Length,'m'); verifyEqual(t,id.units.Length,'in');
history=visualHistory(imperial);
for k=1:numel(history), verifyEqual(t,history{k}.units,id.units); end
ax=g2vis.plot_model(imperial); verifyEqual(t,get(get(ax,'XLabel'),'String'),'X [in]');
ax=g2vis.plot_reactions(imperial); verifyTrue(t,contains(get(get(ax,'Title'),'String'),'kip*in'));
ax=g2vis.section_force_diagram_2d(imperial,'M'); verifyTrue(t,contains(get(get(ax,'Title'),'String'),'M [kip*in]'));
end

function testPhysicalUnitLabelsAcrossViews(t)
material=[12 10 3 10 3 3 200 36 .02 3];
a={'Units fibers',[0 0;10 0],[1 1 1;0 0 0],[1 2 12],{material},[0 0 0;0 1 0], ...
    g2vis.units('Imperial','Length','in','Force','kip')};
m=model(a); evalc('[m,~,~]=variableloadNR(m,[2 1 1.5 10 1e-8],[],[]);');
ax=g2vis.plot_defo(m); verifyTrue(t,contains(get(get(ax,'Title'),'String'),'|u| [in]'));
ax=g2vis.plot_displacements(m,'Component','rotation');
cb=findall(ancestor(ax,'figure'),'Type','colorbar'); verifyEqual(t,cb.Label.String,'rotation [rad]');
ax=g2vis.plot_load(m); verifyTrue(t,contains(get(get(ax,'Title'),'String'),'w [kip/in]'));
ax=g2vis.plot_section(m,'curvature'); verifyEqual(t,get(get(ax,'YLabel'),'String'),'curvature [1/in]');
ax=g2vis.plot_section(m,'strain'); verifyEqual(t,get(get(ax,'YLabel'),'String'),'strain [1]');
ax=g2vis.plot_fiber_section(m,1,1,'Component','stress');
cb=findall(ancestor(ax,'figure'),'Type','colorbar'); verifyEqual(t,cb.Label.String,'stress [ksi]');
ax=g2vis.plot_fiber_section(m,1,1,'Component','material');
cb=findall(ancestor(ax,'figure'),'Type','colorbar'); verifyEqual(t,cb.Label.String,'material state [1]');
ax=g2vis.plot_history(m,2,3); verifyTrue(t,contains(get(get(ax,'XLabel'),'String'),'[rad]'));
verifyEqual(t,get(get(ax,'YLabel'),'String'),'Load factor [1]');
end
