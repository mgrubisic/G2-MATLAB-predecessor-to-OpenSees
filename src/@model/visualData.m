function d = visualData(mod)
% VISUALDATA Read-only snapshot for g2vis; vectors use nodal ordering.
% End forces are [Ni Vi Mi Nj Vj Mj] in local element axes.
d.name = mod.NAME;
d.units = mod.Units;
d.xyz = mod.XYZ;
d.bound = mod.BOUND;
d.dof = mod.DOF;
d.connect = mod.CONNECT;
d.u = reshape(mod.Ufinal(mod.DOF),size(mod.DOF));
d.loads = zeros(size(mod.DOF));
if ~isempty(mod.NODELOAD), d.loads = mod.NODELOAD; end
d.lambda = mod.Lambda;
d.solved = mod.Solved;
d.applied = d.lambda*d.loads;
d.analysis = 'static';
d.elements = cell(1,numel(mod.ELEMLIST));
restoring = zeros(size(mod.Ufinal));
for i=1:numel(mod.ELEMLIST)
    [id,xyz,ue] = localize(mod,i,mod.Ufinal);
    el = mod.ELEMLIST{i};
    if ~mod.Solved, el = initialize(el,xyz,[],0); end
    uv = [ue zeros(size(ue)) zeros(size(ue))];
    [~,p] = state(el,xyz,uv,mod.Lambda);
    restoring(id) = restoring(id)+p;
    e = struct(el);
    if isfield(e,'secs')
        e.sectionDimensions = mod.MATERIAL{i}(1:4);
        % Portable snapshots must not retain legacy MATLAB class instances.
        e.secs = struct(e.secs);
    end
    e.type = mod.CONNECT(i,end);
    e.nodes = mod.CONNECT(i,1:2);
    e.response = printResp(el,xyz,uv,mod.Lambda,'noprint');
    dx = xyz(2,1:2)-xyz(1,1:2);
    if e.type == 15, dx = dx + ue(3:4)'-ue(1:2)'; end
    e.length = norm(dx);
    if e.length <= eps, error('G2:ZeroLength','Element %d has zero length.',i); end
    e.tangent = dx/e.length;
    t = e.tangent; n = [-t(2) t(1)];
    if numel(p)==4
        e.endForces = [t*p(1:2) n*p(1:2) 0 t*p(3:4) n*p(3:4) 0];
    else
        e.endForces = [t*p(1:2) n*p(1:2) p(3) t*p(4:5) n*p(4:5) p(6)];
    end
    % Uniform loads follow actual element equilibrium, including legacy q signs.
    e.uniform = -(e.endForces(1:2)+e.endForces(4:5))/e.length;
    d.elements{i} = e;
end
r = restoring-mod.Pfinal;
d.restoringForces=reshape(restoring(mod.DOF),size(mod.DOF));
d.residual = reshape(r(mod.DOF),size(mod.DOF));
d.reactions = d.residual;
d.reactions(mod.BOUND==0) = 0;
if ~isempty(mod.DynamicState)
    s=mod.DynamicState; d.analysis='transient'; d.time=s.Time;
    d.velocity=reshape(s.Velocity(mod.DOF),size(mod.DOF));
    d.acceleration=reshape(s.Acceleration(mod.DOF),size(mod.DOF));
    d.absoluteAcceleration=reshape(s.AbsoluteAcceleration(mod.DOF),size(mod.DOF));
    d.groundAcceleration=s.GroundAcceleration;
    d.applied=reshape(mod.Pfinal(mod.DOF),size(mod.DOF));
    d.residual=reshape(s.Residual(mod.DOF),size(mod.DOF));
    d.reactions=d.residual; d.reactions(mod.BOUND==0)=0;
    d.massDiagonal=reshape(s.MassDiagonal(mod.DOF),size(mod.DOF));
    d.restoringForces=reshape(s.Restoring(mod.DOF),size(mod.DOF));
    d.massPerLength=mod.Dynamics.MassPerLength;
    d.massForm=mod.Dynamics.MassForm;
    d.iterations=s.Iterations; d.residualNorm=s.ResidualNorm;
end
if ~isfield(d,'massDiagonal')
    [M,~,~]=dynamic_mass(mod); d.massDiagonal=reshape(full(diag(M(mod.DOF(:),mod.DOF(:)))),size(mod.DOF));
    d.massPerLength=mod.Dynamics.MassPerLength; d.massForm=mod.Dynamics.MassForm;
end
end
