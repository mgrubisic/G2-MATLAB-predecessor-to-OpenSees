function h = label_values(ax,xy,values,color)
% LABEL_VALUES Signed end/extreme values; constant curves receive one label.
if nargin<4, color=[.08 .35 .70]; end
values=values(:); h=gobjects(0);
valid=isfinite(values)&all(isfinite(xy),2);
xy=xy(valid,:); values=values(valid); if isempty(values), return; end
[lo,imin]=min(values); [hi,imax]=max(values);
tol=max(1,max(abs(values)))*1e-10;
ids=unique([1 imin imax numel(values)]);
if hi-lo<tol, ids=ceil(numel(values)/2); end
for i=ids
    value=values(i); if abs(value)<tol, value=0; end
    h(end+1)=text(ax,xy(i,1),xy(i,2),sprintf(' %.4g',value),'Color',color, ...
        'FontSize',8,'VerticalAlignment','bottom','Tag','G2VisValue', ...
        'HandleVisibility','off');
end
end
