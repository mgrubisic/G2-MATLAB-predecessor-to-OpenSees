function u = units(system,varargin)
% UNITS Coherent unit metadata; input numbers are never rescaled implicitly.
% Metric defaults: m, kN, tonne, s. Imperial defaults: ft, lbf, slug, s.
% units('Imperial','Length','in','Force','kip') derives kip*s^2/in for mass.
if nargin<1, system='Metric'; end
if isstruct(system)
    if ~all(isfield(system,{'System','Length','Force','Time'}))
        error('G2Vis:Units','Invalid unit descriptor.');
    end
    varargin=[{'Length',system.Length,'Force',system.Force,'Time',system.Time} varargin];
    system=system.System;
end
system=validatestring(char(system),{'Metric','Imperial'});
if strcmp(system,'Metric'), lengthUnit='m'; forceUnit='kN';
else, lengthUnit='ft'; forceUnit='lbf'; end
p=inputParser; addParameter(p,'Length',lengthUnit,@(x) ischar(x)||isstring(x));
addParameter(p,'Force',forceUnit,@(x) ischar(x)||isstring(x));
addParameter(p,'Time','s',@(x) ischar(x)||isstring(x)); parse(p,varargin{:});
u.System=system; u.Length=char(p.Results.Length); u.Force=char(p.Results.Force); u.Time=char(p.Results.Time);
lengths={'m','mm','cm','in','ft'}; lengthSI=[1 .001 .01 .0254 .3048];
forces={'N','kN','lbf','kip'}; forceSI=[1 1000 4.4482216152605 4448.2216152605];
times={'s','ms'}; timeSI=[1 .001];
li=find(strcmp(u.Length,lengths)); fi=find(strcmp(u.Force,forces)); ti=find(strcmp(u.Time,times));
if isempty(li)||isempty(fi)||isempty(ti), error('G2Vis:Units','Unsupported length, force or time unit.'); end
if strcmp(system,'Metric') && (~ismember(u.Length,lengths(1:3))||~ismember(u.Force,forces(1:2)))
    error('G2Vis:Units','Metric uses m/mm/cm and N/kN.');
elseif strcmp(system,'Imperial') && (~ismember(u.Length,lengths(4:5))||~ismember(u.Force,forces(3:4)))
    error('G2Vis:Units','Imperial uses in/ft and lbf/kip.');
end
L=lengthSI(li); F=forceSI(fi); T=timeSI(ti);
u.Rotation='rad'; u.Strain='1'; u.LoadFactor='1'; u.MaterialState='1';
u.Area=[u.Length '^2']; u.Inertia=[u.Length '^4'];
u.Moment=[u.Force '*' u.Length]; u.DistributedLoad=[u.Force '/' u.Length];
u.Stress=[u.Force '/' u.Length '^2'];
if strcmp(u.Length,'in')&&strcmp(u.Force,'kip'), u.Stress='ksi';
elseif strcmp(u.Length,'in')&&strcmp(u.Force,'lbf'), u.Stress='psi'; end
u.Curvature=['1/' u.Length];
u.Velocity=[u.Length '/' u.Time]; u.Acceleration=[u.Length '/' u.Time '^2'];
u.Frequency=['1/' u.Time]; if strcmp(u.Time,'s'), u.Frequency='Hz'; end
u.Mass=[u.Force '*' u.Time '^2/' u.Length];
if strcmp(u.Time,'s')
    if strcmp(u.Length,'m')&&strcmp(u.Force,'kN'), u.Mass='tonne';
    elseif strcmp(u.Length,'m')&&strcmp(u.Force,'N'), u.Mass='kg';
    elseif strcmp(u.Length,'ft')&&strcmp(u.Force,'lbf'), u.Mass='slug'; end
end
u.Density=[u.Mass '/' u.Length '^3'];
if contains(u.Mass,'/'), u.Density=[u.Force '*' u.Time '^2/' u.Length '^4']; end
u.Energy=u.Moment; u.Power=[u.Energy '/' u.Time];
u.Stiffness=u.DistributedLoad; u.Damping=[u.Force '*' u.Time '/' u.Length];
u.AngularVelocity=['rad/' u.Time]; u.AngularAcceleration=['rad/' u.Time '^2'];
u.RotationalInertia=[u.Mass '*' u.Length '^2'];
u.MassPerLength=[u.Mass '/' u.Length];
if contains(u.Mass,'/'), u.MassPerLength=[u.Force '*' u.Time '^2/' u.Length '^2']; end
u.RayleighAlpha=['1/' u.Time]; u.RayleighBeta=u.Time;
u.SI=struct('Length',L,'Force',F,'Time',T,'Mass',F*T^2/L, ...
    'Rotation',1,'Strain',1,'LoadFactor',1,'MaterialState',1, ...
    'Area',L^2,'Inertia',L^4,'Moment',F*L,'DistributedLoad',F/L, ...
    'Stress',F/L^2,'Curvature',1/L,'Velocity',L/T,'Acceleration',L/T^2, ...
    'Frequency',1/T,'Density',F*T^2/L^4,'Energy',F*L,'Power',F*L/T, ...
    'Stiffness',F/L,'Damping',F*T/L,'AngularVelocity',1/T,'AngularAcceleration',1/T^2, ...
    'RotationalInertia',F*T^2*L,'MassPerLength',F*T^2/L^2,'RayleighAlpha',1/T,'RayleighBeta',T);
end
