function mod=setElementMass(mod,elements,values,varargin)
% SETELEMENTMASS Uniform mass/length (default) or material mass density.
% Name/value: Form ('lumped' default, 'consistent'), Quantity ('line'/'density').
validateattributes(elements,{'numeric'},{'vector','integer','positive','<=',numel(mod.ELEMLIST)});
validateattributes(values,{'numeric'},{'vector','real','finite','nonnegative'});
if numel(unique(elements))~=numel(elements), error('G2Dyn:Mass','Element indices must be unique.'); end
p=inputParser; addParameter(p,'Form','lumped'); addParameter(p,'Quantity','line'); parse(p,varargin{:});
form=validatestring(p.Results.Form,{'lumped','consistent'});
quantity=validatestring(p.Results.Quantity,{'line','density'});
if isscalar(values), values=repmat(values,numel(elements),1); end
if numel(values)~=numel(elements), error('G2Dyn:Mass','Provide a scalar or one value per element.'); end
for j=1:numel(elements)
    i=elements(j); e=struct(mod.ELEMLIST{i}); mu=values(j);
    if strcmp(quantity,'density')
        if isfield(e,'a'), area=e.a;
        elseif isfield(e,'secs')
            section=struct(e.secs(1)); area=sum([section.fibers.ar]);
        else, error('G2Dyn:Mass','Element has no cross-sectional area.'); end
        mu=mu*area;
    end
    [~,xyz]=localize(mod,i,mod.Ufinal);
    g2dyn.elementMass(xyz,size(mod.DOF,2),mod.CONNECT(i,end),mu,form);
    mod.Dynamics.MassPerLength(i)=mu; mod.Dynamics.MassForm{i}=form;
end
end
