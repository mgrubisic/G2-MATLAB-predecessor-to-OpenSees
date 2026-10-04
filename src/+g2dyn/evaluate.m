function y=evaluate(s,t)
% EVALUATE Evaluate a time series at scalar or array time in native time units.
validateattributes(t,{'numeric'},{'real','finite'});
if ~isstruct(s)||~isfield(s,'Type'), error('G2Dyn:Series','Expected g2dyn.timeSeries.'); end
y=zeros(size(t)); active=t>=s.StartTime&t<=s.EndTime;
switch s.Type
    case 'Constant', y(active)=s.Factor;
    case 'Linear', y(active)=s.Factor*(t(active)-s.StartTime);
    case 'Sine', y(active)=s.Factor*sin(2*pi*(t(active)-s.StartTime)/s.Period+s.Phase);
    case 'Path'
        active=t>=s.Time(1)&t<=s.Time(end);
        if numel(s.Time)==1, y(t==s.Time(1))=s.Values(1);
        else, y(active)=interp1(s.Time,s.Values,t(active),'linear'); end
        if s.UseLast, y(t>s.Time(end))=s.Values(end); end
        y=s.Factor*y;
    otherwise, error('G2Dyn:Series','Unknown time series type.');
end
end
