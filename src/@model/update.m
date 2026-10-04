function m=update(mod, ellist, Pfin, Ufin, lambda )
% MODEL/UPDATE Update element list with new state
% M=UPDATE(MOD,ELEMLIST,PFIN,UFIN) Update model MOD with element list ELEMLIST
% and final load vector, PFIN, and final displacement vector, UFIN.
% UPDATE(...,LAMBDA) stores the load factor and a converged visualization state.

if nargin < 5
    [~,~,Pref] = getData(mod);
    if norm(Pref) > 0
        lambda = (Pref' * Pfin) / (Pref' * Pref);
    else
        error('G2:LoadFactorRequired','Specify lambda when reference nodal loads are zero.');
    end
end
if isempty(mod.History), mod.History = {visualData(mod)}; end
mod.ELEMLIST = ellist;
mod.Pfinal   = Pfin;
mod.Ufinal   = Ufin;
mod.Lambda   = lambda;
mod.Solved   = true;
mod.DynamicState = [];
mod.History{end+1} = visualData(mod);

m = mod;
