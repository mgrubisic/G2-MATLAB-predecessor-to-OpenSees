function [P,lambda,ground,influence]=dynamic_load(mod,patterns,t,M)
n=numel(mod.DOF); P=zeros(n,1); lambda=0;
ground=zeros(1,2); influence=zeros(n,2);
for dir=1:2, influence(mod.DOF(:,dir),dir)=1; end
for i=1:numel(patterns)
    p=patterns{i}; value=g2dyn.evaluate(p.Series,t);
    switch p.Type
        case 'UniformExcitation'
            ground(p.Direction)=ground(p.Direction)+p.Factor*value;
        case 'Plain'
            loads=p.Loads; if isempty(loads), loads=mod.NODELOAD; end
            if ~isempty(loads)
                if ~isequal(size(loads),size(mod.DOF)), error('G2Dyn:Load','Plain Loads must have one row per node and one column per DOF.'); end
                P(mod.DOF(:))=P(mod.DOF(:))+value*loads(:);
            end
            lambda=lambda+p.ElementFactor*value;
        otherwise, error('G2Dyn:Pattern','Unknown load pattern.');
    end
end
P=P-M*influence*ground';
end
