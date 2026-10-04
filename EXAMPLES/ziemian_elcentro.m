function [m1,dynamicResult,modalData,earthquakeSummary]=ziemian_elcentro(varargin)
% ZIEMIAN_ELCENTRO Nonlinear Ziemian frame under the complete ElCentro record.
% ziemian_elcentro
% [m,result,modes,summary]=ziemian_elcentro('Plot',false)
% Native units: m-kN-tonne-s. Input acceleration: g; record spacing: 0.02 s.
% Geometry, pinned bases and A/I follow ziemian.m. Material nonlinearity is
% bilinear fiber steel (element12); kinematics remain small-displacement.
% Equivalent rectangular I sections match the original A/I, not rolled-shape
% dimensions. FloorLoads, Fy, hardening and damping are demonstration assumptions.
root=fileparts(fileparts(mfilename('fullpath'))); addpath(root); setup_g2;
ip=inputParser;
addParameter(ip,'RecordPath',fullfile(root,'data','earthquakes','ElCentro.txt'),@(x)ischar(x)||isstring(x));
addParameter(ip,'Plot',true,@(x)islogical(x)&&isscalar(x));
addParameter(ip,'FloorLoads',[50 35],@(x)isnumeric(x)&&numel(x)==2&&all(isfinite(x))&&all(x>0)); % kN/m
parse(ip,varargin{:}); o=ip.Results;
dt=.02; gravity=9.80665; rho=7.85; E=200e6; fy=250e3; hardening=.01;
accelSeries=g2dyn.timeSeries('Path','FilePath',o.RecordPath,'Dt',dt,'Factor',gravity);
if numel(accelSeries.Values)<2, error('G2Example:Record','At least two acceleration samples are required.'); end
recordTime=accelSeries.Time; recordG=accelSeries.Values;

XYZ=[0 0;0 6.1;0 10.67;6.1 0;6.1 6.1;6.1 10.67;20.73 0;20.73 6.1;20.73 10.67];
BOUND=zeros(9,3); BOUND([1 4 7],1:2)=1;
members=[1 2;2 3;4 5;5 6;7 8;8 9;2 5;5 8;3 6;6 9];
inch=.0254;
areas=[4.16 3.54 29.1 32 24 32 24.7 39.9 11.8 27.6]'*inch^2;
inertias=[88.6 53.8 1110 1240 881 1240 2850 7800 612 3270]'*inch^4;
heights=[12 10 14 14 14 14 27 36 18 27]'*inch;
widths=[4 4 14 14 10 14 10 12 6 10]'*inch;
% Two elements per member improve distributed plasticity resolution.
CONNECT=zeros(20,3); MATERIAL=cell(1,20); elementArea=zeros(20,1);
for member=1:10
    nodes=members(member,:); middle=size(XYZ,1)+1;
    XYZ(middle,:)=mean(XYZ(nodes,:),1); BOUND(middle,:)=0;
    ids=2*member-1:2*member;
    CONNECT(ids,:)=[nodes(1) middle 12;middle nodes(2) 12];
    section=equivalentSection(areas(member),inertias(member),heights(member),widths(member));
    for e=ids
        MATERIAL{e}=[section 3 6 E fy hardening 3];
        elementArea(e)=areas(member);
    end
end
% Floor weight is lumped to frame joints by tributary span. Its mass acts
% in both translations. Steel mass is separate and consistently distributed.
floorWeight=zeros(size(XYZ,1),1);
for member=7:10
    nodes=members(member,:); L=norm(XYZ(nodes(2),:)-XYZ(nodes(1),:));
    floor=1+(member>=9);
    floorWeight(nodes)=floorWeight(nodes)+o.FloorLoads(floor)*L/2;
end
LOAD=zeros(size(BOUND)); LOAD(:,2)=-floorWeight;
for e=1:size(CONNECT,1)
    nodes=CONNECT(e,1:2); L=norm(XYZ(nodes(2),:)-XYZ(nodes(1),:));
    LOAD(nodes,2)=LOAD(nodes,2)-rho*elementArea(e)*L*gravity/2;
end
m1=model({'Nonlinear Ziemian | ElCentro',XYZ,BOUND,CONNECT,MATERIAL,LOAD,g2vis.units});
floorNodes=find(floorWeight>0);
m1=setMass(m1,floorNodes,[floorWeight(floorNodes)/gravity floorWeight(floorNodes)/gravity zeros(numel(floorNodes),1)]);
m1=setElementMass(m1,1:20,rho,'Quantity','density','Form','consistent');
m1=numberer(m1,'RCM');
% Establish static gravity equilibrium before applying the earthquake.
[gravitySteps,~,m1]=simpleNewtonRaphson(m1,[10 .1 50 1e-7],[1],[]);
assert(abs(gravitySteps(end,1)-1)<1e-12,'Gravity preload did not converge.');
gravitySnapshot=visualData(m1);
modes=modalAnalysis(m1,6); modalData=modalProperties(m1,modes,'-print');
zeta=.03; w=modes.Omega(1:2); coeff=[1./(2*w) w/2]\[zeta;zeta];
m1=rayleigh(m1,coeff(1),0,coeff(2),0);
gravityPattern=g2dyn.plain(g2dyn.timeSeries('Constant'),'Loads',LOAD,'ElementFactor',0);
excitation=g2dyn.uniformExcitation(1,accelSeries);
[m1,dynamicResult]=transientAnalysis(m1,dt,numel(recordG)-1, ...
    'Patterns',{gravityPattern,excitation},'Test',g2dyn.normUnbalance(1e-6,50), ...
    'MaxSubdivisions',6,'OnFailure','error'); % default TRBDF2
assert(dynamicResult.Converged,'Ziemian earthquake analysis did not converge.');
history=dynamicResult.History;
time=cellfun(@(d)d.time,history)';
roofDisplacement=cellfun(@(d)d.u(9,1)-gravitySnapshot.u(9,1),history)';
baseShear=cellfun(@(d)sum(d.reactions([1 4 7],1)),history)';
drift=zeros(numel(history),2); plasticFibers=zeros(numel(history),1);
criticalElement=1; criticalSection=1; criticalStep=1; maxStrain=-Inf;
for k=1:numel(history)
    d=history{k}; du=d.u(:,1)-gravitySnapshot.u(:,1);
    drift(k,:)=[max(abs(du([2 5 8])-du([1 4 7])))/6.1 ...
                max(abs(du([3 6 9])-du([2 5 8])))/4.57];
    for e=1:numel(d.elements)
        for s=1:numel(d.elements{e}.secs)
            fibers=d.elements{e}.secs(s).fibers;
            properties=[fibers.pr]; plasticFibers(k)=plasticFibers(k)+sum([properties.cd]~=0);
            strain=max(abs([properties.es]));
            if strain>maxStrain
                maxStrain=strain; criticalElement=e; criticalSection=s; criticalStep=k;
            end
        end
    end
end
peakRoof=max(abs(roofDisplacement));
earthquakeSummary=struct('RecordPath',char(o.RecordPath),'RecordG',recordG, ...
    'RecordTime',recordTime,'Gravity',gravity,'Dt',dt,'FloorLoads',o.FloorLoads, ...
    'Fy',fy,'Hardening',hardening,'DampingRatio',zeta,'Time',time, ...
    'RoofDisplacement',roofDisplacement,'BaseShear',baseShear,'StoryDriftRatio',drift, ...
    'PlasticFibers',plasticFibers,'PeakRoofDisplacement',peakRoof, ...
    'PeakBaseShear',max(abs(baseShear)),'PeakStoryDriftRatio',max(drift,[],1), ...
    'PeakGroundAccelerationG',max(abs(recordG)), ...
    'CriticalElement',criticalElement,'CriticalSection',criticalSection,'CriticalStep',criticalStep, ...
    'MaxFiberStrain',maxStrain);
fprintf('ElCentro: %d samples, dt = %.2f s, duration = %.2f s, PGA = %.4f g\n', ...
    numel(recordG),dt,recordTime(end),max(abs(recordG)));
fprintf('TRBDF2: roof peak %.5g m; base shear peak %.5g kN; drift peaks %.4g / %.4g %%; yielded fibers peak %d; cutbacks %d\n', ...
    peakRoof,max(abs(baseShear)),100*max(drift,[],1),max(plasticFibers),dynamicResult.Cutbacks);
if o.Plot, ziemian_elcentro_plots(history,earthquakeSummary); end
end
function section=equivalentSection(A,I,h,bf)
% Match area and geometric strong-axis inertia with a symmetric rectangular I.
inertia=@(tf)bf*(h^3-(h-2*tf)^3)/12+(A-2*bf*tf)*(h-2*tf)^2/12;
upper=min(A/(2*bf),h/2)*(1-1e-10);
tf=fzero(@(tf)inertia(tf)-I,[eps upper]); tw=(A-2*bf*tf)/(h-2*tf);
section=[h bf tf tw];
end
