function properties=modalProperties(mod,varargin)
% MODALPROPERTIES OpenSees-style modal masses and participation for 2D G2.
% p=modalProperties(m,modes,'-print','-file','report.txt','-unorm','-return')
% modes is optional (otherwise computes all finite positive modes).
% Also accepts Print/File/UNorm name-value options. This method is read-only.
modes=[];
if ~isempty(varargin)&&isstruct(varargin{1})
    modes=varargin{1}; varargin(1)=[];
end
args={}; i=1;
while i<=numel(varargin)
    key=char(varargin{i});
    switch lower(key)
        case '-return', i=i+1; continue;
        case '-print', args=[args {'Print',true}]; i=i+1;
        case '-unorm', args=[args {'UNorm',true}]; i=i+1;
        case '-file'
            if i==numel(varargin), error('G2Dyn:ModalOptions','-file requires a filename.'); end
            args=[args {'File',varargin{i+1}}]; i=i+2;
        otherwise
            if i==numel(varargin), error('G2Dyn:ModalOptions','Name/value options require a value.'); end
            args=[args varargin(i:i+1)]; i=i+2;
    end
end
ip=inputParser;
addParameter(ip,'Print',false,@(x)islogical(x)&&isscalar(x));
addParameter(ip,'UNorm',false,@(x)islogical(x)&&isscalar(x));
addParameter(ip,'File','',@(x)ischar(x)||(isstring(x)&&isscalar(x)));
addParameter(ip,'Count',mod.nfree,@(x)isnumeric(x)&&isscalar(x)&&isfinite(x)&&x>0&&x==fix(x));
parse(ip,args{:}); o=ip.Results;
if isempty(modes), modes=modalAnalysis(mod,o.Count); end
if ~all(isfield(modes,{'Shapes','Eigenvalues','Omega','Frequency','Period'}))
    error('G2Dyn:Modes','Expected modalAnalysis results.');
end
nm=numel(modes.Eigenvalues); nd=size(mod.DOF,2); nn=size(mod.DOF,1); n=numel(mod.DOF);
if nm==0||size(modes.Shapes,1)~=nn||size(modes.Shapes,2)~=nd||size(modes.Shapes,3)~=nm
    error('G2Dyn:Modes','Mode shapes do not match this model or no positive modes are available.');
end
[M,masses]=dynamic_mass(mod); [~,K]=dynamicMatrices(mod);
phi=zeros(n,nm); shapes=modes.Shapes;
for j=1:nm
    shape=shapes(:,:,j);
    if any(~isfinite(shape(:)))||any(shape(mod.BOUND~=0)~=0)
        error('G2Dyn:Modes','Modes must be finite and zero on constrained DOFs.');
    end
    phi(mod.DOF(:),j)=shape(:);
end
free=1:mod.nfree; Mf=M(free,free); Kf=K(free,free); pf=phi(free,:);
for j=1:nm
    residual=Kf*pf(:,j)-modes.Eigenvalues(j)*Mf*pf(:,j);
    scale=max(1,norm(Kf*pf(:,j))+norm(modes.Eigenvalues(j)*Mf*pf(:,j)));
    if norm(residual)>1e-7*scale, error('G2Dyn:Modes','Modes are stale or incompatible with the current stiffness and mass.'); end
    if o.UNorm
        peak=max(abs(pf(:,j))); if peak==0, error('G2Dyn:Modes','Zero mode shape.'); end
        phi(:,j)=phi(:,j)/peak; pf(:,j)=pf(:,j)/peak;
        shapes(:,:,j)=shapes(:,:,j)/peak;
    end
end
% HRZ diagonalize each contribution separately, before assembly.
ML=zeros(nn,3);
for node=1:nn
    ML(node,1:nd)=ML(node,1:nd)+hrz(mod.Dynamics.NodalMass{node},nd)';
end
for e=1:numel(masses)
    nodes=mod.CONNECT(e,1:2); diagonal=hrz(masses{e},nd);
    ML(nodes,1:nd)=ML(nodes,1:nd)+reshape(diagonal,nd,2)';
end
MLfree=ML; mask=false(nn,3); mask(:,1:nd)=mod.BOUND==0; MLfree(~mask)=0;
com=zeros(1,2);
for direction=1:2
    weight=sum(MLfree(:,direction));
    if weight>0, com(direction)=sum(mod.XYZ(:,direction).*MLfree(:,direction))/weight;
    elseif any(mask(:,direction)), com(direction)=mean(mod.XYZ(mask(:,direction),direction)); end
end
dx=mod.XYZ(:,1)-com(1); dy=mod.XYZ(:,2)-com(2);
ML(:,3)=ML(:,3)+dx.^2.*ML(:,2)+dy.^2.*ML(:,1);
MLfree(:,3)=MLfree(:,3)+dx.^2.*MLfree(:,2)+dy.^2.*MLfree(:,1);
total=sum(ML,1); totalFree=sum(MLfree,1);
R=zeros(n,3); R(mod.DOF(:,1),1)=1; R(mod.DOF(:,2),2)=1;
R(mod.DOF(:,1),3)=-dy; R(mod.DOF(:,2),3)=dx;
if nd==3, R(mod.DOF(:,3),3)=1; end
gm=full(pf'*Mf*pf); generalizedMass=diag(gm);
if any(generalizedMass<=0), error('G2Dyn:Modes','Modal generalized masses must be positive.'); end
load=full(pf'*Mf*R(free,:));
factors=load./generalizedMass; participation=load.^2./generalizedMass;
ratios=zeros(nm,3);
for direction=1:3
    if totalFree(direction)>0, ratios(:,direction)=100*participation(:,direction)/totalFree(direction); end
end
properties=struct('domainSize',2,'eigenLambda',modes.Eigenvalues(:), ...
    'eigenOmega',modes.Omega(:),'eigenFrequency',modes.Frequency(:),'eigenPeriod',modes.Period(:), ...
    'totalMass',total,'totalFreeMass',totalFree,'centerOfMass',com, ...
    'generalizedMass',generalizedMass,'generalizedMassMatrix',gm, ...
    'modalParticipationFactors',factors,'modalParticipationMasses',participation, ...
    'modalParticipationMassesCumulative',cumsum(participation,1), ...
    'modalParticipationMassRatios',ratios,'modalParticipationMassRatiosCumulative',cumsum(ratios,1), ...
    'Shapes',shapes,'Units',mod.Units,'DisplacementNormalized',o.UNorm, ...
    'HRZMass',ML,'HRZFreeMass',MLfree);
directions={'MX','MY','RMZ'};
prefixes={'partiFactor','partiMass','partiMassesCumu','partiMassRatios','partiMassRatiosCumu'};
matrices={factors,participation,cumsum(participation,1),ratios,cumsum(ratios,1)};
for a=1:numel(prefixes)
    for b=1:3, properties.([prefixes{a} directions{b}])=matrices{a}(:,b); end
end
report=g2dyn.modalReport(properties); properties.Report=report;
if o.Print, fprintf('%s',report); end
if strlength(string(o.File))>0
    [fid,message]=fopen(o.File,'w');
    if fid<0, error('G2Dyn:ReportFile','Cannot open report: %s',message); end
    cleanup=onCleanup(@()fclose(fid)); %#ok<NASGU>
    fprintf(fid,'%s',report);
end
end
function diagonal=hrz(block,nd)
rows=sum(block,2); diagonal=diag(block);
for direction=1:nd
    ids=direction:nd:size(block,1); denominator=sum(diagonal(ids));
    if denominator~=0, diagonal(ids)=diagonal(ids)*sum(rows(ids))/denominator;
    else, diagonal(ids)=0; end
end
end
