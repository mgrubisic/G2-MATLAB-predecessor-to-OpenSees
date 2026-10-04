# G2 visualization

The `+g2vis` MATLAB package follows the OpsVis workflow for the element families
actually available in G2: planar trusses, beam-columns, moment releases, plastic
hinges and fiber sections. It needs no Python, OpenSeesPy or third-party toolbox.
MATLAB R2020a or newer is the target; runtime tests were run with R2026a.

## Quick start

From the G2 repository root:

```matlab
setup_g2;
run('EXAMPLES/strongback.m')
% Or run ziemian.m / cantilever.m in the same folder.
```

Each example finds the G2 path itself. Strongback and Ziemian show geometry,
loads, displacement colors, N/V/M, reactions and an interactive viewer.
Cantilever additionally shows curvature, axial strain, fiber stress and strain,
load-displacement history and an animation of converged load steps.

To run all examples and export their plots and numerical results:

```matlab
setup_g2;
run_all_examples('results')
```

PNG images and `*_results.mat` snapshots are written to that directory.
The runner keeps interactive windows open. No files are exported by individual
examples unless explicitly requested through the viewer or API.

## Public API

```matlab
m = linearAnalysis(m);           % keep the returned solved model
g2vis.plot_model(m,'LocalAxes',true)
g2vis.plot_defo(m)                % automatically scaled Hermite beam curves
g2vis.plot_defo(m,'Scale',1)      % true displacement, without amplification
g2vis.plot_displacements(m,'Component','y')
g2vis.plot_load(m)
g2vis.plot_reactions(m)
g2vis.section_force_diagram_2d(m,'M')
[NVM,x] = g2vis.section_force_distribution_2d(m,3,101);
g2vis.plot_section(m,'curvature','Elements',1:10)
g2vis.plot_fiber_section(m,1,2,'Component','stress')
g2vis.plot_history(m,11,2)         % physical node 11, vertical direction
g2vis.dashboard(m)
g2vis.viewer(m)
g2vis.anim_defo(m,'Filename','cantilever.gif','Delay',0.08)
```

`viewer` selects the plot type, committed step, direct amplification, fiber
element and integration point. MATLAB axes retain their usual zoom, pan and
data-tip interactions. Export PNG saves the current axes.

Most plot functions return `[ax, handles]`. Deformation adds `scale` as the third
output; force diagrams return `[ax, handles, scale, values]`. Numerical curves
are available through `[curves, scale] = g2vis.deformed_coordinates(m,...)`.
All these functions accept either a model or its read-only `visualData(m)`
snapshot. History functions also accept a cell array from `visualHistory(m)`.

Common name/value options:

| Option | Meaning |
| --- | --- |
| `Axes` | Existing axes for subplots or user interfaces; plots add to these axes |
| `Scale` | Direct multiplier; empty means automatic; zero suppresses amplification |
| `Ratio` | Automatic graphical amplitude / largest model dimension (default 0.12) |
| `Points` | Sample points per element (default 41, minimum 3) |
| `Elements` | Element indices to display; empty means all |
| `Color`, `LineWidth` | Diagram / curve appearance |
| `NodeLabels`, `ElementLabels`, `Supports`, `LocalAxes` | Geometry decorations |
| `Undeformed` | Show the reference geometry behind displacement curves |
| `Fill`, `Values` | Filled force diagrams and numerical annotations |
| `Component` | Displacement: magnitude/x/y/rotation; fibers: stress/strain/material |
| `Invert` | Reflect only M relative to its mandatory default; false by default |

For section distributions, distance is cumulative along the selected element
order. Branching structures should select a single member chain.
Rotation color maps interpolate **nodal** rotations; released member-end
rotations are used independently in the displaced centerline.
The `material` fiber component is G2's committed constitutive state code.

All plots use white figure/axes backgrounds, including the original cantilever
plots. Legends use `Box='off'`, `Color='none'` and readable dark text, independent
of the MATLAB application theme. `g2vis.style_light(figureHandle)` applies these
defaults to existing and future axes/legends in a user-created figure.

`Values=true` is the default in individual plots and the dashboard. Curves label
their ends and signed extrema (one label for constant curves, including zero).
Fiber strips display their committed values; animation labels refresh per step.
Use `Values=false` to hide these annotations. `g2vis.label_values` is also
available for annotating custom curves.

Support symbols contact the original node at the top edge (fixed support),
apex (pin), top of the circle (vertical restraint), or left side of the circle
(horizontal restraint), following the OpsVis convention. Symbols appear by
default on model geometry, internal-force diagrams, and displacement/deflection
plots; `Supports=false` hides them. Concentrated moments and moment reactions
use a circular arc with a filled, direction-sensitive triangular arrowhead.

## Numerical conventions

Coordinates, forces, stresses and strains stay in the user's model units.
Models and snapshots retain declared unit metadata; axes, titles, annotations
and color bars show the relevant units. Six-cell models default to Metric
m-kN-tonne-s. The optional seventh cell declares another profile, including
Imperial. See [UNITS.md](UNITS.md) for the unit table and conversion API.

Local x runs from the first to the second connected node; local y is its
counterclockwise normal. The force convention matches OpsVis:

```text
N(x) = -Ni - wx*x                  positive N means tension
V(x) =  Vi + wy*x
M(x) = -Mi + Vi*x + wy*x^2/2
```

Moment diagrams use the mandatory **mirrored** default offset `-Scale*M`.
With `Invert=true`, only the graphical M shape reflects to `+Scale*M`.
N/V use `+Scale*N/V` regardless of this option. Returned values, signed
annotations, analytical distributions and solver results retain their signs.

End forces come from `state`, transformed into the local axes. Uniform loads
are recovered from end-force equilibrium, so the plots agree with the actual
G2 solution. This matters for the original `element2` tangential-load convention:
its implementation applies an effective `wx = 2*lambda*ws`; `wn` corresponds
to `wy = -lambda*wn`. These legacy solver conventions are preserved and the
load plot explicitly shows effective loads. `element3` currently implements
transverse distributed loading only.

Beam curves use cubic Hermite interpolation and member rotations adjusted for
releases. Elastic beams include the exact uniform-load quartic contribution;
this captures deformation inside a fixed-fixed element with zero nodal motion.
Trusses are straight between displaced endpoints. For `element15`, force axes
follow the committed deformed chord.

Reactions are assembled restoring forces minus applied nodal forces at
constrained DOFs. Free-DOF residuals are available separately as `d.residual`.
Fiber colors come directly from committed constitutive data, and rectangles
retain the actual strip areas and section widths. Section coordinates use each
element's stored integration rule instead of assuming Gauss or Lobatto.

Automatic deformation scaling uses sampled curve extrema. Animation uses one
scale and one viewport for all committed steps. Static animation represents load
steps; transient animation displays physical time in the model's time units.

## Solver compatibility and stored history

```matlab
m = linearAnalysis(m);
[m,plt,plte] = variableloadNR(m,control,plotdofs,plotelem);
[plt,plte,m] = simpleNewtonRaphson(m,control,plotdofs,plotelem);
[plt,plte,m] = modifiedNR(m,control,plotdofs,plotelem);
[m,result] = transientAnalysis(m,dt,steps,'Patterns',{excitation});
```

The existing first two outputs of the uniform-step solvers remain unchanged;
their optional third output returns the model. `plot(m,title,ratio)` remains
available with its historical relative-amplitude interpretation (default 0.15).

Every solver stores the initial state and successfully committed states,
including complete nodal displacements, element responses and fiber data.
Rejected steps are excluded; requested output tables are trimmed to converged
steps. Plotting never commits or alters the model. Full fiber histories consume
memory proportional to steps × integration points × fibers.

External callers of `update` should supply its fifth argument, `lambda`,
especially for distributed-only loading. Four-argument calls infer lambda from
nonzero reference nodal loads; zero-reference calls require an explicit factor.

## Scope relative to OpsVis

| OpsVis capability | G2 implementation |
| --- | --- |
| Model / labels / supports / local axes | `plot_model` |
| Interpolated deformation | `plot_defo`, `deformed_coordinates` |
| Nodal / uniform member loads | `plot_load` |
| 2D section-force distributions and diagrams | `section_force_distribution_2d`, `section_force_diagram_2d` |
| Fiber section visualization | `plot_fiber_section`, including committed stress/strain |
| Animation | `anim_defo`, including GIF export |
| Displacement colors, reactions, nonlinear section response | Additional G2 views |
| Transient time histories, velocity/acceleration, hysteresis, masses | `plot_time_history`, `plot_nodal_response`, `plot_hysteresis`, `plot_mass`, `dynamic_dashboard` |
| Modal analysis | `modalAnalysis` returns frequencies and nodal mode shapes |
| 3D, solid/shell stress fields | G2 has no corresponding elements |

Unsupported spatial models are rejected explicitly. This package adds
postprocessing of supported G2 results. The separate `g2dyn` configuration and
model methods now provide mass matrices, modal analysis and nonlinear transient
analysis; see [DYNAMICS.md](DYNAMICS.md). No new spatial elements are introduced.

## Verification

```matlab
setup_g2;
results = runtests('tests');
assertSuccess(results)
```

Tests compare independent analytical cantilever, rotated cantilever, uniform
simply-supported and fixed-fixed beam solutions, released ends, and truss
forces. They exercise all ten existing element types, nonlinear history,
failed-step exclusion, solver output compatibility, read-only plotting,
viewer callbacks, PNG export and GIF frame counts. All five examples
run end to end, including nonlinear fiber visualization and transient dynamics.
Graphics regressions check white backgrounds, transparent frameless legends,
moment arrowhead directions, default value labels (including zero), mirrored
M geometry without altered signs, and correctly anchored supports in model,
force and displacement views.
