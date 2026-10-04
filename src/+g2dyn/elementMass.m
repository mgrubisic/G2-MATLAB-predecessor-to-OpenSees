function M=elementMass(xyz,dofs,type,massPerLength,form)
% ELEMENTMASS Reference-geometry translational lumped or consistent 2D mass.
% Beam consistent mass uses axial linear and transverse Hermite interpolation.
validateattributes(massPerLength,{'numeric'},{'real','scalar','finite','nonnegative'});
L=norm(xyz(2,:)-xyz(1,:));
if L<=0, error('G2Dyn:Geometry','Mass requires positive element length.'); end
M=zeros(2*dofs); total=massPerLength*L;
if strcmpi(form,'lumped')
    for i=[1 2 dofs+1 dofs+2], M(i,i)=total/2; end
elseif strcmpi(form,'consistent')
    if ismember(type,[1 4 5 6 15])
        ix=[1 2 dofs+1 dofs+2]; M(ix,ix)=total/6*[2*eye(2) eye(2);eye(2) 2*eye(2)];
    elseif ismember(type,[2 8 12 13])&&dofs==3
        M([1 4],[1 4])=total/6*[2 1;1 2];
        M([2 3 5 6],[2 3 5 6])=total/420* ...
            [156 22*L 54 -13*L;22*L 4*L^2 13*L -3*L^2; ...
            54 13*L 156 -22*L;-13*L -3*L^2 -22*L 4*L^2];
        t=(xyz(2,:)-xyz(1,:))/L; R=[t(1) t(2) 0;-t(2) t(1) 0;0 0 1];
        T=blkdiag(R,R); M=T'*M*T;
    else
        error('G2Dyn:MassForm','Consistent mass is unavailable for this element; use lumped.');
    end
else, error('G2Dyn:MassForm','Form must be lumped or consistent.'); end
end
