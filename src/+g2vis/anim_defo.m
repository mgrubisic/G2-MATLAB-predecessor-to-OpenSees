function [f,h] = anim_defo(m,varargin)
% ANIM_DEFO Animate converged shapes at a fixed scale; optional GIF output.
% Name/value: Filename (empty = display only), Delay (seconds), Repeat (count).
p=inputParser; addParameter(p,'Filename','',@(x) ischar(x)||isstring(x));
addParameter(p,'Delay',.08,@(x) isnumeric(x)&&isscalar(x)&&isfinite(x)&&x>=0);
addParameter(p,'Repeat',1,@(x) isnumeric(x)&&isscalar(x)&&x>=1&&x==fix(x));
parse(p,varargin{:}); o=p.Results;
if isa(m,'model'), snapshots=visualHistory(m); else, snapshots=m; end
if ~iscell(snapshots)||isempty(snapshots), error('G2Vis:History','Expected model or snapshot history.'); end
d=data(snapshots{end}); peak=0;
for k=1:numel(snapshots)
    [c,~]=g2vis.deformed_coordinates(snapshots{k},'Scale',1);
    for i=1:numel(c)
        e=d.elements{i}; r=linspace(0,1,size(c{i},1))'; xy=d.xyz(e.nodes,:);
        u=c{i}-((1-r)*xy(1,:)+r*xy(2,:)); peak=max(peak,max(sqrt(sum(u.^2,2))));
    end
end
scale=0; if peak>0, scale=.12*span(d)/peak; end
f=figure('Name',['G2 animation | ' d.name],'NumberTitle','off','Color','w'); ax=axes('Parent',f);
[~,h]=g2vis.plot_defo(snapshots{1},'Axes',ax,'Scale',scale,'Values',false);
% Fixed limits from all sampled steps prevent viewport jumping and clipping.
xy=d.xyz;
for k=1:numel(snapshots)
    c=g2vis.deformed_coordinates(snapshots{k},'Scale',scale); xy=[xy;vertcat(c{:})]; %#ok<AGROW>
end
pad=.08*span(d); axis(ax,[min(xy(:,1))-pad max(xy(:,1))+pad min(xy(:,2))-pad max(xy(:,2))+pad]);
frame=0;
for repeat=1:o.Repeat
    for k=1:numel(snapshots)
        if ~isgraphics(f), return; end
        c=g2vis.deformed_coordinates(snapshots{k},'Scale',scale);
        actual=g2vis.deformed_coordinates(snapshots{k},'Scale',1);
        delete(findall(ax,'Tag','G2VisValue'));
        for i=1:numel(h), set(h(i),'XData',c{i}(:,1),'YData',c{i}(:,2)); end
        for i=1:numel(c)
            e=d.elements{i}; r=linspace(0,1,size(c{i},1))'; xy=d.xyz(e.nodes,:);
            u=actual{i}-((1-r)*xy(1,:)+r*xy(2,:));
            g2vis.label_values(ax,c{i},sqrt(sum(u.^2,2)));
        end
        stateLabel=sprintf('lambda %.5g [1]',snapshots{k}.lambda);
        if isfield(snapshots{k},'time'), stateLabel=sprintf('t %.5g [%s]',snapshots{k}.time,unit_label(d,'Time')); end
        title(ax,sprintf('%s | %s | |u| [%s] | scale %.4g [1]', ...
            d.name,stateLabel,unit_label(d,'Length'),scale),'Interpreter','none'); drawnow;
        if strlength(string(o.Filename))>0
            rgb=frame2im(getframe(f)); [im,map]=rgb2ind(rgb,256); frame=frame+1;
            if frame==1, imwrite(im,map,o.Filename,'gif','LoopCount',Inf,'DelayTime',max(.02,o.Delay));
            else, imwrite(im,map,o.Filename,'gif','WriteMode','append','DelayTime',max(.02,o.Delay)); end
        end
        if o.Delay>0, pause(o.Delay); end
    end
end
end
