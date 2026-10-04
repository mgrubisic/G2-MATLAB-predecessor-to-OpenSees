function [M,K,C,restoring]=dynamicMatrices(mod)
% DYNAMICMATRICES Full matrices in current equation order, including supports.
% At a committed transient state use the stored initial/committed stiffness.
[M,masses,nodeC]=dynamic_mass(mod); elements=mod.ELEMLIST;
U=[mod.Ufinal zeros(numel(mod.Ufinal),2)];
if ~mod.Solved
    for i=1:numel(elements)
        [~,xyz,ue]=localize(mod,i,U); elements{i}=initialize(elements{i},xyz,ue,0);
    end
end
virgin=createElements(mod); zero=zeros(size(U));
for i=1:numel(virgin)
    [~,xyz,ue]=localize(mod,i,zero); virgin{i}=initialize(virgin{i},xyz,ue,0);
end
[~,~,~,K0]=dynamic_assemble(mod,virgin,zero,0,masses,nodeC,{},{});
[~,~,~,Kc]=dynamic_assemble(mod,elements,U,mod.Lambda,masses,nodeC,{},{});
if ~isempty(mod.DynamicState)
    K0=mod.DynamicState.InitialStiffness; Kc=mod.DynamicState.CommittedStiffness;
end
[K,restoring,C]=dynamic_assemble(mod,elements,U,mod.Lambda,masses,nodeC,K0,Kc);
end
