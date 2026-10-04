function errors=verify_opensees_reference
% Optional cross-engine checks after running opensees_reference.py.
root=fileparts(fileparts(mfilename('fullpath'))); addpath(root); setup_g2;
out=fullfile(root,'results'); errors=zeros(4,3);
for benchmark=1:4
    if mod(benchmark,2)==1
        m=model({'Steel01 equivalent',[0 0;1 0],[1 1 1;0 1 1], ...
            [1 2 6],{[4 .1 .2 1]},zeros(2,3)});
        m=setMass(m,2,[1 0 0]); direction=1; steps=1000; amplitude=8;
        name='opensees_nonlinear';
    else
        m=model({'Consistent mass beam',[0 0;1 0],[1 1 1;0 0 0], ...
            [1 2 2],{[200 1 .01]},zeros(2,3)});
        m=setMass(m,2,[1 1 0]); m=setElementMass(m,1,.2,'Form','consistent');
        m=rayleigh(m,.02,.001,.002,.003); direction=2; steps=200; amplitude=2;
        name='opensees_beam';
    end
    integrator=g2dyn.newmark;
    if benchmark>2, integrator=g2dyn.trbdf2; name=[name '_trbdf2']; end
    reference=readmatrix(fullfile(out,[name '.csv']));
    dt=.01; ts=g2dyn.timeSeries('Path','Dt',dt,'Values',amplitude*sin(2*pi*(0:steps)'*dt));
    if mod(benchmark,2)==1, patterns={g2dyn.uniformExcitation(direction,ts,'Factor',-1)};
    else, patterns={g2dyn.plain(ts,'Loads',[0 -.1 -.2/12;0 -1.1 .2/12],'ElementFactor',0)}; end
    [~,r]=transientAnalysis(m,dt,steps,'Patterns',patterns,'Integrator',integrator,'Test',g2dyn.normUnbalance(1e-9,30));
    assert(r.Converged);
    actual=[cellfun(@(d)d.u(2,direction),r.History)' ...
        cellfun(@(d)d.velocity(2,direction),r.History)' ...
        cellfun(@(d)d.acceleration(2,direction),r.History)'];
    errors(benchmark,:)=max(abs(actual-reference(:,2:4)),[],1);
    fprintf('%s max errors u/v/a: %.4g %.4g %.4g\n',name,errors(benchmark,:));
    assert(max(errors(benchmark,:))<2e-7,'Cross-engine response mismatch.');
end
end
