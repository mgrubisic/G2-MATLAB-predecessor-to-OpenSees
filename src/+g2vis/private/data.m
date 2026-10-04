function d = data(m)
if isa(m,'model'), d=visualData(m); else, d=m; end
if ~isstruct(d)||~all(isfield(d,{'xyz','connect','u','elements'}))
    error('G2Vis:Model','Expected a G2 model or visualData snapshot.');
end
if ~isfield(d,'units'), d.units=g2vis.units; else, d.units=g2vis.units(d.units); end
if size(d.xyz,2)~=2 || ~ismember(size(d.u,2),[2 3]) || size(d.connect,2)~=3
    error('G2Vis:Dimension','Current G2 elements support two-node models in the XY plane.');
end
if isempty(d.xyz)||any(~isfinite(d.xyz(:)))||any(~isfinite(d.u(:)))
    error('G2Vis:Data','Coordinates and displacements must be finite and nonempty.');
end
end
