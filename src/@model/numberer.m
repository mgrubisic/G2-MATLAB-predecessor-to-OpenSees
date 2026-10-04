function mod=numberer(mod,algorithm)
% NUMBERER Reorder free equations by Plain or Reverse Cuthill-McKee.
% Physical node/DOF indices remain unchanged; call before analysis.
algorithm=validatestring(algorithm,{'Plain','RCM'});
if mod.Solved, error('G2Dyn:Numberer','Set equation numbering before solving the model.'); end
[D,nfree,ntot]=dof_numberer(mod.BOUND);
if strcmp(algorithm,'RCM')&&nfree>0
    graph=sparse(nfree,nfree);
    for i=1:size(mod.CONNECT,1)
        nodes=mod.CONNECT(i,1:end-1); nodes=nodes(nodes>0);
        ids=D(nodes,:); ids=ids(ids<=nfree); graph(ids,ids)=1;
    end
    order=g2dyn.rcm(graph); inverse=zeros(nfree,1); inverse(order)=1:nfree;
    mask=D<=nfree; D(mask)=inverse(D(mask));
end
mod.DOF=D; mod.nfree=nfree; mod.ID=id_numberer(mod.CONNECT,D);
mod.Pfinal=zeros(ntot,1); mod.Ufinal=zeros(ntot,1); mod.Numberer=algorithm;
end
