"""Optional independent OpenSeesPy benchmarks; writes CSV into results.

Run with a Python environment containing openseespy, then in MATLAB:
    verify_opensees_reference
No OpenSees source is copied into G2. These use the public OpenSees API.
"""
import sys
sys.dont_write_bytecode = True
from pathlib import Path
import csv
import math
import json
import openseespy.opensees as ops

OUTPUT = Path(__file__).resolve().parents[1] / "results"
OUTPUT.mkdir(parents=True, exist_ok=True)


def run(name, beam=False, integrator="Newmark"):
    ops.wipe()
    ops.model("basic", "-ndm", 2, "-ndf", 3)
    ops.node(1, 0.0, 0.0)
    ops.node(2, 1.0, 0.0)
    ops.fix(1, 1, 1, 1)
    if beam:
        ops.geomTransf("Linear", 1)
        ops.element("elasticBeamColumn", 1, 1, 2, 1.0, 200.0, 0.01, 1,
                    "-mass", 0.2, "-cMass")
        ops.mass(2, 1.0, 1.0, 0.0)
        ops.rayleigh(0.02, 0.001, 0.002, 0.003)
        direction, steps, amplitude = 2, 200, 2.0
    else:
        ops.fix(2, 0, 1, 1)
        ops.uniaxialMaterial("Steel01", 1, 0.2, 4.0, 0.1)
        ops.element("truss", 1, 1, 2, 1.0, 1)
        ops.mass(2, 1.0, 0.0, 0.0)
        direction, steps, amplitude = 1, 1000, 8.0
    dt = 0.01
    samples = [amplitude * math.sin(2 * math.pi * i * dt) for i in range(steps + 1)]
    ops.timeSeries("Path", 1, "-dt", dt, "-values", *samples)
    if beam:
        # Equivalent -M*r*ag applied once. The supplied ElasticBeam2d.cpp
        # subtracts Q in both getResistingForce and getResistingForceIncInertia;
        # OpenSees 3.8.0 UniformExcitation doubles this element's ground load.
        # Plain loads avoid that upstream discrepancy in this mass benchmark.
        ops.pattern("Plain", 1, 1)
        ops.load(1, 0.0, -0.1, -0.2 / 12)
        ops.load(2, 0.0, -1.1, 0.2 / 12)
    else:
        ops.pattern("UniformExcitation", 1, direction, "-accel", 1, "-fact", -1.0)
    ops.constraints("Plain")
    ops.numberer("RCM")
    ops.system("BandGeneral")
    ops.test("NormUnbalance", 1e-9, 30)
    ops.algorithm("Newton")
    if integrator == "Newmark":
        ops.integrator("Newmark", 0.5, 0.25)
    else:
        ops.integrator("TRBDF2")
    ops.analysis("Transient")
    rows = [[0.0, 0.0, 0.0, 0.0]]
    for _ in range(steps):
        if ops.analyze(1, dt) != 0:
            raise RuntimeError(f"OpenSees failed at {ops.getTime()}")
        rows.append([ops.getTime(), ops.nodeDisp(2, direction),
                     ops.nodeVel(2, direction), ops.nodeAccel(2, direction)])
    with (OUTPUT / f"{name}.csv").open("w", newline="", encoding="ascii") as stream:
        writer = csv.writer(stream)
        writer.writerow(["time", "displacement", "velocity", "acceleration"])
        writer.writerows(rows)
    print(f"{name}: {steps} converged steps; {OUTPUT / (name + '.csv')}")


def modal_reference():
    ops.wipe()
    ops.model("basic", "-ndm", 2, "-ndf", 3)
    for node, xy in enumerate([(0, 0), (2, 1), (4, 0)], 1):
        ops.node(node, *xy)
    ops.fix(1, 1, 1, 1)
    ops.geomTransf("Linear", 1)
    for tag, rho in enumerate([0.2, 0.3], 1):
        ops.element("elasticBeamColumn", tag, tag, tag + 1, 1, 200, 0.1, 1,
                    "-mass", rho, "-cMass")
    for node, mass in enumerate([(2, 3, 0.4), (1, 2, 0.3), (2, 1, 0.5)], 1):
        ops.mass(node, *mass)
    lambdas = ops.eigen("-fullGenLapack", 6)
    shapes = [[ops.nodeEigenvector(node, mode + 1) for node in range(1, 4)]
              for mode in range(6)]
    data = {"Eigenvalues": lambdas, "ShapesByMode": shapes,
            "Properties": ops.modalProperties("-return"),
            "UNormProperties": ops.modalProperties("-unorm", "-return")}
    with (OUTPUT / "opensees_modal.json").open("w", encoding="ascii") as stream:
        json.dump(data, stream)
    print("Modal properties reference exported")


if __name__ == "__main__":
    print("OpenSees version:", ops.version())
    run("opensees_nonlinear")
    run("opensees_beam", beam=True)
    run("opensees_nonlinear_trbdf2", integrator="TRBDF2")
    run("opensees_beam_trbdf2", beam=True, integrator="TRBDF2")
    modal_reference()
