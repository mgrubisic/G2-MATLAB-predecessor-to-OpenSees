function [K,p,C,elementK]=dynamic_assemble(mod,elements,U,lambda,masses,nodeC,Kinitial,Kcommitted)
n=size(U,1); K=sparse(n,n); p=zeros(n,1); C=nodeC; elementK=cell(size(elements));
for i=1:numel(elements)
    [ids,xyz,ue]=localize(mod,i,U); [k,f]=state(elements{i},xyz,ue,lambda);
    if any(~isfinite(k(:)))||any(~isfinite(f(:)))
        error('G2Dyn:ElementState','Element %d returned a nonfinite trial state.',i);
    end
    K(ids,ids)=K(ids,ids)+k; p(ids)=p(ids)+f; elementK{i}=k;
    a=mod.Dynamics.ElementRayleigh(i,:);
    c=a(1)*masses{i}+a(2)*k;
    if ~isempty(Kinitial), c=c+a(3)*Kinitial{i}; end
    if ~isempty(Kcommitted), c=c+a(4)*Kcommitted{i}; end
    C(ids,ids)=C(ids,ids)+c;
end
end
