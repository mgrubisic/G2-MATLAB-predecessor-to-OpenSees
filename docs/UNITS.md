# Structural units in G2

The implemented design uses one unit descriptor per model. Every history
snapshot retains it, and every plot obtains its labels from it. The solver
keeps its original arithmetic: declaring units does not rescale inputs or
responses. Conversion is always explicit.

The three responsibilities are:

1. Declare the numerical input units when constructing a model.
2. Derive dimensions and labels centrally with `g2vis.units`.
3. Convert values explicitly with `g2vis.convert_units` when needed.

## Defaults and profiles

| Quantity | Metric (default) | Imperial (default) | Imperial in-kip |
| --- | --- | --- | --- |
| Length / displacement | m | ft | in |
| Force | kN | lbf | kip |
| Time | s | s | s |
| Mass | tonne | slug | kip*s^2/in |
| Moment / energy | kN*m | lbf*ft | kip*in |
| Distributed load / translational stiffness | kN/m | lbf/ft | kip/in |
| Stress / elastic modulus | kN/m^2 | lbf/ft^2 | ksi |
| Curvature | 1/m | 1/ft | 1/in |
| Velocity | m/s | ft/s | in/s |
| Acceleration | m/s^2 | ft/s^2 | in/s^2 |
| Density | tonne/m^3 | slug/ft^3 | kip*s^2/in^4 |
| Rotation | rad | rad | rad |
| Strain / load factor / material state code | 1 | 1 | 1 |

Area, second moment of area, frequency, power and damping are also derived.
Metric supports m/mm/cm and N/kN; Imperial supports ft/in and lbf/kip.
Time supports s/ms. In-inch stresses use psi for lbf and ksi for kip.

Mass is derived coherently as `force * time^2 / length`: m-kN-s gives tonne,
and ft-lbf-s gives slug. The in-kip-s profile uses kip*s^2/in, rather than
mistaking kip (force) or lbm for the coherent mass unit. The mm-kN-s profile
has mass unit kN*s^2/mm. The G2
dynamic solver uses this coherent mass unit for concentrated and distributed
masses. See [DYNAMICS.md](DYNAMICS.md).

## Declare native model units

Existing six-cell definitions default to Metric m-kN-tonne-s:

```matlab
mod = model({name, XYZ, BOUND, CONNECT, MATERIAL, LOAD});
```

Use the optional seventh cell for another native profile:

```matlab
u = g2vis.units('Imperial','Length','in','Force','kip');
mod = model({name, XYZ, BOUND, CONNECT, MATERIAL, LOAD, u});
```

Numbers must already use the declared profile consistently. An in-kip model
uses in for coordinates, in^2 for area, in^4 for inertia, ksi for E and yield
stress, kip for nodal forces and kip*in for nodal moments. Declaring Imperial
does not convert Metric numbers entered earlier.

The examples declare their actual inputs:

- `strongback.m`, `ziemian.m`: Metric mm-kN, with stress kN/mm^2.
- `cantilever.m`: Imperial in-kip, with stress ksi.

These declarations preserve the existing analysis values. New models without
an override use the requested m-kN-tonne defaults. Legacy snapshot structs
without metadata default to Metric; declare the original profile before
plotting old non-Metric snapshots using `snapshot.units = u`.

## Explicit conversion

```matlab
metric = g2vis.units;
inchKip = g2vis.units('Imperial','Length','in','Force','kip');
length_m = g2vis.convert_units(120,'Length',inchKip,metric); % 3.048 m
force_kN = g2vis.convert_units(1,'Force',inchKip,metric);   % 4.4482216152605 kN
moment_kNm = g2vis.convert_units(1,'Moment',inchKip,metric);
stress_kNm2 = g2vis.convert_units(1,'Stress',inchKip,metric);
```

Conversion supports numeric arrays. The descriptor's `SI` fields contain
scale factors to m, N, kg and s and dimensional factors for derived quantities.
For example, `metric.SI.Mass` is 1000 kg per tonne. Conversion evaluates
`value * source.SI.quantity / target.SI.quantity`.

Do not simply re-label a complete model to change its units. Complete model
conversion must convert geometry, translations, forces/moments, section
properties, material strengths/moduli, distributed loads and stored responses.
Element material layouts differ and require per-element adapters. This
implementation provides value conversion and native labels; it does not
silently rebase entire models or old analyses.

## Plot labels and optional M inversion

Geometry axes show the native distance unit. Force/moment titles identify the
units of their values. Load and reaction annotations also show units explicitly.
Displacement/fiber color bars identify their quantity and unit. Curvature,
strain and history axes distinguish 1/length, dimensionless `[1]`, displacement
and rotation `[rad]`. Animation and viewer status retain these labels.

```matlab
g2vis.section_force_diagram_2d(mod,'M');
% Mandatory default: the previously agreed shape, offset -Scale*M.

g2vis.section_force_diagram_2d(mod,'M','invert',true);
% Reflect only the shape relative to that default, offset +Scale*M.
% Signed values and numerical force distributions remain unchanged.

g2vis.dashboard(mod,'Invert',true);
% Same optional M reflection in the overview. N and V are unaffected.
```

`Invert=false` is the default; the viewer's `Invert M` checkbox starts off.

## Recommended extension

For independent display units, add a `DisplayUnits` option and a central
snapshot conversion layer. Convert a copy of the snapshot with per-quantity
factors, then pass it to the existing plots. Preserve analysis data and the
original history. Test physically equivalent Metric and Imperial models
against each other before introducing whole-model conversion.

This would support mm-kN input with m-kN display, or Imperial input with Metric
display, without duplicating conversion logic throughout the plot functions.
