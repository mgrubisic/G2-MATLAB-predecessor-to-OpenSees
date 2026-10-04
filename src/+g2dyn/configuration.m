function c=configuration(nodes,dofs,elements)
% Internal model defaults; all quantities use the model's native units.
c.NodalMass=repmat({zeros(dofs)},nodes,1);
c.MassPerLength=zeros(elements,1);
c.MassForm=repmat({'lumped'},elements,1);
c.NodeAlpha=zeros(nodes,1);
c.ElementRayleigh=zeros(elements,4);
end
