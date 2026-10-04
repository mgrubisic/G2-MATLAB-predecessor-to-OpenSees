function varargout = plot(mod, label, ratio)
% PLOT Legacy entry point backed by g2vis (ratio defaults to 0.15).
if nargin<2, label = ''; end
if nargin<3, ratio = 0.15; end
[ax,~,s] = g2vis.plot_defo(mod,'Ratio',ratio);
if ~isempty(label)
    unitsLabel=['|u| [' mod.Units.Length ']'];
    if iscell(label), label=[label(:);{unitsLabel}]; else, label=[char(label) ' | ' unitsLabel]; end
    title(ax,label,'Interpreter','none');
end
if nargout>0, varargout{1}=ax; end
if nargout>1, varargout{2}=s; end
end
