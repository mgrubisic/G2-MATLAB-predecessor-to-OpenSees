function s=timeSeries(type,varargin)
% TIMESERIES Constant, Linear, Sine or linearly interpolated Path time series.
% Path: Values and either Dt or Time; outside path: zero unless UseLast=true.
p=inputParser;
addParameter(p,'Factor',1,@scalarFinite);
addParameter(p,'StartTime',0,@scalarFinite);
addParameter(p,'EndTime',Inf,@(x) scalarFinite(x)||(isscalar(x)&&x==Inf));
addParameter(p,'Period',1,@(x) scalarFinite(x)&&x>0);
addParameter(p,'Phase',0,@scalarFinite);
addParameter(p,'Values',[],@(x) isnumeric(x)&&isreal(x)&&all(isfinite(x(:))));
addParameter(p,'Time',[],@(x) isnumeric(x)&&isreal(x)&&all(isfinite(x(:))));
addParameter(p,'Dt',[],@(x) isempty(x)||(scalarFinite(x)&&x>0));
addParameter(p,'FilePath','',@(x) ischar(x)||(isstring(x)&&isscalar(x)));
addParameter(p,'UseLast',false,@(x) islogical(x)&&isscalar(x));
addParameter(p,'PrependZero',false,@(x) islogical(x)&&isscalar(x));
parse(p,varargin{:}); s=p.Results;
types={'Constant','Linear','Sine','Path'}; ix=find(strcmpi(type,types),1);
if isempty(ix), error('G2Dyn:Series','Unknown time series type.'); end
s.Type=types{ix};
if s.EndTime<s.StartTime, error('G2Dyn:Series','EndTime must not precede StartTime.'); end
if strcmp(s.Type,'Path')
    if strlength(string(s.FilePath))>0
        if ~isempty(s.Values), error('G2Dyn:Series','Use Values or FilePath, not both.'); end
        samples=readmatrix(s.FilePath);
        if ~isnumeric(samples)||~isreal(samples)||any(~isfinite(samples(:)))||isempty(samples)
            error('G2Dyn:Series','Path file must contain finite numeric samples.');
        end
        if size(samples,2)==2&&isempty(s.Time)&&isempty(s.Dt)
            s.Time=samples(:,1); s.Values=samples(:,2);
        elseif isvector(samples), s.Values=samples(:);
        else, error('G2Dyn:Series','Path file requires one sample column or time/value columns.'); end
    end
    if ~isvector(s.Values)||isempty(s.Values), error('G2Dyn:Series','Path requires nonempty Values.'); end
    s.Values=s.Values(:);
    if isempty(s.Time)
        if isempty(s.Dt), error('G2Dyn:Series','Path requires Dt or Time.'); end
        if s.PrependZero, s.Values=[0;s.Values]; end
        s.Time=s.StartTime+(0:numel(s.Values)-1)'*s.Dt;
    else
        if ~isempty(s.Dt)||s.PrependZero, error('G2Dyn:Series','Explicit Time cannot be combined with Dt or PrependZero.'); end
        s.Time=s.Time(:);
        if numel(s.Time)~=numel(s.Values)||any(diff(s.Time)<=0)
            error('G2Dyn:Series','Time and Values must match; Time must strictly increase.');
        end
    end
end
end
function tf=scalarFinite(x)
tf=isnumeric(x)&&isreal(x)&&isscalar(x)&&isfinite(x);
end
