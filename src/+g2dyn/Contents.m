% G2DYN - Nonlinear dynamics for native G2 planar elements.
%   newmark           - Newmark integration (gamma=.5, beta=.25 by default).
%   trbdf2            - Default alternating trapezoidal/BDF2 integration.
%   modalReport       - Unit-labelled text report of modal properties.
%   normUnbalance     - Absolute free-equation residual convergence test.
%   timeSeries        - Constant, Linear, Sine and Path (array/file) series.
%   evaluate          - Evaluate a time series at physical time.
%   uniformExcitation - Translational ground acceleration pattern.
%   plain             - Time-dependent nodal/reference element loads.
%   rcm               - Reverse Cuthill-McKee equation permutation.
%   elementMass       - Lumped or consistent reference-geometry element mass.
%
% Model methods: setMass, setElementMass, numberer, rayleigh,
% dynamicMatrices, modalAnalysis, modalProperties, transientAnalysis.
