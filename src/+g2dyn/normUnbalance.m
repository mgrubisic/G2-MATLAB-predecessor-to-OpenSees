function t=normUnbalance(tolerance,maxIterations,normType)
% NORMUNBALANCE Absolute norm of the free-DOF equilibrium residual.
if nargin<1, tolerance=1e-8; end
if nargin<2, maxIterations=30; end
if nargin<3, normType=2; end
validateattributes(tolerance,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(maxIterations,{'numeric'},{'scalar','integer','positive','finite'});
if ~isnumeric(normType)||~isscalar(normType)||~ismember(normType,[1 2 Inf]), error('G2Dyn:Norm','Norm must be 1, 2 or Inf.'); end
t=struct('Type','NormUnbalance','Tolerance',tolerance,'MaxIterations',maxIterations,'Norm',normType);
end
