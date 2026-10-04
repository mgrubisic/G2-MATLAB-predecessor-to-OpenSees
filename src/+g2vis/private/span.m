function s = span(d)
s=max(max(d.xyz,[],1)-min(d.xyz,[],1));
if s<=eps, s=1; end
end
