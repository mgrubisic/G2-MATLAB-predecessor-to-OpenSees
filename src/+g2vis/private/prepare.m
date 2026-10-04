function ax = prepare(d,o,label)
ax=o.Axes;
if isempty(ax)
    f=figure('Name',['G2 | ' d.name],'NumberTitle','off','Color','w');
    ax=axes('Parent',f);
end
g2vis.style_light(ax);
hold(ax,'on'); axis(ax,'equal'); grid(ax,'on'); box(ax,'on');
set(ax,'FontName','Helvetica','FontSize',10,'GridAlpha',0.12, ...
    'Color','w','XColor',[.15 .15 .15],'YColor',[.15 .15 .15], ...
    'GridColor',[.3 .3 .3]);
xlabel(ax,['X [' unit_label(d,'Length') ']'],'Interpreter','none');
ylabel(ax,['Y [' unit_label(d,'Length') ']'],'Interpreter','none');
title(ax,[d.name ' | ' label],'Interpreter','none','Color',[.1 .1 .1]);
end
