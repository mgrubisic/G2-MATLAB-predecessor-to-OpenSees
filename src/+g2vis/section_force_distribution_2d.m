function [values,x] = section_force_distribution_2d(m,element,points)
% SECTION_FORCE_DISTRIBUTION_2D OpsVis-compatible [N V M] convention.
% N is positive tension, V=Vi+wy*x, M=-Mi+Vi*x+wy*x^2/2.
if nargin<3, points=41; end
validateattributes(points,{'numeric'},{'scalar','integer','>=',3});
d=data(m); validateattributes(element,{'numeric'},{'scalar','integer','>=',1,'<=',numel(d.elements)});
e=d.elements{element}; f=e.endForces; w=e.uniform;
x=linspace(0,e.length,points)';
values=[-f(1)-w(1)*x, f(2)+w(2)*x, -f(3)+f(2)*x+w(2)*x.^2/2];
end
