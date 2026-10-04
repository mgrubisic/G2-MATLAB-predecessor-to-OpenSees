# Nonlinear dynamics in G2

G2 now solves planar structural transient problems using default TRBDF2 and its existing element
constitutive models. The implementation is independent MATLAB code informed by
the supplied OpenSees C++ formulations. It does not embed or call OpenSees.
The original static solvers and six/seven-cell model constructors remain valid.

## Quick start

```matlab
setup_g2;
dynamic_linear       % damped free vibration; tip and distributed masses
dynamic_earthquake   % nonlinear fiber column; synthetic ground acceleration
ziemian_elcentro     % nonlinear Ziemian frame; complete ElCentro.txt in g, dt=.02 s
run_all_examples('results') % all six examples, PNG and MAT exports
```

The earthquake example uses element12, multiple sections/fibers, kinematic
hardening, consistent element mass, a concentrated tip mass and Rayleigh damping.
The synthetic motion is intentionally near the initial first-mode frequency to
exercise plasticity. It is not an earthquake record.

### Ziemian frame with ElCentro

`ziemian_elcentro` uses the supplied `data/earthquakes/ElCentro.txt` sample column.
Each sample is acceleration in g; `Factor=9.80665` converts to m/s^2 exactly
once. Samples start at t=0, retain their original amplitudes, and are spaced
at 0.02 s. TRBDF2 runs through the last sample (1560 samples, 31.18 s).
UniformExcitation acts in X; gravity remains active throughout the earthquake.
Convergence failures raise an error; any cutbacks retain their actual times.

Geometry, member A/I and three pinned bases follow the original `ziemian.m`,
converted to m-kN-tonne-s. Each member has two element12 fiber elements, three
Gauss sections and 3 flange/6 web fibers. Symmetric rectangular I sections are
fitted to the original geometric A/I using nominal depths and representative
widths; these are equivalent sections, not catalog rolled-section dimensions.
The fiber discretization approximates geometric inertia. Material behavior is
path-dependent bilinear steel with E=200 GPa, Fy=250 MPa and 1% hardening.
The example uses small-displacement kinematics without geometric P-delta.

Additional demonstration assumptions are steel density 7.85 tonne/m^3,
floor line weights 50/35 kN/m and 3% Rayleigh damping at the first two modes.
Floor weight is assigned to joints by tributary span, and floor mass is weight/g
in both translations. Steel has consistent distributed mass; its weight is
assigned at element ends. These contributions are separate, without double
counting. Gravity is equilibrated in ten static load steps before modal analysis
and earthquake integration. These assumed properties do not establish a
validated reproduction of the original published Ziemian benchmark.

```matlab
[m,r,p,s] = ziemian_elcentro('Plot',false); % complete analysis without figures
[m,r,p,s] = ziemian_elcentro('FloorLoads',[50 35]); % kN/m per floor
% Reopen exported results and display all response plots without re-solving:
load('results/ziemian_elcentro_results.mat');
ziemian_elcentro_plots(dynamicResult.History,earthquakeSummary);
```

Plots show the input in g, roof displacement, summed base reactions, story
drift percentages, global force-displacement response, current yielding fibers,
velocity/absolute acceleration, N/V/M diagrams, critical fiber stress/state,
curvature, masses, the viewer and animation. Roof/drift summary responses are
measured from the gravity equilibrium state. `earthquakeSummary` retains the
record, assumptions, response histories and peaks; `modalData` describes the
preloaded model. The batch runner exports PNG, MAT and modal text reports.

## Model configuration

All inputs use the model's native coherent units. Default is m-kN-tonne-s.
`g2vis.units('Imperial')` gives ft-lbf-slug-s; in-kip-s is also supported.
Mass is **not weight**. Divide weight by gravity in matching acceleration units
before calling `setMass`. See [UNITS.md](UNITS.md).

```matlab
m = setMass(m,5,[10 10 0]);  % mx,my [tonne], J [tonne*m^2]
m = setMass(m,[3 4],[2 2 0;3 3 0]);
m = setElementMass(m,1:4,.08,'Form','lumped');     % tonne/m
m = setElementMass(m,1:4,7.85,'Quantity','density', ...
                   'Form','consistent');          % tonne/m^3 times section area
m = numberer(m,'RCM');
m = rayleigh(m,alphaM,betaK,betaK0,betaKc);
```

`setMass` replaces the selected nodal mass; it also accepts one symmetric
positive-semidefinite full nodal block. Coupled translational/rotational entries
have their corresponding generalized mass dimensions. `setElementMass` replaces
selected line masses. Nodal and elemental mass contributions **add**.
Define mass and damping before starting an analysis.

Lumped mass assigns half the element mass to each end's two translations and
no artificial rotary mass. Consistent truss mass uses linear interpolation;
consistent beam mass uses axial linear and transverse Euler-Bernoulli Hermite
interpolation, including translation/rotation coupling. All mass matrices use
the undeformed reference geometry and stay constant through the analysis.
Consistent mass supports types 1,4,5,6,15 (trusses) and 2,8,12,13 (beams).
Released type3 beams currently require lumped mass; requesting consistent mass
raises an explicit error. Rotational inertia can be assigned separately at nodes.

RCM uses the free-equation connectivity graph, degree-ordered breadth-first
search, pseudo-peripheral roots and reversed component order. It includes
disconnected components and has no toolbox dependency. Constrained equations
remain after the free equations. Physical node/direction addressing is unchanged.
Existing static examples retain Plain numbering unless explicitly changed;
transient analysis defaults to RCM for an unsolved model. Solved/preloaded models
retain their numbering. Legacy static output indices refer to equation numbers,
so update those indices if opting into a different numberer.

## Time series and load patterns

```matlab
ts = g2dyn.timeSeries('Path','Values',acceleration,'Dt',.01);
ts = g2dyn.timeSeries('Path','Time',time,'Values',acceleration);
ts = g2dyn.timeSeries('Path','FilePath','record.txt','Dt',.01,'Factor',9.81);
ts = g2dyn.timeSeries('Sine','Period',.5,'Factor',2,'EndTime',5);
ts = g2dyn.timeSeries('Constant','Factor',1);
ts = g2dyn.timeSeries('Linear','Factor',2);
earthquake = g2dyn.uniformExcitation(1,ts,'Factor',1);
forcePattern = g2dyn.plain(ts,'Loads',nodalLoads,'ElementFactor',0);
```

Path files contain one sample column (provide `Dt` or `Time`) or time/value
columns (omit `Dt` and `Time`). Path values interpolate linearly. Before the first
sample and after the last sample the value is zero; `UseLast=true` holds the last
value after the path. The sample at the last timestamp is retained exactly.
`PrependZero=true` inserts a zero sample for a `Dt` path. `StartTime` shifts a `Dt`
path; explicit timestamps take precedence. Constant, Linear and Sine series use
the interval StartTime/EndTime; Linear grows from zero at StartTime.
Sine additionally accepts Phase in radians. `g2dyn.evaluate(ts,t)` evaluates arrays.

UniformExcitation supports X (1) and Y (2) translations. Multiple patterns
superpose, including several in one direction. Effective nodal load is

`P(t) = Pnodal(t) - M * rX * agX(t) - M * rY * agY(t)`.

The full assembled mass, including element mass and constrained-node coupling,
is used exactly once. The results u, v and a are relative to the moving ground.
Absolute translational acceleration is `a + r*ag`; ground and absolute
accelerations are stored separately. Constrained relative DOFs remain zero.
Rotation of the ground, multi-support motion and imposed nonzero support
displacements are not implemented.

Plain patterns use the supplied physical node-by-DOF `Loads`; if omitted they
use the model's original nodal loads. ElementFactor multiplies the series value
to scale reference uniform element loads through G2's existing lambda parameter.
ElementFactor defaults to 1; set it to 0 for a nodal-only pattern. For a force
pattern, the series factor is dimensionless and the load matrix carries force
and moment units. For UniformExcitation the evaluated series carries acceleration
units. Convert recordings in g using gravity explicitly.

## Rayleigh damping

Each element contributes

`Ce = alphaM*Me + betaK*Ktrial + betaK0*Kinitial + betaKc*KlastCommitted`.

Each node contributes `alphaM*Mn`; nodal mass is not counted again at elements.
alphaM is in 1/time; the three beta coefficients are in time. With no selectors,
`rayleigh` overwrites factors on all nodes and elements. Region calls affect
only the explicitly selected objects:

```matlab
m = rayleigh(m,.1,0,.002,0,'Elements',[1 2]); % leave nodal factors unchanged
m = rayleigh(m,.05,0,0,0,'Nodes',[3 4]);      % nodes receive alphaM only
```

Kinitial is the virgin element stiffness. KlastCommitted is updated only after
successful time steps. Trial stiffness and damping are reassembled every global
iteration; like OpenSees Newmark, the effective tangent does not include the
derivative of stiffness-proportional damping with respect to displacement.
For inelastic examples, the default demonstration uses betaK0 instead of betaK.

## Integration, convergence and failure behavior

```matlab
[m,result] = transientAnalysis(m,.005,600, ...
    'Patterns',{earthquake}, ...
    'Integrator',g2dyn.trbdf2, ... % optional: this is the default
    'Test',g2dyn.normUnbalance(1e-6,40,2), ...
    'MaxSubdivisions',5);
assert(result.Converged);
```

The default TRBDF2 reproduces the supplied OpenSees `TRBDF2.cpp`: one full
requested step uses the trapezoidal rule and the next equal-size step uses BDF2.
There are no hidden intermediate snapshots or half steps. A change in time step
or failed trial restarts with trapezoidal. The two preceding committed u/v states
and the stage are retained across calls, including continuation and cutbacks.
Roundoff in absolute-time subtraction is tolerated when deciding whether the
step size changed. For BDF2, `v=(3*u-4*u_n+u_(n-1))/(2*dt)` and
`a=(3*v-4*v_n+v_(n-1))/(2*dt)`; the effective tangent is
`K + 3/(2*dt)*C + 9/(4*dt^2)*M`. TRBDF2 introduces numerical dissipation,
so undamped energy conservation is not the same as for Newmark.

Newmark remains selectable with `'Integrator',g2dyn.newmark(.5,.25)`.
Its first parameter is gamma (sometimes called alpha); requested
defaults are gamma=.5 and beta=.25, the average-acceleration scheme. The
equilibrium equation is `M*a + C*v + fint = P`. Each Newton correction uses
`Keff = Ktrial + gamma/(beta*dt)*C + 1/(beta*dt^2)*M`.
Custom positive gamma/beta values are accepted; their stability is the caller's
choice. Matrices are assembled sparsely and solved by MATLAB's sparse solver.

Convergence checks the absolute norm of the free-equation residual, with norm
1, 2 (default) or Inf and a maximum number of displacement corrections. As in
OpenSees NormUnbalance, translations contribute native force and rotations
native moment components to the numerical norm. The tolerance therefore depends
on native units; it is not a dimensionless or normalized error estimate.
The residual plot identifies both force and moment component units.

Only converged states commit plastic/fiber history. On a failed trial, the
unchanged committed elements are reused. A failed step is bisected recursively
up to MaxSubdivisions (default 4); accepted substeps are recorded with their
actual times. If it still fails, default OnFailure='stop' emits a warning and
returns the last converged model with Converged=false and diagnostics.
OnFailure='error' raises an exception instead. Check Converged before relying on
an analysis; a partially accepted requested interval may end before TargetTime.
The returned model can continue through a subsequent transientAnalysis call.
Do not restart it with new initial conditions.

InitialTime defaults to zero. Optional InitialDisplacement, InitialVelocity and
InitialAcceleration are **node-by-DOF matrices**, with zero constrained entries.
When acceleration is omitted, it is computed from initial equilibrium on the
mass-matrix range. Zero-mass rotations are allowed; an initial load on a massless
DOF must already be balanced. A preloaded static model supplies its committed
displacement/material state; keep its static loads using a Constant Plain pattern
and add the earthquake pattern. Its dynamic history starts at InitialTime.
Inconsistent initial conditions and unrestrained massless mechanisms are rejected.

Local fiber-section and force-based-element convergence is also checked. A local
failure cannot be silently accepted by the global solver or committed.

`result` includes Converged, CompletedSteps, RequestedSteps, StartTime, EndTime,
TargetTime, FailedTime, Cutbacks, Message, integrator/test settings and the full
physical-time History. CompletedSteps counts fully completed requested intervals;
History also contains any successfully accepted subdivisions. Snapshots contain
u, velocity, acceleration, absoluteAcceleration, groundAcceleration, applied
effective loads, restoringForces, reactions, residualNorm, iterations and masses.
Dynamic reactions include restoring, damping and relative inertia minus the
effective applied load. The existing N/V/M diagrams show structural element
forces, with the established mirrored M default and optional Invert unchanged.

## Modal checks and visualization

`modalAnalysis(m,count)` uses current stiffness, condenses zero-mass equations,
and returns finite positive eigenvalues, Omega, Frequency, Period and nodal
mass-normalized Shapes. It rejects a singular massless mechanism.
`dynamicMatrices(m)` returns full M,K,C and restoring forces in equation order.

### OpenSees-style modalProperties

```matlab
modes = modalAnalysis(m,6);
p = modalProperties(m,modes,'-print','-file','ModalReport.txt','-return');
p = modalProperties(m,modes,'-unorm');
p = modalProperties(m,'Count',6,'Print',true); % calculate modes automatically
```

The [OpenSees modalProperties command](https://openseespydoc.readthedocs.io/en/latest/src/modalProperties.html)
is the reference for the fields and formulas. G2 accepts the same flags and
MATLAB Print/File/UNorm name-value equivalents. A MATLAB struct is always
returned; `-return` is accepted for command compatibility. Without supplied modes,
the finite positive modes are calculated with modalAnalysis. Supplied modes are
validated against current stiffness, mass and constraints to reject stale results.
The model and original mode shapes are not modified or implicitly cached.

The output includes eigenLambda/Omega/Frequency/Period, totalMass,
totalFreeMass, centerOfMass, generalizedMassMatrix, modalParticipationFactors,
modalParticipationMasses and their cumulative sums/percentages. Per-direction
fields match OpenSees names: partiFactorMX/MY/RMZ, partiMassMX/MY/RMZ,
partiMassesCumuMX/MY/RMZ, partiMassRatiosMX/MY/RMZ and
partiMassRatiosCumuMX/MY/RMZ. RMZ is supported even for two-translation-DOF nodes
through gyrating translational mass. This is a 2D implementation, not 3D.

Each elemental/nodal mass contribution is HRZ-diagonalized before assembly to
compute total/free masses and the center of mass. The center uses free directional
masses, falling back to the geometric center of free nodes for a zero-mass
direction. Rotational totals add `mx*dy^2 + my*dx^2` about that center.
Generalized masses and participation use the original consistent **free** mass
matrix and rigid-body influence vectors (not the HRZ diagonal). Percentages use
the HRZ total free mass, matching OpenSees. For consistent masses at constrained
interfaces, even all computed modes need not sum to exactly 100% under this
normalization. Zero denominator directions return zero percentage.

`-unorm` divides each eigenvector by its largest absolute component, including
rotation, as OpenSees does. Generalized mass and participation factors change;
effective modal masses and percentages remain invariant. The returned Shapes are
the normalized copy. Reports label native mass, rotational-inertia, length,
frequency, time and percentage units, and distinguish normalization-dependent
quantities. Report files overwrite the named path. Both dynamic examples print
the report; run_all_examples exports it and stores modalData in the MAT file.

```matlab
g2vis.dynamic_dashboard(m,node,direction);
g2vis.plot_time_history(m,node,direction,'Component','velocity');
g2vis.plot_time_history(m,node,direction,'Component','absoluteAcceleration');
g2vis.plot_time_history(m,1,1,'Component','reaction');
g2vis.plot_hysteresis(m,node,direction);
g2vis.plot_mass(m);
g2vis.plot_nodal_response(m,'acceleration','Component','x');
g2vis.viewer(m); g2vis.anim_defo(m,'Filename','response.gif');
```

plot_history automatically selects physical time for transient results and keeps
the original load-factor plot for static results. The viewer includes velocity,
relative/absolute acceleration and masses; its slider and animation display
time units. Nodal velocity/acceleration colors interpolate linearly between nodes,
not as exact recovered beam fields. Mass circles show the assembled matrix
diagonal; line labels show source mass/length. For consistent mass, diagonal
values alone are not the total mass. All new plots retain light colors,
transparent frameless legends and default value annotations.

## Verification and OpenSees reference

```matlab
results = runtests('tests'); assertSuccess(results);
```

The tests cover TRBDF2's independent first-order-system recurrence, convergence
order, dissipation, continuation, step-size changes and cutbacks, plus
Newmark's closed-form discrete oscillator solution, conservation
of undamped energy, analytical damping, constant forcing/ground acceleration,
mass integrals/coupling, RCM bandwidth/invariance, finite modes with massless
rotations, an independent kinematic-hardening return-map response, fiber elements
12/13, failure rollback, successful cutbacks and graphics/unit labels.

For optional cross-engine verification, run tests/opensees_reference.py with
OpenSeesPy installed, then add tests to the MATLAB path and call
verify_opensees_reference and verify_modal_reference. They read ignored reference
CSV/JSON files generated in results.
OpenSeesPy 3.8.0 and G2 agree to numerical roundoff for the nonlinear
UniformExcitation oscillator (both TRBDF2 and Newmark) and for a damped consistent-mass beam under equivalent
nodal loading. Measured maximum u/v/a errors were approximately 1e-11 or smaller.

An upstream discrepancy was found in the supplied
`OpenSees-master/SRC/element/elasticBeamColumn/ElasticBeam2d.cpp`:
getResistingForce subtracts Q and getResistingForceIncInertia subtracts Q again.
An independent first-step check in OpenSeesPy 3.8.0 confirmed twice the element
ground-load contribution for that element. The beam benchmark therefore applies
the analytically derived `-M*r*ag` once through Plain nodal loads. G2 does not
reproduce the doubled load. Its distributed-mass UniformExcitation is separately
tested against the exact assembled-matrix load identity. No OpenSees files were
modified. This is a finding for that source/element/version, not a claim about
all OpenSees elements or releases.

Modal property comparisons cover both normalization choices and all OpenSees
dictionary fields for a rotated two-element consistent-mass beam with nodal
translational/rotational masses, including fixed-node mass. Relative/scaled errors
were approximately 1e-15. These benchmarks are reproducible with the scripts.

Source references in the separate OpenSees reference repository: TRBDF2.cpp and Newmark.cpp (integration),
DomainModalProperties.cpp (modal properties), RCM.cpp
(numbering), CTestNormUnbalance.cpp (residual test), UniformExcitation.cpp and
EarthquakePattern.cpp (ground loading), PathSeries.cpp (series), Element.cpp and
Node.cpp (Rayleigh damping).

This adds transient solution infrastructure to the existing planar G2 elements;
it does not add OpenSees's 3D, shell/solid, contact, multi-point constraints,
advanced constitutive models or multi-support capabilities. Numerical validation
is specific to the documented benchmarks and existing G2 material formulations.
