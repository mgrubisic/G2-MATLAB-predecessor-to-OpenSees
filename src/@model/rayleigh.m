function mod=rayleigh(mod,alphaM,betaK,betaK0,betaKc,varargin)
% RAYLEIGH C=alphaM*M+betaK*Ktrial+betaK0*Kinitial+betaKc*Kcommitted.
% By default overwrite all nodes/elements. Nodes/Elements select regions;
% selected nodes receive alphaM only, as in OpenSees.
factors=[alphaM betaK betaK0 betaKc];
validateattributes(factors,{'numeric'},{'real','finite','nonnegative','numel',4});
p=inputParser; addParameter(p,'Nodes',[]); addParameter(p,'Elements',[]); parse(p,varargin{:});
nodes=p.Results.Nodes; elements=p.Results.Elements;
if all(ismember({'Nodes','Elements'},p.UsingDefaults))
    nodes=1:size(mod.DOF,1); elements=1:numel(mod.ELEMLIST);
end
if ~isempty(nodes), validateattributes(nodes,{'numeric'},{'vector','integer','positive','<=',size(mod.DOF,1)}); end
if ~isempty(elements), validateattributes(elements,{'numeric'},{'vector','integer','positive','<=',numel(mod.ELEMLIST)}); end
mod.Dynamics.NodeAlpha(nodes)=alphaM;
mod.Dynamics.ElementRayleigh(elements,:)=repmat(factors,numel(elements),1);
end
