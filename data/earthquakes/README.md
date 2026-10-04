# Earthquake input records

`ElCentro.txt` is the numerical recording supplied for this project: 1560 finite
acceleration samples in one column, expressed in g, with 0.02 s spacing.
The first sample is at t=0, the last at 31.18 s, and PGA is 0.31882 g.

`EXAMPLES/ziemian_elcentro.m` reads it using a repository-relative absolute path.
Its Path-series Factor=9.80665 converts g to m/s² once. No amplitude scaling,
baseline correction, filtering, resampling or initial zero insertion is applied.

The filename was supplied with the data. Station, component, processing history,
original download source and redistribution terms were not supplied; these are
not inferred from the filename. No event/component identity or record-specific
license is asserted here. Original numerical samples are preserved.
