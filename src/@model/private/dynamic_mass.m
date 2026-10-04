function [M,elementMass,nodeC]=dynamic_mass(mod)
n=numel(mod.DOF); nd=size(mod.DOF,2); M=sparse(n,n); nodeC=sparse(n,n);
for i=1:size(mod.DOF,1)
    ids=mod.DOF(i,:); block=mod.Dynamics.NodalMass{i};
    M(ids,ids)=M(ids,ids)+block;
    nodeC(ids,ids)=nodeC(ids,ids)+mod.Dynamics.NodeAlpha(i)*block;
end
elementMass=cell(1,numel(mod.ELEMLIST));
for i=1:numel(mod.ELEMLIST)
    [ids,xyz]=localize(mod,i,mod.Ufinal);
    block=g2dyn.elementMass(xyz,nd,mod.CONNECT(i,end), ...
        mod.Dynamics.MassPerLength(i),mod.Dynamics.MassForm{i});
    elementMass{i}=block; M(ids,ids)=M(ids,ids)+block;
end
end
