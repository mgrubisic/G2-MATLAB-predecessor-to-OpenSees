function modes=modalAnalysis(mod,count)
% MODALANALYSIS Finite positive modes; statically condense zero-mass DOFs.
% Shapes are nodal arrays, mass normalized; uses current tangent stiffness.
if nargin<2, count=mod.nfree; end
validateattributes(count,{'numeric'},{'scalar','integer','positive','finite'});
[M,K]=dynamicMatrices(mod); free=1:mod.nfree; M=full(M(free,free)); K=full(K(free,free));
if norm(K-K','fro')>1e-9*max(1,norm(K,'fro')), error('G2Dyn:Modal','Modal analysis requires symmetric stiffness.'); end
[Q,D]=eig((M+M')/2); mass=diag(D); keep=mass>max([mass;0])*1e-12;
if ~any(keep), error('G2Dyn:NoMass','Modal analysis requires positive free-DOF mass.'); end
Qm=Q(:,keep); Qz=Q(:,~keep); transform=Qm;
if ~isempty(Qz)
    Kzz=Qz'*K*Qz;
    if rcond(Kzz)<eps, error('G2Dyn:Singular','Unrestrained massless mechanism.'); end
    transform=Qm-Qz*(Kzz\(Qz'*K*Qm));
end
reducedK=transform'*K*transform; reducedM=diag(mass(keep));
[phi,D]=eig((reducedK+reducedK')/2,reducedM); values=real(diag(D));
valid=find(isfinite(values)&values>0); [~,order]=sort(values(valid)); valid=valid(order);
valid=valid(1:min(count,numel(valid))); values=values(valid); phi=transform*phi(:,valid);
shapes=zeros([size(mod.DOF) numel(valid)]);
for i=1:numel(valid)
    phi(:,i)=phi(:,i)/sqrt(phi(:,i)'*M*phi(:,i));
    [~,j]=max(abs(phi(:,i))); if phi(j,i)<0, phi(:,i)=-phi(:,i); end
    fullShape=zeros(numel(mod.DOF),1); fullShape(free)=phi(:,i);
    shapes(:,:,i)=reshape(fullShape(mod.DOF),size(mod.DOF));
end
modes=struct('Eigenvalues',values,'Omega',sqrt(values),'Frequency',sqrt(values)/(2*pi), ...
    'Period',2*pi./sqrt(values),'Shapes',shapes,'Units',mod.Units,'Numberer',mod.Numberer);
end
