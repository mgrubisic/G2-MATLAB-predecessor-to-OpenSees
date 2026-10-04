function p=uniformExcitation(direction,series,varargin)
% UNIFORMEXCITATION Translational ground acceleration; response is relative.
validateattributes(direction,{'numeric'},{'scalar','integer','>=',1,'<=',2});
g2dyn.evaluate(series,0);
ip=inputParser; addParameter(ip,'Factor',1,@(x) isnumeric(x)&&isreal(x)&&isscalar(x)&&isfinite(x));
parse(ip,varargin{:});
p=struct('Type','UniformExcitation','Direction',direction,'Series',series,'Factor',ip.Results.Factor);
end
