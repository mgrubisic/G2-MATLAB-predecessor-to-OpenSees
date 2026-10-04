function verify_examples
% VERIFY_EXAMPLES End-to-end examples; release figure resources between demos.
% The full earthquake analysis runs without GUI windows; graphics are covered
% by the other examples and the MATLAB visualization regression tests.
root=fileparts(fileparts(mfilename('fullpath'))); addpath(root); setup_g2;
visible=get(groot,'defaultFigureVisible'); set(groot,'defaultFigureVisible','off');
cleanup=onCleanup(@()restore(visible)); %#ok<NASGU>
for name={'strongback','ziemian','cantilever','dynamic_linear','dynamic_earthquake','ziemian_elcentro'}
    fprintf('Verifying example: %s\n',name{1});
    verifyOne(root,name{1}); close all;
end
fprintf('All six examples verified.\n');
end
function verifyOne(root,name)
if strcmp(name,'ziemian_elcentro')
    log=evalc('[m1,dynamicResult,~,summary]=ziemian_elcentro(''Plot'',false);'); %#ok<NASGU>
    assert(dynamicResult.Converged&&dynamicResult.CompletedSteps==1559);
    assert(abs(dynamicResult.EndTime-31.18)<1e-10);
    assert(max(summary.PlasticFibers)>0);
else
    log=evalc('run(fullfile(root,''EXAMPLES'',[name ''.m'']));'); %#ok<NASGU>
    assert(visualData(m1).solved);
    if exist('dynamicResult','var'), assert(dynamicResult.Converged); end
end
end
function restore(visible)
close all; set(groot,'defaultFigureVisible',visible);
end
