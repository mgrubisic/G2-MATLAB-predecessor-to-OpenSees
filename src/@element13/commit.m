function el=commit(el,xyz,u,lambda) %#ok<INUSD>
% Commit only a locally converged force-based compatibility solution.
% G2 - Matrix Structural Analysis with Matlab, Version 0.1.
% University of California, Berkeley; Copyright 1999, Gregory L. Fenves.
dx=xyz(2,:)-xyz(1,:); L=norm(dx); dx=dx/L;
a=[-dx(2)/L dx(1)/L 1 dx(2)/L -dx(1)/L 0; ...
   -dx(2)/L dx(1)/L 0 dx(2)/L -dx(1)/L 1; ...
   -dx(1) -dx(2) 0 dx(1) dx(2) 0];
[s,~,~,dvsec]=compatibility(el,a*u(:,2),L);
for i=1:el.nsecs, el.secs(i)=commit(el.secs(i),dvsec(:,i)); end
el.si=s;
end
