function str=g2
% G2 Matrix structural analysis
%
% G2 is a Matlab framework for matrix structural analysis.
%
% The original release targeted MATLAB 5.0. This maintained edition uses
% modern MATLAB graphics (R2020a+ target; verified with R2026a).
% Run setup_g2 from the repository root to add src and EXAMPLES to the path.
% src contains the @model/@element classes, +g2vis/+g2dyn and static solvers.
%
% 'help model' gives information about creating a model.  Use
% 'help elementn' where n=1,2,3 ... for information about the
%  elements.

% G2 - Matrix Structural Analysis with Matlab
% Version 0.1
% University of California, Berkeley
% Copyright 1999, Gregory L. Fenves
% fenves@ce.berkeley.edu
% --------------------------------------

g2version = '0.1 (UC Berkeley, CE 221)';

str = sprintf(['G2 - MATRIX STRUCTURAL ANALYSIS WITH MATLAB ' ... 
		version '\nVERSION: ' g2version ]);
