function run_all_examples(outputDirectory)
% RUN_ALL_EXAMPLES Run static and dynamic demos and optionally export figures.
% run_all_examples               interactive figures
% run_all_examples('results')     figures plus PNG/MAT results in output
root=fileparts(fileparts(mfilename('fullpath'))); addpath(root); setup_g2;
if nargin<1, outputDirectory=''; end
if ~isempty(outputDirectory)
    if ~isfolder(outputDirectory), mkdir(outputDirectory); end
    % Make the path absolute before RUN temporarily changes current directory.
    [ok,details]=fileattrib(outputDirectory);
    if ~ok, error('G2Vis:Export','Cannot access output directory.'); end
    outputDirectory=details.Name;
end
for demo={'strongback','ziemian','cantilever','dynamic_linear','dynamic_earthquake','ziemian_elcentro'}
    runDemo(root,demo{1},outputDirectory);
end
end
function runDemo(root,name,out)
before=findall(groot,'Type','figure');
if strcmp(name,'ziemian_elcentro')
    addpath(fullfile(root,'EXAMPLES'));
    [m1,dynamicResult,modalData,earthquakeSummary]=ziemian_elcentro;
else
    run(fullfile(root,'EXAMPLES',[name '.m']));
end
if ~isempty(out)
    figures=setdiff(findall(groot,'Type','figure'),before);
    for j=1:numel(figures)
        % exportgraphics handles regular and tiled axes; viewer includes controls.
        if isempty(findall(figures(j),'Type','uicontrol'))
            exportgraphics(figures(j),fullfile(out,sprintf('%s_%02d.png',name,j)),'Resolution',160);
        else
            ax=findobj(figures(j),'Type','axes');
            exportgraphics(ax(1),fullfile(out,[name '_viewer.png']),'Resolution',160);
        end
    end
    snapshot=visualData(m1); history=visualHistory(m1); %#ok<NASGU>
    if exist('dynamicResult','var')
        % Compressed v7 is efficient for these moderate nested snapshot histories.
        save(fullfile(out,[name '_results.mat']),'snapshot','history','dynamicResult','-v7');
    else, save(fullfile(out,[name '_results.mat']),'snapshot','history'); end
    if exist('modalData','var')
        save(fullfile(out,[name '_results.mat']),'modalData','-append');
        fid=fopen(fullfile(out,[name '_modal_report.txt']),'w');
        if fid<0, error('G2Dyn:ReportFile','Cannot export modal report.'); end
        cleanup=onCleanup(@()fclose(fid));
        fprintf(fid,'%s',modalData.Report); clear cleanup;
    end
    if exist('earthquakeSummary','var')
        save(fullfile(out,[name '_results.mat']),'earthquakeSummary','-append');
    end
    overview=g2vis.dashboard(m1);
    exportgraphics(overview,fullfile(out,[name '_overview.png']),'Resolution',160);
    if exist('dynamicResult','var')
        responseNode=size(snapshot.xyz,1);
        if strcmp(name,'ziemian_elcentro'), responseNode=9; end
        summary=g2vis.dynamic_dashboard(m1,responseNode, ...
            1+strcmp(name,'dynamic_linear'));
        exportgraphics(summary,fullfile(out,[name '_time_history.png']),'Resolution',160);
    end
end
end
