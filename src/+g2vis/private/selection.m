function ids = selection(d,o)
ids=o.Elements;
if isempty(ids), ids=1:numel(d.elements); end
if any(ids<1|ids>numel(d.elements)|ids~=fix(ids))
    error('G2Vis:Elements','Element indices are outside the model.');
end
ids=ids(:)';
end
