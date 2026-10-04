function tests=test_modal_trbdf2
tests=functiontests(localfunctions);
end
function setupOnce(~), addpath(fileparts(fileparts(mfilename('fullpath')))); setup_g2; end
function m=oscillator
m=model({'TR oscillator',[0 0;1 0],[1 1 1;0 1 1],[1 2 1],{[4 1]},zeros(2,3)});
m=setMass(m,2,[1 0 0]);
end
function testDefaultAndStageEquations(t)
[m,r]=transientAnalysis(oscillator,.1,4,'Patterns',{},'InitialDisplacement',[0 0 0;.1 0 0]);
verifyEqual(t,r.Integrator.Type,'TRBDF2'); verifyEqual(t,visualData(m).time,.4,'AbsTol',1e-14);
% Independent first-order oscillator solution: trapezoidal then BDF2.
A=[0 1;-4 0]; I=eye(2); y=[.1;0]; previous=y; expected=y;
for i=1:4
    if mod(i,2)==1, next=(I-.05*A)\((I+.05*A)*y);
    else, next=(1.5*I-.1*A)\(2*y-.5*previous); end
    previous=y; y=next; expected(:,end+1)=y; %#ok<AGROW>
end
actual=[cellfun(@(d)d.u(2,1),r.History);cellfun(@(d)d.velocity(2,1),r.History)];
verifyEqual(t,actual,expected,'AbsTol',1e-13);
end
function testTRContinuationAndChangedStep(t)
[m,~]=transientAnalysis(oscillator,.02,3,'Patterns',{},'InitialDisplacement',[0 0 0;.1 0 0]);
[m,r]=transientAnalysis(m,.02,7,'Patterns',{});
[reference,~]=transientAnalysis(oscillator,.02,10,'Patterns',{},'InitialDisplacement',[0 0 0;.1 0 0]);
verifyEqual(t,visualData(m).u,visualData(reference).u,'AbsTol',1e-13);
before=visualData(m); [m,~]=transientAnalysis(m,.01,1,'Patterns',{}); after=visualData(m);
A=[0 1;-4 0]; expected=(eye(2)-.005*A)\((eye(2)+.005*A)*[before.u(2,1);before.velocity(2,1)]);
verifyEqual(t,[after.u(2,1);after.velocity(2,1)],expected,'AbsTol',1e-13);
verifyEqual(t,numel(r.History),11);
end
function testTRAccuracyAndDissipation(t)
error=zeros(1,2);
for j=1:2
    dt=.02/2^(j-1); [~,r]=transientAnalysis(oscillator,dt,round(2/dt),'Patterns',{},'InitialDisplacement',[0 0 0;.1 0 0]);
    d=r.History{end}; error(j)=abs(d.u(2,1)-.1*cos(4));
    energy=cellfun(@(s).5*s.velocity(2,1)^2+2*s.u(2,1)^2,r.History);
    verifyLessThanOrEqual(t,max(energy),.02+1e-12); verifyLessThan(t,energy(end),.02);
end
verifyGreaterThan(t,error(1)/error(2),3.5);
end
function testTRFailureAndCutback(t)
m=model({'Plastic',[0 0;1 0],[1 1 1;0 1 1],[1 2 6],{[4 .1 .2 1]},zeros(2,3)}); m=setMass(m,2,[1 0 0]);
pattern=g2dyn.plain(g2dyn.timeSeries('Linear','Factor',10),'Loads',[0 0 0;1 0 0]);
[~,r]=transientAnalysis(m,.5,1,'Patterns',{pattern},'Test',g2dyn.normUnbalance(1e-9,1),'MaxSubdivisions',8);
verifyTrue(t,r.Converged); verifyGreaterThan(t,r.Cutbacks,0); verifyEqual(t,r.EndTime,.5,'AbsTol',1e-13);
verifyEqual(t,r.Message,'');
end
function testModalSingleMassAndFlags(t)
m=oscillator; modes=modalAnalysis(m,1); before=visualData(m);
p=modalProperties(m,modes,'-return');
verifyEqual(t,p.eigenLambda,4,'AbsTol',1e-12);
verifyEqual(t,p.totalFreeMass,[1 0 0]); verifyEqual(t,p.centerOfMass,[1 0]);
verifyEqual(t,p.generalizedMassMatrix,1,'AbsTol',1e-12);
verifyEqual(t,p.partiMassMX,1,'AbsTol',1e-12); verifyEqual(t,p.partiMassRatiosMX,100,'AbsTol',1e-12);
verifyEqual(t,visualData(m),before);
file=[tempname '.txt']; cleanup=onCleanup(@()delete(file)); %#ok<NASGU>
console=evalc('q=modalProperties(m,modes,''-print'',''-file'',file,''-unorm'');');
verifyTrue(t,contains(console,'MODAL ANALYSIS REPORT')); verifyEqual(t,fileread(file),q.Report);
verifyTrue(t,contains(q.Report,'tonne')); verifyTrue(t,contains(q.Report,'[Hz]'));
verifyError(t,@()modalProperties(m,'-file'),'G2Dyn:ModalOptions');
end
function testModalHRZAndNormalization(t)
m=model({'Beam',[0 0;2 0],[1 1 1;0 0 0],[1 2 2],{[10 1 1]},zeros(2,3)});
m=setElementMass(m,1,3,'Form','consistent'); m=setMass(m,2,[2 2 .4]);
modes=modalAnalysis(m,3); p=modalProperties(m,modes); q=modalProperties(m,modes,'UNorm',true);
verifyEqual(t,p.totalMass(1:2),[8 8],'AbsTol',1e-12);
verifyEqual(t,p.totalFreeMass(1:2),[5 5],'AbsTol',1e-12);
verifyEqual(t,p.centerOfMass,[2 0],'AbsTol',1e-12);
% HRZ direct rotation: sum of both rotational rows = 6*(2*2^2)/420.
verifyEqual(t,p.totalFreeMass(3),.4+6*2^2/420,'AbsTol',1e-12);
verifyEqual(t,p.generalizedMassMatrix,eye(3),'AbsTol',1e-10);
verifyEqual(t,p.modalParticipationMasses,q.modalParticipationMasses,'AbsTol',1e-10);
% Consistent free mass differs from HRZ totals at constrained interfaces.
verifyEqual(t,p.modalParticipationMassRatiosCumulative(end,1:2),[80 100*(2+6*156/420)/5],'AbsTol',1e-10);
verifyEqual(t,squeeze(max(max(abs(q.Shapes),[],1),[],2)),ones(3,1),'AbsTol',1e-12);
verifyGreaterThan(t,norm(p.modalParticipationFactors-q.modalParticipationFactors),1e-3);
end
function testModalNoRotationalDOFAndStale(t)
m=model({'2DOF',[0 0;1 1;2 0],[1 1;0 0;1 1],[1 2 15;2 3 15],{[10 1];[10 1]},zeros(3,2)});
m=setMass(m,2,[2 3]); p=modalProperties(m);
verifySize(t,p.modalParticipationMasses,[2 3]); verifyEqual(t,p.centerOfMass,[1 1]);
verifyEqual(t,p.totalFreeMass,[2 3 0]);
modes=modalAnalysis(m); changed=setMass(m,2,[4 6]);
verifyError(t,@()modalProperties(changed,modes),'G2Dyn:Modes');
end
