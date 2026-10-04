function o = options(varargin)
p = inputParser;
p.FunctionName = 'g2vis';
addParameter(p,'Axes',[],@(x) isempty(x)||(isscalar(x)&&isgraphics(x,'axes')));
addParameter(p,'Scale',[],@(x) isempty(x)||(isnumeric(x)&&isscalar(x)&&isfinite(x)));
addParameter(p,'Ratio',0.12,@(x) isnumeric(x)&&isscalar(x)&&isfinite(x)&&x>=0);
addParameter(p,'Points',41,@(x) isnumeric(x)&&isscalar(x)&&x>=3&&x==fix(x));
addParameter(p,'NodeLabels',true,@(x) islogical(x)&&isscalar(x));
addParameter(p,'ElementLabels',true,@(x) islogical(x)&&isscalar(x));
addParameter(p,'Supports',true,@(x) islogical(x)&&isscalar(x));
addParameter(p,'LocalAxes',false,@(x) islogical(x)&&isscalar(x));
addParameter(p,'Undeformed',true,@(x) islogical(x)&&isscalar(x));
addParameter(p,'Fill',true,@(x) islogical(x)&&isscalar(x));
addParameter(p,'Values',true,@(x) islogical(x)&&isscalar(x));
addParameter(p,'Invert',false,@(x) islogical(x)&&isscalar(x));
addParameter(p,'Elements',[],@(x) isnumeric(x)&&(isvector(x)||isempty(x)));
addParameter(p,'Component','magnitude',@(x) ischar(x)||isstring(x));
addParameter(p,'Color',[0.08 0.35 0.70],@(x) isnumeric(x)&&numel(x)==3&&all(x(:)>=0)&&all(x(:)<=1));
addParameter(p,'LineWidth',1.6,@(x) isnumeric(x)&&isscalar(x)&&x>0&&isfinite(x));
parse(p,varargin{:}); o=p.Results;
end
