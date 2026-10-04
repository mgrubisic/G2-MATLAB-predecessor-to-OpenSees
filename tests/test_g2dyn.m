function tests=test_g2dyn
tests=functiontests(localfunctions);
end
function setupOnce(t)
addpath(fileparts(fileparts(mfilename('fullpath')))); setup_g2;
t.TestData.visible=get(groot,'defaultFigureVisible'); set(groot,'defaultFigureVisible','off');
end
function teardownOnce(t), set(groot,'defaultFigureVisible',t.TestData.visible); close all; end
function teardown(~), close all; end
function m=oscillator(type,material)
if nargin<1, type=1; end
if nargin<2, material=[4 1]; end
m=model({'Oscillator',[0 0;1 0],[1 1 1;0 1 1],[1 2 type],{material},zeros(2,3)});
m=setMass(m,2,[1 0 0]);
end
function testDefaults(t)
n=g2dyn.newmark; verifyEqual(t,[n.Gamma n.Beta],[.5 .25]);
c=g2dyn.normUnbalance; verifyEqual(t,c.Norm,2);
verifyError(t,@()g2dyn.newmark(.5,0),'MATLAB:expectedPositive');
end
function testSeries(t)
s=g2dyn.timeSeries('Path','Values',[0 2 0],'Dt',.5,'Factor',3);
verifyEqual(t,g2dyn.evaluate(s,[-1 0 .25 .5 .75 1 2]),[0 0 3 6 3 0 0]);
s=g2dyn.timeSeries('Path','Values',[1 3],'Time',[2 4],'UseLast',true);
verifyEqual(t,g2dyn.evaluate(s,[0 2 3 4 5]),[0 1 2 3 3]);
s=g2dyn.timeSeries('Path','Values',[2 4],'Dt',1,'PrependZero',true,'StartTime',3);
verifyEqual(t,g2dyn.evaluate(s,[2 3 3.5 4 5]),[0 0 1 2 4]);
verifyEqual(t,g2dyn.evaluate(g2dyn.timeSeries('Constant','Factor',2),[-1 0 1]),[0 2 2]);
verifyEqual(t,g2dyn.evaluate(g2dyn.timeSeries('Linear','Factor',2),[-1 0 1]),[0 0 2]);
verifyEqual(t,g2dyn.evaluate(g2dyn.timeSeries('Sine','Period',2),[0 .5 1]),[0 1 0],'AbsTol',1e-14);
verifyError(t,@()g2dyn.timeSeries('Path','Values',[1 2],'Time',[1 1]),'G2Dyn:Series');
end
function testMassDefinition(t)
m=oscillator; m=setElementMass(m,1,2,'Form','consistent'); [M,K]=dynamicMatrices(m); d=visualData(m);
rx=zeros(6,1); rx(d.dof(:,1))=1;
verifyEqual(t,full(rx'*M*rx),3,'AbsTol',1e-12);
verifyEqual(t,full(M(d.dof(1,1),d.dof(2,1))),1/3,'AbsTol',1e-12);
verifyEqual(t,size(K),[6 6]);
verifyError(t,@()setMass(m,2,[-1 0 0]),'G2Dyn:Mass');
m=setElementMass(m,1,2,'Quantity','density'); verifyEqual(t,visualData(m).massPerLength,2);
m=setMass(m,2,[1 .2 0;.2 2 0;0 0 .4]); [M,~]=dynamicMatrices(m);
verifyEqual(t,full(M(d.dof(2,1),d.dof(2,2))),.2,'AbsTol',1e-12);
end
function testBeamMass(t)
M=g2dyn.elementMass([0 0;2 0],3,2,3,'consistent');
verifyEqual(t,M(2,3),6*44/420,'AbsTol',1e-12);
verifyEqual(t,M(3,6),-6*12/420,'AbsTol',1e-12);
verifyEqual(t,[1 0 0 1 0 0]*M*[1 0 0 1 0 0]',6,'AbsTol',1e-12);
verifyEqual(t,[0 1 0 0 1 0]*M*[0 1 0 0 1 0]',6,'AbsTol',1e-12);
verifyGreaterThan(t,min(eig(M)),0);
R=g2dyn.elementMass([0 0;0 2],3,2,3,'consistent');
verifyEqual(t,R(1,1),M(2,2),'AbsTol',1e-12);
verifyError(t,@()g2dyn.elementMass([0 0;2 0],3,3,3,'consistent'),'G2Dyn:MassForm');
end
function testRCM(t)
order=[1 8 2 7 3 6 4 5]; graph=sparse(8,8);
for i=1:7, graph(order(i),order(i+1))=1; end
graph=graph+graph'; p=g2dyn.rcm(graph); [i,j]=find(graph(p,p));
verifyEqual(t,sort(p),1:8); verifyLessThanOrEqual(t,max(abs(i-j)),1);
p=g2dyn.rcm(blkdiag(graph,sparse(2,2))); verifyEqual(t,sort(p),1:10);
end
function testFreeVibrationAndEnergy(t)
dt=.02; steps=200;
[m,r]=transientAnalysis(oscillator,dt,steps,'Patterns',{},'Integrator',g2dyn.newmark,'InitialDisplacement',[0 0 0;.1 0 0]);
u=cellfun(@(d)d.u(2,1),r.History); v=cellfun(@(d)d.velocity(2,1),r.History);
theta=2*atan(2*dt/2);
verifyEqual(t,u,.1*cos((0:steps)*theta),'AbsTol',2e-12);
verifyEqual(t,.5*v.^2+2*u.^2,.02*ones(size(u)),'AbsTol',1e-12);
verifyTrue(t,r.Converged); verifyEqual(t,visualData(m).time,4,'AbsTol',1e-12);
verifyLessThan(t,max(cellfun(@(d)d.residualNorm,r.History)),1e-8);
end
function testConstantForceAndGround(t)
ts=g2dyn.timeSeries('Constant','Factor',2); loads=[0 0 0;1 0 0];
[~,r]=transientAnalysis(oscillator,.01,100,'Integrator',g2dyn.newmark,'Patterns',{g2dyn.plain(ts,'Loads',loads,'ElementFactor',0)});
u=cellfun(@(d)d.u(2,1),r.History); expected=.5*(1-cos((0:100)*2*atan(.01)));
verifyEqual(t,u,expected,'AbsTol',2e-12);
[m,r]=transientAnalysis(oscillator,.01,100,'Integrator',g2dyn.newmark,'Patterns',{g2dyn.uniformExcitation(1,ts)});
verifyEqual(t,cellfun(@(d)d.u(2,1),r.History),-expected,'AbsTol',2e-12);
d=visualData(m); verifyEqual(t,d.absoluteAcceleration(2,1),d.acceleration(2,1)+2,'AbsTol',1e-12);
verifyEqual(t,d.applied(2,1),-2,'AbsTol',1e-12);
verifyEqual(t,d.reactions(1,1),-d.restoringForces(2,1),'AbsTol',1e-10);
end
function testSuperposedGroundPatterns(t)
m=oscillator; m=setElementMass(m,1,2,'Form','consistent');
patterns={g2dyn.uniformExcitation(1,g2dyn.timeSeries('Constant','Factor',2)), ...
    g2dyn.uniformExcitation(1,g2dyn.timeSeries('Constant','Factor',-1)), ...
    g2dyn.uniformExcitation(2,g2dyn.timeSeries('Constant','Factor',3))};
[m,r]=transientAnalysis(m,.01,2,'Patterns',patterns); verifyTrue(t,r.Converged);
d=visualData(m); [M,~]=dynamicMatrices(m); influence=zeros(6,2); influence(d.dof(:,1),1)=1; influence(d.dof(:,2),2)=1;
expected=-M*influence*[1;3];
verifyEqual(t,d.applied,reshape(expected(d.dof),size(d.dof)),'AbsTol',1e-12);
end
function testRayleigh(t)
m=oscillator; m=setElementMass(m,1,2);
m=rayleigh(m,.3,.1,.2,.4); [M,K,C]=dynamicMatrices(m);
verifyEqual(t,full(C),full(.3*M+.7*K),'AbsTol',1e-12);
m=rayleigh(m,0,0,0,0,'Elements',1); [~,~,C]=dynamicMatrices(m); d=visualData(m);
expected=zeros(6); expected(d.dof(2,1),d.dof(2,1))=.3;
verifyEqual(t,full(C),expected,'AbsTol',1e-12);
m=rayleigh(m,.2,0,0,0); [~,r]=transientAnalysis(m,.001,1000,'Patterns',{},'Integrator',g2dyn.newmark,'InitialDisplacement',[0 0 0;.1 0 0]);
omega=sqrt(2); zeta=.2/(2*omega); wd=omega*sqrt(1-zeta^2);
exact=.1*exp(-zeta*omega*r.Time).*(cos(wd*r.Time)+zeta*omega/wd*sin(wd*r.Time));
verifyEqual(t,cellfun(@(d)d.u(2,1),r.History)',exact,'AbsTol',3e-8);
end
function testModalMasslessRotation(t)
m=model({'Beam',[0 0;2 0],[1 1 1;1 0 0],[1 2 2],{[10 1 1]},zeros(2,3)});
m=setMass(m,2,[0 2 0]); modes=modalAnalysis(m,1);
verifyEqual(t,modes.Eigenvalues,3*10/(2^3*2),'AbsTol',1e-12);
verifyEqual(t,modes.Shapes(2,3,1)/modes.Shapes(2,2,1),3/(2*2),'AbsTol',1e-12);
u=.1*modes.Shapes(:,:,1); [~,r]=transientAnalysis(m,.01,10,'Patterns',{},'InitialDisplacement',u);
verifyTrue(t,r.Converged); verifyLessThan(t,max(cellfun(@(d)d.residualNorm,r.History)),1e-8);
end
function testNumberingInvariant(t)
xyz=[0 0;3 0;1 0;2 0]; con=[1 3 1;3 4 1;4 2 1]; bound=repmat([0 1 1],4,1); bound(1,:)=1;
m=model({'Chain',xyz,bound,con,repmat({[4 1]},3,1),zeros(4,3)}); m=setMass(m,2:4,repmat([1 0 0],3,1));
u=zeros(4,3); u(2:4,1)=[.1 .05 .07];
[a,~]=transientAnalysis(m,.01,20,'Patterns',{},'Numberer','Plain','InitialDisplacement',u);
[b,r]=transientAnalysis(m,.01,20,'Patterns',{},'Numberer','RCM','InitialDisplacement',u);
verifyEqual(t,visualData(a).u,visualData(b).u,'AbsTol',1e-12); verifyEqual(t,r.Numberer,'RCM');
verifyNotEqual(t,visualData(a).dof,visualData(b).dof);
end
function testContinuation(t)
[a,~]=transientAnalysis(oscillator,.01,10,'Patterns',{},'Integrator',g2dyn.newmark,'InitialDisplacement',[0 0 0;.1 0 0]);
[a,r]=transientAnalysis(a,.01,10,'Patterns',{},'Integrator',g2dyn.newmark);
[b,~]=transientAnalysis(oscillator,.01,20,'Patterns',{},'Integrator',g2dyn.newmark,'InitialDisplacement',[0 0 0;.1 0 0]);
verifyEqual(t,visualData(a).u,visualData(b).u,'AbsTol',1e-12);
verifyEqual(t,numel(r.Time),21); verifyEqual(t,r.EndTime,.2,'AbsTol',1e-12);
end
function testNonlinearCyclicReference(t)
dt=.01; n=1000; ts=g2dyn.timeSeries('Sine','Period',1,'Factor',8);
[m,r]=transientAnalysis(oscillator(6,[4 .1 .2 1]),dt,n, ...
    'Integrator',g2dyn.newmark,'Patterns',{g2dyn.plain(ts,'Loads',[0 0 0;1 0 0],'ElementFactor',0)});
expected=bilinearReference(dt,n); actual=cellfun(@(d)d.u(2,1),r.History);
verifyTrue(t,r.Converged); verifyEqual(t,actual,expected,'AbsTol',2e-8);
verifyGreaterThan(t,max(actual),.05); verifyLessThan(t,min(actual),-.05);
d=visualData(m); verifyLessThan(t,norm(d.residual(d.bound==0)),1e-8);
verifyGreaterThan(t,max(cellfun(@(d)d.iterations,r.History)),1);
end
function testFailureRollback(t)
ws=warning('off','G2Dyn:NoConvergence'); cleanup=onCleanup(@()warning(ws)); %#ok<NASGU>
[m,r]=transientAnalysis(oscillator(6,[4 .1 .2 1]),.5,1, ...
    'Patterns',{g2dyn.plain(g2dyn.timeSeries('Linear','Factor',100),'Loads',[0 0 0;1 0 0])}, ...
    'Test',g2dyn.normUnbalance(1e-10,1),'MaxSubdivisions',0);
verifyFalse(t,r.Converged); verifyEqual(t,r.EndTime,0); verifyEqual(t,numel(r.History),1);
d=visualData(m); verifyEqual(t,d.u,zeros(2,3)); verifyEqual(t,d.elements{1}.prop.sc,0);
end
function testCutback(t)
[~,r]=transientAnalysis(oscillator(6,[4 .1 .2 1]),.5,1, ...
    'Patterns',{g2dyn.plain(g2dyn.timeSeries('Linear','Factor',10),'Loads',[0 0 0;1 0 0])}, ...
    'Test',g2dyn.normUnbalance(1e-9,1),'MaxSubdivisions',8);
verifyTrue(t,r.Converged); verifyGreaterThan(t,r.Cutbacks,0); verifyEqual(t,r.EndTime,.5,'AbsTol',1e-12);
verifyTrue(t,all(diff(r.Time)>0));
end
function testFiberBeamDynamics(t)
for type=[12 13]
    m=model({'Fiber',[0 0;1 0],[1 1 1;1 0 0],[1 2 type],{[.4 .2 .1 .2 3 3 200 .5 .02 3]},zeros(2,3)});
    m=setMass(m,2,[0 .01 0]); m=rayleigh(m,.01,0,.001,0);
    [m,r]=transientAnalysis(m,.01,100,'Patterns',{g2dyn.uniformExcitation(2,g2dyn.timeSeries('Sine','Period',.5,'Factor',10))});
    verifyTrue(t,r.Converged); d=visualData(m);
    verifyLessThan(t,norm(d.residual(d.bound==0)),1e-8);
    verifyGreaterThan(t,max(cellfun(@(s)max(abs(s.u(:))),r.History)),0);
end
end
function testInputFailures(t)
m=oscillator; m=setMass(m,2,[0 0 0]); verifyError(t,@()transientAnalysis(m,.1,1),'G2Dyn:NoMass');
m=model({'Beam',[0 0;1 0],[1 1 1;1 0 0],[1 2 2],{[10 1 1]},[0 0 0;0 0 1]}); m=setMass(m,2,[0 1 0]);
verifyError(t,@()transientAnalysis(m,.1,1),'G2Dyn:InitialEquilibrium');
end
function testFileSeriesAndDynamicUnits(t)
file=[tempname '.txt']; cleanup=onCleanup(@()delete(file)); %#ok<NASGU>
writematrix([0 0;.1 2;.2 0],file);
s=g2dyn.timeSeries('Path','FilePath',file); verifyEqual(t,g2dyn.evaluate(s,.05),1,'AbsTol',1e-12);
writematrix([0;2;0],file);
s=g2dyn.timeSeries('Path','FilePath',file,'Dt',.1); verifyEqual(t,g2dyn.evaluate(s,.05),1,'AbsTol',1e-12);
metric=g2vis.units; imperial=g2vis.units('Imperial','Length','in','Force','kip');
verifyEqual(t,metric.RotationalInertia,'tonne*m^2'); verifyEqual(t,metric.MassPerLength,'tonne/m');
verifyEqual(t,g2vis.convert_units(1,'Acceleration',metric,imperial),1/.0254,'AbsTol',1e-12);
verifyEqual(t,g2vis.convert_units(1,'AngularVelocity',metric,imperial),1);
end
function testStaticPreloadAndDistributedLoad(t)
m=model({'Preloaded',[0 0;2 0],[1 1 1;0 0 0],[1 2 2],{[100 1 1 2 0]},[0 0 0;0 -1 0]});
m=setElementMass(m,1,1,'Form','consistent');
evalc('m=linearAnalysis(m);'); initial=visualData(m);
[m,r]=transientAnalysis(m,.01,10); verifyTrue(t,r.Converged);
verifyEqual(t,visualData(m).u,initial.u,'AbsTol',1e-12);
verifyEqual(t,visualData(m).reactions,initial.reactions,'AbsTol',1e-10);
verifyEqual(t,r.History{1}.time,0); verifyTrue(t,all(cellfun(@(s)strcmp(s.analysis,'transient'),r.History)));
end
function testNonlinearRayleighStiffness(t)
m=oscillator(6,[4 .1 .2 1]); m=rayleigh(m,.2,.1,.2,.3);
[m,r]=transientAnalysis(m,.01,50,'Patterns',{g2dyn.plain(g2dyn.timeSeries('Linear','Factor',10), ...
    'Loads',[0 0 0;1 0 0],'ElementFactor',0)});
verifyTrue(t,r.Converged); d=visualData(m); [M,K,C]=dynamicMatrices(m); i=d.dof(2,1);
verifyEqual(t,full(K(i,i)),.4,'AbsTol',1e-12);
verifyEqual(t,full(C(i,i)),.2*full(M(i,i))+.1*.4+.2*4+.3*.4,'AbsTol',1e-12);
verifyError(t,@()transientAnalysis(m,.01,1,'Numberer','Plain'),'G2Dyn:Numberer');
end
function testDynamicPlots(t)
[m,r]=transientAnalysis(oscillator,.01,10,'Patterns',{g2dyn.uniformExcitation(1,g2dyn.timeSeries('Sine'))});
for component={'displacement','velocity','acceleration','absoluteAcceleration','groundAcceleration','reaction','residualNorm'}
    [ax,~,values]=g2vis.plot_time_history(m,2,1,'Component',component{1});
    verifyEqual(t,values(:,1),r.Time); verifyTrue(t,contains(ax.XLabel.String,'[s]'));
    verifyTrue(t,contains(ax.YLabel.String,'['));
end
[~,~,values]=g2vis.plot_history(m,2,1); verifyEqual(t,values(:,1),r.Time);
g2vis.plot_mass(m); g2vis.plot_hysteresis(m,2,1); g2vis.dynamic_dashboard(m,2,1);
for field={'velocity','acceleration','absoluteAcceleration'}, g2vis.plot_nodal_response(m,field{1}); end
f=g2vis.viewer(m); mode=findobj(f,'Tag','G2VisMode'); labels=mode.String;
for name={'Velocity','Acceleration','Absolute acceleration','Masses'}
    mode.Value=find(strcmp(labels,name{1})); cb=mode.Callback; cb(mode,[]);
end
g2vis.anim_defo(r.History([1 end]),'Delay',0);
ax=findall(gcf,'Type','axes'); verifyTrue(t,contains(ax(1).Title.String,'t '));
end
function values=bilinearReference(dt,n)
% Independent kinematic-hardening return map, scalar bisection equilibrium.
k=4; b=.1; fy=.2; H=b*k/(1-b); u=0; v=0; a=0; plastic=0; back=0;
values=zeros(1,n+1);
for i=1:n
    predictor=u+dt*v+dt^2*.25*a; vp=v+.5*dt*a; force=8*sin(2*pi*i*dt);
    lo=-100; hi=100;
    for j=1:55
        trial=(lo+hi)/2; [f,~,~]=returnMap(trial,plastic,back,k,H,fy);
        balance=f+4/dt^2*(trial-predictor)-force;
        if balance>0, hi=trial; else, lo=trial; end
    end
    trial=(lo+hi)/2; [~,plastic,back]=returnMap(trial,plastic,back,k,H,fy);
    a=4/dt^2*(trial-predictor); v=vp+.5*dt*a; u=trial; values(i+1)=u;
end
end
function [f,p,back]=returnMap(u,p,back,k,H,fy)
f=k*(u-p); xi=f-back;
if abs(xi)>fy
    dp=(abs(xi)-fy)/(k+H)*sign(xi); p=p+dp; back=back+H*dp; f=f-k*dp;
end
end
