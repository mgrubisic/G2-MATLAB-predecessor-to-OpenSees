function h = arrows(ax,xy,forces,s,o,units)
% Separate force and moment scales, so quantities with different units do not mix.
h=gobjects(0); peak=max(sqrt(sum(forces(:,1:2).^2,2)));
fac=o.Scale; if isempty(fac), fac=0; if peak>0, fac=.14*s/peak; end, end
for i=1:size(xy,1)
    f=forces(i,1:2); tip=xy(i,:); tail=tip-fac*f;
    if any(f~=0)
        h(end+1)=quiver(ax,tail(1),tail(2),fac*f(1),fac*f(2),0,'Color',o.Color,'LineWidth',o.LineWidth,'MaxHeadSize',.5);
        if o.Values
            align='left'; if f(1)<0, align='right'; end
            text(ax,tail(1),tail(2),sprintf(' [%.4g, %.4g] %s',f,units.Force), ...
                'FontSize',8,'Color',o.Color,'Interpreter','none','HorizontalAlignment',align);
        end
    end
    if size(forces,2)==3 && forces(i,3)~=0
        moment=forces(i,3); ang=linspace(.2,1.8*pi,45)*sign(moment); radius=.035*s;
        c=tip+radius*[cos(ang)' sin(ang)'];
        h(end+1)=plot(ax,c(:,1),c(:,2),'Color',o.Color,'LineWidth',o.LineWidth);
        % Explicit triangular head remains visible even for tiny quiver segments.
        direction=sign(moment)*[-sin(ang(end)) cos(ang(end))];
        normal=[-direction(2) direction(1)]; headtip=c(end,:);
        back=headtip-.45*radius*direction;
        head=[headtip;back+.22*radius*normal;back-.22*radius*normal];
        h(end+1)=patch(ax,head(:,1),head(:,2),o.Color,'EdgeColor',o.Color, ...
            'Tag','G2VisMomentArrowhead','HandleVisibility','off', ...
            'UserData',struct('Moment',moment,'Direction',direction));
        if o.Values, text(ax,tip(1)+radius,tip(2)+radius,sprintf(' M=%.4g %s',moment,units.Moment),'FontSize',8,'Color',o.Color,'Interpreter','none'); end
    end
end
end
