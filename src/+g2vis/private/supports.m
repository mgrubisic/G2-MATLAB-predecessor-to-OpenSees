function h = supports(ax,d,o)
% SUPPORTS OpsVis-style symbols anchored at their node, never at their center.
h=gobjects(0);
if ~o.Supports, return; end
sizeSymbol=.025*span(d); color=[.35 .25 .60]; fill=[.90 .86 .97];
for i=1:size(d.xyz,1)
    b=d.bound(i,:)~=0; if ~any(b), continue; end
    anchor=d.xyz(i,:); a=sizeSymbol;
    if numel(b)==3 && all(b)
        local=[-a/2 0; a/2 0; a/2 -a; -a/2 -a];
    elseif all(b(1:2))
        local=[0 0; -a*.6 -a; a*.6 -a];
    else
        % Uy roller: top contacts the node; Ux roller: left contacts the node.
        angle=linspace(pi/2,pi/2+2*pi,49)';
        local=[a/2*cos(angle) -a/2+a/2*sin(angle)];
        if b(1) && ~b(2), local=[-local(:,2) local(:,1)]; end
    end
    xy=anchor+local;
    h(end+1)=patch(ax,xy(:,1),xy(:,2),fill,'EdgeColor',color,'LineWidth',1.2, ...
        'Tag','G2VisSupport','HandleVisibility','off','UserData',struct('Node',i,'Anchor',anchor));
    if ~all(b(1:2))
        if b(1) && ~b(2), base=anchor+[a -a*.7; a a*.7];
        else, base=anchor+[-a*.7 -a; a*.7 -a]; end
        line(ax,base(:,1),base(:,2),'Color',color,'LineWidth',1.2,'HandleVisibility','off');
    end
end
end
