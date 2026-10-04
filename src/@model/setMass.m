function mod=setMass(mod,nodes,values)
% SETMASS Replace concentrated masses by node, in native coherent mass units.
% values: one row per node, one entry per DOF; for one node a symmetric PSD
% DOF-by-DOF block is also accepted. Rotational entry is mass*length^2.
validateattributes(nodes,{'numeric'},{'vector','integer','positive','<=',size(mod.DOF,1)});
validateattributes(values,{'numeric'},{'real','finite','nonempty'});
if numel(unique(nodes))~=numel(nodes), error('G2Dyn:Mass','Node indices must be unique.'); end
nd=size(mod.DOF,2);
if numel(nodes)==1&&isequal(size(values),[nd nd])
    blocks={values};
elseif isequal(size(values),[numel(nodes) nd])
    blocks=cell(numel(nodes),1);
    for i=1:numel(nodes), blocks{i}=diag(values(i,:)); end
else, error('G2Dyn:Mass','Provide one mass row per node or a single-node full block.'); end
for i=1:numel(nodes)
    b=blocks{i}; scale=max(1,norm(b,'fro'));
    if norm(b-b','fro')>1e-12*scale||min(eig((b+b')/2))<-1e-12*scale
        error('G2Dyn:Mass','Nodal mass must be symmetric positive semidefinite.');
    end
end
for i=1:numel(nodes), mod.Dynamics.NodalMass{nodes(i)}=(blocks{i}+blocks{i}')/2; end
end
