function h = visualHistory(mod)
% VISUALHISTORY Initial and successfully committed states only.
h = mod.History;
if isempty(h), h = {visualData(mod)}; end
end
