% Linear free vibration: concentrated + consistent distributed mass, m-kN-tonne-s.
addpath(fileparts(fileparts(mfilename('fullpath')))); setup_g2;
m1=model({'Linear dynamic cantilever',[0 0;2 0],[1 1 1;0 0 0], ...
    [1 2 2],{[210e6 .02 2e-4]},zeros(2,3),g2vis.units});
m1=setMass(m1,2,[2 2 0]);                    % 2 tonne at the tip
m1=setElementMass(m1,1,.15,'Form','consistent'); % tonne/m
m1=numberer(m1,'RCM');
modes=modalAnalysis(m1,2);
modalData=modalProperties(m1,modes,'-print');
zeta=.03; w=modes.Omega(1);
m1=rayleigh(m1,2*zeta*w,0,0,0);              % 3% damping in first mode
shape=modes.Shapes(:,:,1); shape=.01*shape/max(vecnorm(shape(:,1:2),2,2));
[m1,dynamicResult]=transientAnalysis(m1,.002,500,'Patterns',{}, ...
    'InitialDisplacement',shape, ... % default TRBDF2; Newmark remains optional
    'Test',g2dyn.normUnbalance(1e-7,30));
assert(dynamicResult.Converged,'Linear transient example did not converge.');
g2vis.dynamic_dashboard(m1,2,2);
g2vis.plot_mass(m1);
g2vis.plot_nodal_response(m1,'velocity','Component','y');
g2vis.plot_nodal_response(m1,'absoluteAcceleration','Component','y');
g2vis.plot_time_history(m1,1,2,'Component','reaction');
g2vis.viewer(m1);
% A short animation uses converged physical time, not static load factor.
g2vis.anim_defo(dynamicResult.History(1:10:end),'Delay',.02);
