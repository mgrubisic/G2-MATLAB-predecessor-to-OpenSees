function root=setup_g2
% SETUP_G2 Add G2 source and examples to the MATLAB path without recursion.
% From the repository root: setup_g2; ziemian_elcentro
% Do not add @class/private folders or reference projects with genpath.
root=fileparts(mfilename('fullpath'));
addpath(fullfile(root,'src'),fullfile(root,'EXAMPLES'));
end
