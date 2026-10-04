function p=plain(series,varargin)
% PLAIN Time-dependent nodal loads and factor on reference element loads.
% Omitted Loads uses model NODELOAD. ElementFactor defaults to 1.
g2dyn.evaluate(series,0); ip=inputParser;
addParameter(ip,'Loads',[],@(x) isnumeric(x)&&isreal(x)&&all(isfinite(x(:))));
addParameter(ip,'ElementFactor',1,@(x) isnumeric(x)&&isreal(x)&&isscalar(x)&&isfinite(x));
parse(ip,varargin{:});
p=struct('Type','Plain','Series',series,'Loads',ip.Results.Loads,'ElementFactor',ip.Results.ElementFactor);
end
