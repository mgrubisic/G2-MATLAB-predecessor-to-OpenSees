function [mod,result]=transientAnalysis(mod,dt,steps,varargin)
% TRANSIENTANALYSIS Nonlinear TRBDF2/Newmark with convergence and rollback.
% [mod,result]=transientAnalysis(mod,dt,steps,'Patterns',{...})
% Defaults: TRBDF2, NormUnbalance(1e-8,30,2), RCM, 4 cutbacks.
% Initial conditions are nodal matrices. UniformExcitation gives relative
% u/v/a; absolute acceleration is recorded separately. See docs/DYNAMICS.md.
validateattributes(dt,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(steps,{'numeric'},{'scalar','integer','finite','nonnegative'});
ip=inputParser;
addParameter(ip,'Patterns',{g2dyn.plain(g2dyn.timeSeries('Constant'))});
addParameter(ip,'Integrator',g2dyn.trbdf2);
addParameter(ip,'Test',g2dyn.normUnbalance);
addParameter(ip,'Numberer','RCM');
addParameter(ip,'InitialTime',0);
addParameter(ip,'InitialDisplacement',[]);
addParameter(ip,'InitialVelocity',[]);
addParameter(ip,'InitialAcceleration',[]);
addParameter(ip,'MaxSubdivisions',4);
addParameter(ip,'OnFailure','stop');
parse(ip,varargin{:}); o=ip.Results;
if isstruct(o.Patterns), patterns=num2cell(o.Patterns); else, patterns=o.Patterns; end
if ~iscell(patterns), error('G2Dyn:Pattern','Patterns must be a cell array or struct array.'); end
if ~isstruct(o.Integrator)||~isfield(o.Integrator,'Type')
    error('G2Dyn:Integrator','Use g2dyn.trbdf2 or g2dyn.newmark.');
end
switch lower(o.Integrator.Type)
    case 'trbdf2', integrator=g2dyn.trbdf2;
    case 'newmark', integrator=g2dyn.newmark(o.Integrator.Gamma,o.Integrator.Beta);
    otherwise, error('G2Dyn:Integrator','Unknown integrator.');
end
test=g2dyn.normUnbalance(o.Test.Tolerance,o.Test.MaxIterations,o.Test.Norm);
validateattributes(o.InitialTime,{'numeric'},{'scalar','real','finite'});
validateattributes(o.MaxSubdivisions,{'numeric'},{'scalar','integer','finite','nonnegative'});
failureMode=validatestring(o.OnFailure,{'stop','error'});
numbering=validatestring(o.Numberer,{'RCM','Plain'});
if ~mod.Solved, mod=numberer(mod,numbering); end
if mod.Solved&&~ismember('Numberer',ip.UsingDefaults)&&~strcmp(mod.Numberer,numbering)
    error('G2Dyn:Numberer','A solved model retains its existing equation numbering.');
end
nf=mod.nfree; n=numel(mod.DOF); free=1:nf;
if nf==0, error('G2Dyn:NoFreeDOF','Transient analysis needs free equations.'); end
[M,masses,nodeC]=dynamic_mass(mod);
if nnz(M(free,free))==0, error('G2Dyn:NoMass','Define positive mass on at least one free DOF.'); end
elements=mod.ELEMLIST; u=mod.Ufinal; v=zeros(n,1); a=zeros(n,1);
integrationState=struct('Type',integrator.Type,'Stage',1,'Dt',NaN,'PreviousU',u,'PreviousV',v);
virgin=createElements(mod); Uzero=zeros(n,3);
for i=1:numel(virgin)
    [~,xyz,ue]=localize(mod,i,Uzero); virgin{i}=initialize(virgin{i},xyz,ue,0);
end
[~,~,~,K0]=dynamic_assemble(mod,virgin,Uzero,0,masses,nodeC,{},{});
continuing=~isempty(mod.DynamicState);
if continuing
    if ~isempty(o.InitialDisplacement)||~isempty(o.InitialVelocity)||~isempty(o.InitialAcceleration)|| ...
            ~ismember('InitialTime',ip.UsingDefaults)
        error('G2Dyn:InitialState','A continued analysis retains its committed time and state.');
    end
    t=mod.DynamicState.Time; v=mod.DynamicState.Velocity; a=mod.DynamicState.Acceleration;
    K0=mod.DynamicState.InitialStiffness; Kc=mod.DynamicState.CommittedStiffness;
    if isfield(mod.DynamicState,'IntegrationState')&& ...
            strcmp(mod.DynamicState.IntegrationState.Type,integrator.Type)
        integrationState=mod.DynamicState.IntegrationState;
    end
else
    t=o.InitialTime;
    if mod.Solved&&~isempty(o.InitialDisplacement)
        error('G2Dyn:InitialState','InitialDisplacement cannot overwrite a preloaded material state.');
    end
    if ~isempty(o.InitialDisplacement), u=nodalVector(o.InitialDisplacement,'InitialDisplacement'); end
    if ~isempty(o.InitialVelocity), v=nodalVector(o.InitialVelocity,'InitialVelocity'); end
    [P,lambda,ground,influence]=dynamic_load(mod,patterns,t,M);
    if ~mod.Solved
        for i=1:numel(elements)
            [~,xyz,ue]=localize(mod,i,[u u zeros(n,1)]);
            elements{i}=initialize(elements{i},xyz,ue,lambda);
            elements{i}=commit(elements{i},xyz,ue,lambda);
        end
    end
    [~,~,~,Kc]=dynamic_assemble(mod,elements,[u zeros(n,2)],lambda,masses,nodeC,{},{});
    [~,f,C]=dynamic_assemble(mod,elements,[u zeros(n,2)],lambda,masses,nodeC,K0,Kc);
    rhs=P-f-C*v;
    if isempty(o.InitialAcceleration)
        % Range solve supports zero-mass rotations without artificial inertia.
        [Q,D]=eig(full((M(free,free)+M(free,free)')/2)); eigenvalues=diag(D);
        keep=eigenvalues>max(eigenvalues)*1e-12;
        a(free)=Q(:,keep)*((Q(:,keep)'*rhs(free))./eigenvalues(keep));
    else, a=nodalVector(o.InitialAcceleration,'InitialAcceleration'); end
    residual=f+C*v+M*a-P;
    if norm(residual(free),test.Norm)>test.Tolerance
        error('G2Dyn:InitialEquilibrium', ...
            'Initial state violates dynamic equilibrium (norm %.5g). Preload massless DOFs statically or provide consistent initial conditions.',norm(residual(free),test.Norm));
    end
    mod.History={};
    mod=committedModel(elements,u,v,a,t,Kc,P,lambda,ground,influence,residual,0,f);
end
start=t; targetEnd=start+steps*dt; completed=0; cutbacks=0; failure=''; failedTime=NaN;
for step=1:steps
    target=start+step*dt;
    if ~advance(target-t,0)
        failedTime=target; break;
    end
    completed=step;
end
history=mod.History;
if completed==steps, failure=''; end
result=struct('Converged',completed==steps,'CompletedSteps',completed, ...
    'RequestedSteps',steps,'StartTime',start,'EndTime',t,'TargetTime',targetEnd, ...
    'FailedTime',failedTime,'Message',failure,'Cutbacks',cutbacks, ...
    'Integrator',integrator,'Test',test,'Numberer',mod.Numberer, ...
    'Time',cellfun(@(d) d.time,history)', 'History',{history});
if ~result.Converged
    message=sprintf('Stopped at time %.8g; last converged state retained. %s',t,failure);
    if strcmp(failureMode,'error'), error('G2Dyn:NoConvergence','%s',message);
    else, warning('G2Dyn:NoConvergence','%s',message); end
end

    function value=nodalVector(input,label)
        validateattributes(input,{'numeric'},{'real','finite','size',size(mod.DOF)},mfilename,label);
        value=zeros(n,1); value(mod.DOF(:))=input(:);
        if any(value(nf+1:end)~=0), error('G2Dyn:Constraint','Initial conditions must be zero on constrained DOFs.'); end
    end
    function ok=advance(h,depth)
        [ok,message]=attempt(h);
        if ok, return; end
        failure=message;
        % Like OpenSees revertToLastStep: a retry restarts with trapezoidal.
        integrationState.Stage=1; integrationState.Dt=NaN;
        mod.DynamicState.IntegrationState=integrationState;
        if depth<o.MaxSubdivisions
            cutbacks=cutbacks+1;
            ok=advance(h/2,depth+1);
            if ok, ok=advance(h/2,depth+1); end
        end
    end
    function [ok,message]=attempt(h)
        ok=false; message=''; nextTime=t+h;
        [P,lambda,ground,influence]=dynamic_load(mod,patterns,nextTime,M);
        nextIntegration=integrationState;
        if strcmp(integrator.Type,'TRBDF2')&&integrationState.Stage==0&& ...
                abs(h-integrationState.Dt)<=64*eps(max([1 abs(t) abs(nextTime) h integrationState.Dt]))
            % BDF2 applied successively to displacement and velocity.
            a1=1.5/h; a0=a1^2;
            reference=u;
            velocityOffset=.5*(integrationState.PreviousU-u)/h;
            accelerationOffset=a1*velocityOffset+(-2*v+.5*integrationState.PreviousV)/h;
            trial=u; nextIntegration.Stage=1;
        else
            beta=.25; gamma=.5;
            if strcmp(integrator.Type,'Newmark'), beta=integrator.Beta; gamma=integrator.Gamma; end
            a0=1/(beta*h^2); a1=gamma/(beta*h);
            up=u+h*v+h^2*(.5-beta)*a; vp=v+h*(1-gamma)*a;
            reference=up; velocityOffset=vp; accelerationOffset=zeros(n,1);
            trial=up; nextIntegration.Stage=0;
        end
        nextIntegration.Dt=h; nextIntegration.PreviousU=u; nextIntegration.PreviousV=v;
        increment=zeros(n,1);
        for iteration=0:test.MaxIterations
            at=a0*(trial-reference)+accelerationOffset; vt=a1*(trial-reference)+velocityOffset;
            U=[trial trial-u increment];
            try
                [K,f,C,trialK]=dynamic_assemble(mod,elements,U,lambda,masses,nodeC,K0,Kc);
                R=P-f-C*vt-M*at;
                residualNorm=norm(R(free),test.Norm);
                if residualNorm<=test.Tolerance
                    committed=elements;
                    for e=1:numel(elements)
                        [~,xyz,ue]=localize(mod,e,U); committed{e}=commit(elements{e},xyz,ue,lambda);
                    end
                    % Save the tangent evaluated at the accepted trial, not a
                    % stiffness re-evaluated after changing material history.
                    candidate=committedModel(committed,trial,vt,at,nextTime,trialK, ...
                        P,lambda,ground,influence,-R,iteration,f,nextIntegration);
                    elements=committed; Kc=trialK; u=trial; v=vt; a=at; t=nextTime;
                    integrationState=nextIntegration; mod=candidate; ok=true; return;
                end
                if iteration==test.MaxIterations, break; end
                effective=K+a1*C+a0*M;
                increment=zeros(n,1);
                increment(free)=linearSolve(effective(free,free),R(free));
                trial=trial+increment;
            catch exception
                % Uncommitted elements are values, so failed trials cannot
                % leak fiber/plastic history into a retry.
                if startsWith(exception.identifier,'G2Dyn:')||startsWith(exception.identifier,'MATLAB:singular')
                    message=exception.message; return;
                end
                rethrow(exception);
            end
        end
        message=sprintf('Residual %.5g exceeds tolerance %.5g after %d iterations at time %.8g.', ...
            residualNorm,test.Tolerance,test.MaxIterations,nextTime);
    end
    function candidate=committedModel(els,uc,vc,ac,time,Kcommit,P,lambda,ground,influence,residual,iterations,restoring,nextIntegration)
        % Construct the snapshot before publishing any new committed state.
        % A section/recovery failure therefore also rolls back atomically.
        candidate=mod;
        if nargin<14, nextIntegration=integrationState; end
        candidate.ELEMLIST=els; candidate.Ufinal=uc; candidate.Pfinal=P;
        candidate.Lambda=lambda; candidate.Solved=true;
        candidate.DynamicState=struct('Time',time,'Velocity',vc,'Acceleration',ac, ...
            'AbsoluteAcceleration',ac+influence*ground','GroundAcceleration',ground, ...
            'Residual',residual,'ResidualNorm',norm(residual(free),test.Norm), ...
            'Iterations',iterations,'InitialStiffness',{K0},'CommittedStiffness',{Kcommit}, ...
            'MassDiagonal',full(diag(M)),'Restoring',restoring,'IntegrationState',nextIntegration);
        snapshot=visualData(candidate);
        candidate.History{end+1}=snapshot;
    end
end
function x=linearSolve(A,b)
if ~all(isfinite(nonzeros(A)))||~isfinite(condest(A))
    error('G2Dyn:Singular','Effective tangent is singular; check constraints and massless mechanisms.');
end
x=A\b;
if any(~isfinite(x))||norm(A*x-b)>1e-7*max(1,norm(b))
    error('G2Dyn:Singular','Effective tangent solve failed its residual check.');
end
end
