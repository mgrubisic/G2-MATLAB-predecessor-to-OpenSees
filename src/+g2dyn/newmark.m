function n=newmark(gamma,beta)
% NEWMARK Displacement-form Newmark integrator, default average acceleration.
if nargin<1, gamma=.5; end
if nargin<2, beta=.25; end
validateattributes(gamma,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(beta,{'numeric'},{'scalar','real','finite','positive'});
n=struct('Type','Newmark','Gamma',gamma,'Beta',beta);
end
