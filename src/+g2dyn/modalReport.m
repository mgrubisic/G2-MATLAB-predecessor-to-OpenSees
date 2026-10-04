function text=modalReport(p)
% MODALREPORT Unit-labelled OpenSees-style plain-text modal properties report.
u=p.Units; text=sprintf('# G2 MODAL ANALYSIS REPORT\n\n* 1. DOMAIN SIZE: %d\n',p.domainSize);
text=[text sprintf('\n* 2. EIGENVALUE ANALYSIS\nMODE LAMBDA [1/%s^2] OMEGA [rad/%s] FREQUENCY [%s] PERIOD [%s]\n',u.Time,u.Time,u.Frequency,u.Time)];
for i=1:numel(p.eigenLambda)
    text=[text sprintf('%d %.12g %.12g %.12g %.12g\n',i,p.eigenLambda(i),p.eigenOmega(i),p.eigenFrequency(i),p.eigenPeriod(i))]; %#ok<AGROW>
end
heading=sprintf('MX [%s] MY [%s] RMZ [%s]',u.Mass,u.Mass,u.RotationalInertia);
text=[text sprintf('\n* 3. TOTAL MASS\n%s\n%.12g %.12g %.12g\n',heading,p.totalMass)];
text=[text sprintf('\n* 4. TOTAL FREE MASS\n%s\n%.12g %.12g %.12g\n',heading,p.totalFreeMass)];
text=[text sprintf('\n* 5. CENTER OF MASS [%s]\nX Y\n%.12g %.12g\n',u.Length,p.centerOfMass)];
names={'MODAL PARTICIPATION FACTORS','MODAL PARTICIPATION MASSES', ...
    'MODAL PARTICIPATION MASSES (cumulative)','MODAL PARTICIPATION MASS RATIOS (%)', ...
    'MODAL PARTICIPATION MASS RATIOS (%) (cumulative)','GENERALIZED MASS MATRIX'};
values={p.modalParticipationFactors,p.modalParticipationMasses,p.modalParticipationMassesCumulative, ...
    p.modalParticipationMassRatios,p.modalParticipationMassRatiosCumulative,p.generalizedMassMatrix};
for a=1:numel(names)
    text=[text sprintf('\n* %d. %s\n',a+5,names{a})]; %#ok<AGROW>
    if a==1
        if p.DisplacementNormalized
            text=[text sprintf('MODE MX [1] MY [1] RMZ [%s] (displacement-normalized convention)\n',u.Length)]; %#ok<AGROW>
        else
            text=[text sprintf('MODE MX [sqrt(%s)] MY [sqrt(%s)] RMZ [%s*sqrt(%s)]\n',u.Mass,u.Mass,u.Length,u.Mass)]; %#ok<AGROW>
        end
    elseif a==2||a==3, text=[text sprintf('MODE %s\n',heading)]; %#ok<AGROW>
    elseif a==4||a==5, text=[text sprintf('MODE MX [%%] MY [%%] RMZ [%%]\n')]; %#ok<AGROW>
    else
        unit='1'; if p.DisplacementNormalized, unit=u.Mass; end
        text=[text sprintf('Generalized mass [%s]; depends on mode normalization\n',unit)]; %#ok<AGROW>
    end
    matrix=values{a};
    for i=1:size(matrix,1)
        text=[text sprintf('%d',i) sprintf(' %.12g',full(matrix(i,:))) sprintf('\n')]; %#ok<AGROW>
    end
end
end
