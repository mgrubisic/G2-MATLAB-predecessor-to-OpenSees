% G2VIS - OpsVis-style visualization of G2 planar structural models.
%
% Geometry / results
%   plot_model                    - Nodes, elements, supports, releases, axes.
%   plot_defo                     - Interpolated beam / truss displaced shapes.
%   deformed_coordinates          - Numerical curves and displacement scale.
%   plot_displacements            - Displacement color maps.
%   plot_load                     - Nodal forces, moments and distributed loads.
%   plot_reactions                - Support reactions.
%   section_force_distribution_2d - Numerical N, V, M distributions.
%   section_force_diagram_2d       - Filled N, V, M diagrams.
%   plot_section                  - Curvature / axial strain at integration points.
%   plot_fiber_section            - Fiber geometry, committed stress / strain.
%   plot_history                  - Node displacement versus load factor.
%   plot_time_history             - Transient u/v/a, input, reactions, residuals.
%   plot_nodal_response           - Velocity and acceleration colors.
%   plot_mass                     - Assembled mass diagonal and line masses.
%   plot_hysteresis               - Restoring force versus displacement.
%   dynamic_dashboard             - Six-panel physical-time response overview.
%
% Presentation
%   dashboard                     - Exportable six-panel overview.
%   viewer                        - Interactive controls and step selection.
%   anim_defo                     - Fixed-scale animation and GIF export.
%   style_light                   - White axes and transparent frameless legends.
%   label_values                  - Signed end/extreme annotations for curves.
%   units                         - Coherent Metric / Imperial unit metadata.
%   convert_units                 - Explicit dimension-aware numeric conversion.
%
% Model accessors: visualData(mod), visualHistory(mod).
