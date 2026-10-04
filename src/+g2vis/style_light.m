function style_light(target)
% STYLE_LIGHT White plotting surfaces and transparent, frameless legends.
% Apply to a figure/axes to style both existing and subsequently created plots.
if nargin<1, target=gcf; end
if isgraphics(target,'figure'), f=target; else, f=ancestor(target,'figure'); end
if isempty(f), error('G2Vis:Figure','Expected a figure or its graphics child.'); end
ink=[.15 .15 .15];
palette=[.08 .35 .70; .85 .33 .10; .20 .60 .35; .55 .25 .65; .10 .60 .70; .75 .50 .10; .65 .25 .35];
set(f,'Color','w','DefaultAxesColor','w','DefaultAxesXColor',ink, ...
    'DefaultAxesYColor',ink,'DefaultAxesZColor',ink,'DefaultAxesColorOrder',palette, ...
    'DefaultTextColor',ink,'DefaultLegendColor','none','DefaultLegendBox','off', ...
    'DefaultLegendTextColor',ink);
for ax=findall(f,'Type','axes')'
    set(ax,'Color','w','XColor',ink,'YColor',ink,'ZColor',ink,'ColorOrder',palette,'GridColor',[.3 .3 .3]);
end
for lg=findall(f,'Type','legend')'
    set(lg,'Color','none','Box','off','TextColor',ink);
end
for cb=findall(f,'Type','colorbar')', set(cb,'Color',ink); end
for txt=findall(f,'Type','text')'
    % Keep colored data annotations; fix light theme inherited text.
    if all(get(txt,'Color')>.6), set(txt,'Color',ink); end
end
end
