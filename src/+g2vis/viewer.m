function f = viewer(m)
% VIEWER Interactive plot selector and converged-step slider, with PNG export.
if isa(m,'model'), snapshots=visualHistory(m);
elseif iscell(m), snapshots=m; else, snapshots={data(m)}; end
last=snapshots{end}; step=numel(snapshots);
f=figure('Name',['G2 viewer | ' last.name],'NumberTitle','off','Color','w','Position',[120 100 1100 760]);
ax=axes('Parent',f,'Position',[.08 .17 .84 .70]);
choices={'Model','Deformation','Displacement magnitude','N','V','M','Loads','Reactions'};
if isfield(last,'time'), choices=[choices {'Velocity','Acceleration','Absolute acceleration','Masses'}]; end
fiberIds=find(cellfun(@(e) isfield(e,'secs'),last.elements));
fiber=[]; section=1;
if ~isempty(fiberIds), fiber=fiberIds(1); end
if ~isempty(fiber), choices=[choices {'Curvature','Axial strain','Fiber stress','Fiber strain'}]; end
mode=uicontrol(f,'Style','popupmenu','Tag','G2VisMode','String',choices,'Value',2,'Units','normalized','Position',[.03 .94 .21 .04],'Callback',@redraw);
uicontrol(f,'Style','text','String','Scale (empty = auto)','Units','normalized','Position',[.26 .94 .16 .03],'BackgroundColor','w');
scaleBox=uicontrol(f,'Style','edit','String','','Units','normalized','Position',[.43 .94 .10 .04],'Callback',@redraw);
invertBox=uicontrol(f,'Style','checkbox','String','Invert M','Value',false,'Units','normalized', ...
    'Position',[.03 .88 .15 .035],'Tag','G2VisInvert','Callback',@redraw);
if ~isempty(fiber)
    labels=arrayfun(@(i) sprintf('Fiber element %d',i),fiberIds,'UniformOutput',false);
    elementBox=uicontrol(f,'Style','popupmenu','Tag','G2VisFiberElement','String',labels,'Units','normalized','Position',[.55 .94 .14 .04],'Callback',@changeFiber);
    sectionBox=uicontrol(f,'Style','popupmenu','Tag','G2VisFiberSection','String',sectionLabels(fiber),'Units','normalized','Position',[.70 .94 .07 .04],'Callback',@changeSection);
end
uicontrol(f,'Style','pushbutton','String','Export PNG','Units','normalized','Position',[.77 .94 .19 .04],'Callback',@saveImage);
status=uicontrol(f,'Style','text','Units','normalized','Position',[.03 .02 .94 .05],'BackgroundColor','w','HorizontalAlignment','left');
slider=uicontrol(f,'Style','slider','Min',1,'Max',max(2,step),'Value',step,'Units','normalized','Position',[.15 .09 .7 .035],'Callback',@changeStep);
if step==1, set(slider,'Enable','off'); else, set(slider,'SliderStep',[1/(step-1) min(1,5/(step-1))]); end
set(findall(f,'Type','uicontrol'),'ForegroundColor',[.15 .15 .15],'BackgroundColor',[.96 .96 .96]);
redraw();
    function labels=sectionLabels(element)
        labels=arrayfun(@(i) sprintf('IP %d',i),1:last.elements{element}.nsecs,'UniformOutput',false);
    end
    function changeFiber(~,~)
        fiber=fiberIds(get(elementBox,'Value')); section=1;
        set(sectionBox,'String',sectionLabels(fiber),'Value',1); redraw();
    end
    function changeSection(~,~)
        section=get(sectionBox,'Value'); redraw();
    end
    function changeStep(~,~)
        step=min(numel(snapshots),max(1,round(get(slider,'Value')))); redraw();
    end
    function redraw(varargin)
        d=snapshots{step}; scale=str2double(get(scaleBox,'String'));
        if isempty(strtrim(get(scaleBox,'String'))), scale=[];
        elseif ~isfinite(scale), set(status,'String','Scale must be a finite number.'); return; end
        colorbar(ax,'off'); legend(ax,'off');
        cla(ax,'reset'); args={'Axes',ax,'Scale',scale}; choice=choices{get(mode,'Value')};
        switch choice
            case 'Model', g2vis.plot_model(d,args{:});
            case 'Deformation', g2vis.plot_defo(d,args{:});
            case 'Displacement magnitude', g2vis.plot_displacements(d,args{:});
            case {'N','V','M'}, g2vis.section_force_diagram_2d(d,choice,args{:},'Invert',logical(get(invertBox,'Value')));
            case 'Loads', g2vis.plot_load(d,args{:});
            case 'Reactions', g2vis.plot_reactions(d,args{:});
            case 'Velocity', g2vis.plot_nodal_response(d,'velocity',args{:});
            case 'Acceleration', g2vis.plot_nodal_response(d,'acceleration',args{:});
            case 'Absolute acceleration', g2vis.plot_nodal_response(d,'absoluteAcceleration',args{:});
            case 'Masses', g2vis.plot_mass(d,args{:});
            case 'Curvature', g2vis.plot_section(d,'curvature',args{:});
            case 'Axial strain', g2vis.plot_section(d,'strain',args{:});
            case 'Fiber stress', g2vis.plot_fiber_section(d,fiber,section,args{:},'Component','stress');
            case 'Fiber strain', g2vis.plot_fiber_section(d,fiber,section,args{:},'Component','strain');
        end
        d=data(d);
        stateLabel=sprintf('lambda %.6g [1]',d.lambda);
        if isfield(d,'time'), stateLabel=sprintf('t %.6g [%s] | relative u/v/a',d.time,d.units.Time); end
        set(status,'String',sprintf('Converged step %d/%d | %s | %s: X/Y [%s], F [%s], M [%s]', ...
            step-1,numel(snapshots)-1,stateLabel,d.units.System,d.units.Length,d.units.Force,d.units.Moment));
    end
    function saveImage(~,~)
        [file,path]=uiputfile('*.png','Export current view');
        if ~isequal(file,0), exportgraphics(ax,fullfile(path,file),'Resolution',180); end
    end
end
