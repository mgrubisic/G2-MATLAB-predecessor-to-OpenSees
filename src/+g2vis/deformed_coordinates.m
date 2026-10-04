function [curves,scale] = deformed_coordinates(m,varargin)
% DEFORMED_COORDINATES Hermite beam curves; trusses use straight segments.
% Scale is a direct multiplier; automatic scale uses sampled curve extrema.
d=data(m); o=options(varargin{:}); ids=selection(d,o);
curves=cell(1,numel(d.elements)); disps=curves; bases=curves; peak=0;
r=linspace(0,1,o.Points)';
for i=ids
    e=d.elements{i}; xy=d.xyz(e.nodes,:); L=norm(diff(xy));
    t=diff(xy)/L; n=[-t(2) t(1)]; u=d.u(e.nodes,1:2);
    ul=u*t'; vl=u*n';
    a=(1-r)*ul(1)+r*ul(2);
    v=(1-r)*vl(1)+r*vl(2);
    if ismember(e.type,[2 3 8 12 13])
        theta=d.u(e.nodes,3);
        if e.type==3, theta=theta-e.response(7:8)'; end
        v=(1-3*r.^2+2*r.^3)*vl(1)+(r-2*r.^2+r.^3)*L*theta(1) ...
            +(3*r.^2-2*r.^3)*vl(2)+(-r.^2+r.^3)*L*theta(2);
        if ismember(e.type,[2 3])
            v=v+e.uniform(2)/(24*e.e*e.I)*(L*r).^2.*(L*(1-r)).^2;
        end
    end
    bases{i}=(1-r)*xy(1,:)+r*xy(2,:);
    disps{i}=a*t+v*n;
    peak=max(peak,max(sqrt(sum(disps{i}.^2,2))));
end
scale=o.Scale;
if isempty(scale)
    scale=0;
    if peak>0, scale=o.Ratio*span(d)/peak; end
end
for i=ids, curves{i}=bases{i}+scale*disps{i}; end
end
