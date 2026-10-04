function errors=verify_modal_reference
% Optional OpenSees modalProperties comparison after opensees_reference.py.
root=fileparts(fileparts(mfilename('fullpath'))); addpath(root); setup_g2;
reference=jsondecode(fileread(fullfile(root,'results','opensees_modal.json')));
m=model({'Modal reference',[0 0;2 1;4 0],[1 1 1;0 0 0;0 0 0], ...
    [1 2 2;2 3 2],{[200 1 .1];[200 1 .1]},zeros(3,3)});
m=setMass(m,1:3,[2 3 .4;1 2 .3;2 1 .5]);
m=setElementMass(m,1,.2,'Form','consistent'); m=setElementMass(m,2,.3,'Form','consistent');
% MATLAB jsondecode stores nested mode/node/direction lists in that order.
shapes=permute(reference.ShapesByMode,[2 3 1]);
modes=modalAnalysis(m,6); modes.Shapes=shapes; modes.Eigenvalues=reference.Eigenvalues;
modes.Omega=sqrt(modes.Eigenvalues); modes.Frequency=modes.Omega/(2*pi); modes.Period=1./modes.Frequency;
errors=zeros(2,1);
for normalization=1:2
    if normalization==1, target=reference.Properties; p=modalProperties(m,modes);
    else, target=reference.UNormProperties; p=modalProperties(m,modes,'-unorm'); end
    keys=fieldnames(target);
    for i=1:numel(keys)
        key=keys{i}; actual=p.(key); expected=target.(key);
        difference=max(abs(actual(:)-expected(:))./max(1,abs(expected(:))));
        errors(normalization)=max(errors(normalization),difference);
        assert(difference<1e-9,'Modal property mismatch: %s',key);
    end
end
fprintf('modalProperties max relative/scaled errors: %.4g %.4g\n',errors);
end
