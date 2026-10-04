function result = convert_units(values,quantity,source,target)
% CONVERT_UNITS Explicit dimension-aware conversion between unit descriptors.
% convert_units(12,'Length',units('Imperial'),units('Metric')) -> 3.6576 m
source=g2vis.units(source); target=g2vis.units(target);
quantity=char(quantity);
if ~isfield(source.SI,quantity), error('G2Vis:Quantity','Unknown quantity %s.',quantity); end
validateattributes(values,{'numeric'},{'real'});
result=double(values).*(source.SI.(quantity)/target.SI.(quantity));
end
