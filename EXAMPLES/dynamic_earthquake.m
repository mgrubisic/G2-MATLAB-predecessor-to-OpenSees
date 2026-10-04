% Nonlinear fiber column under synthetic ground motion, m-kN-tonne-s.
% This input demonstrates the API; it is not a recorded earthquake.
addpath(fileparts(fileparts(mfilename('fullpath')))); setup_g2;
nelem=3; height=3; xyz=[zeros(nelem+1,1) (0:nelem)'*height/nelem];
bound=zeros(nelem+1,3); bound(1,:)=1;
connect=[(1:nelem)' (2:nelem+1)' repmat(12,nelem,1)];
% h,bf,tf,tw,nf,nw,E[kN/m^2],fy[kN/m^2],hardening,Gauss sections.
material=[.30 .20 .02 .01 3 4 210e6 355e3 .02 3];
m1=model({'Nonlinear earthquake column',xyz,bound,connect, ...
    repmat({material},nelem,1),zeros(nelem+1,3),g2vis.units});
m1=setMass(m1,nelem+1,[5 5 0]);              % 5 tonne concentrated tip mass
m1=setElementMass(m1,1:nelem,7.85,'Quantity','density','Form','consistent');
m1=numberer(m1,'RCM'); modes=modalAnalysis(m1,2);
modalData=modalProperties(m1,modes,'-print');
% Rayleigh factors fitted to 3% at the first two undamped frequencies.
zeta=.03; w=modes.Omega(1:2);
coeff=[1./(2*w) w/2]\[zeta;zeta];
m1=rayleigh(m1,coeff(1),0,coeff(2),0);
dt=.005; duration=3; time=(0:round(duration/dt))'*dt;
frequency=.95*modes.Frequency(1);
ag=6*sin(pi*time/duration).^2.*(sin(2*pi*frequency*time)+.25*sin(2*pi*1.3*time));
accelSeries=g2dyn.timeSeries('Path','Time',time,'Values',ag); % m/s^2
excitation=g2dyn.uniformExcitation(1,accelSeries);
[m1,dynamicResult]=transientAnalysis(m1,dt,numel(time)-1, ...
    'Patterns',{excitation}, ... % default TRBDF2
    'Test',g2dyn.normUnbalance(1e-6,40),'MaxSubdivisions',5);
assert(dynamicResult.Converged,'Nonlinear transient example did not converge.');
history=dynamicResult.History;
peak=cellfun(@(d)abs(d.u(end,1)),history); [~,peakStep]=max(peak);
peakSnapshot=history{peakStep};
g2vis.dynamic_dashboard(m1,nelem+1,1);
g2vis.dashboard(peakSnapshot);
g2vis.plot_mass(m1);
g2vis.plot_nodal_response(peakSnapshot,'absoluteAcceleration','Component','x');
g2vis.plot_time_history(m1,nelem+1,1,'Component','acceleration');
g2vis.plot_time_history(m1,1,1,'Component','reaction');
g2vis.plot_time_history(m1,nelem+1,1,'Component','residualNorm');
g2vis.plot_fiber_section(peakSnapshot,1,1,'Component','stress');
g2vis.plot_section(peakSnapshot,'curvature');
g2vis.viewer(m1);
g2vis.anim_defo(history(1:12:end),'Delay',.02);
