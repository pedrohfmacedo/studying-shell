# studying-shell

`studying-shell` is a small collection of Bash scripts for quickly creating hardware design and verification project skeletons.

The repository currently includes scripts for:

- creating a simple RTL/testbench/docs project
- creating a more complete digital design directory structure
- generating UVM project templates with pre-filled SystemVerilog files

## Repository Contents

- `create_prj.sh`: creates a minimal project under `prj/<project_name>/` with `rtl`, `tb`, and `docs`
- `create_prj_complet.sh`: creates a larger project structure for frontend, verification, backend, DFT, and documentation
- `create_uvm_project_elmar.sh`: generates a UVM-oriented project tree with example agent, environment, sequence, top, and simulation files
- `create_uvm_project_elmar_default.sh`: generates a default UVM template similar to the previous script, but with more placeholder-style content for customization

## Requirements

- Linux or another Unix-like environment
- `bash`
- permission to execute the scripts

If needed, make the scripts executable:

```bash
chmod +x *.sh
```

## Usage

All scripts expect a project name as the first argument.

### 1. Minimal Project

```bash
./create_prj.sh my_project
```

Generated structure:

```text
prj/my_project/
├── docs/
│   └── README.md
├── rtl/
└── tb/
```

### 2. Complete Project Structure

```bash
./create_prj_complet.sh my_project
```

Generated structure:

```text
prj/my_project/
├── DFT/
│   ├── constraints/
│   ├── logs/
│   ├── patterns/
│   ├── reports/
│   ├── scripts/
│   └── work/
├── backend/
│   ├── constraints/
│   ├── docs/
│   ├── logs/
│   ├── outputs/
│   ├── parasitics/
│   ├── physical/
│   ├── reports/
│   │   ├── area/
│   │   ├── power/
│   │   ├── signoff/
│   │   └── timing/
│   ├── structural/
│   └── work/
├── docs/
│   └── README.md
├── frontend/
│   ├── constraints/
│   ├── lec/
│   ├── logs/
│   ├── parasitics/
│   ├── reports/
│   │   ├── area/
│   │   ├── power/
│   │   └── timing/
│   ├── rtl/
│   │   ├── src/
│   │   └── tb/
│   ├── scripts/
│   │   └── genus/
│   ├── simulation/
│   │   ├── gatelevel/
│   │   └── rtl/
│   ├── structural/
│   │   └── genus/
│   ├── timing/
│   └── work/
└── verification/
    ├── docs/
    ├── logs/
    ├── reports/
    ├── scripts/
    ├── src/
    └── tb/
```

It is useful when starting a digital design flow that needs separated folders for reports, scripts, logs, constraints, simulation, and physical design artifacts.

### 3. UVM Project Template

```bash
./create_uvm_project_elmar.sh my_uvm_project
```

Generated structure:

```text
prj/my_uvm_project/
├── agents/
│   ├── agent.svh
│   ├── driver.svh
│   └── monitor.svh
├── docs/
│   └── README.md
├── env/
│   ├── coverage_in.svh
│   ├── coverage_out.svh
│   ├── env.svh
│   └── refmod.svh
├── rtl/
│   └── dut.sv
├── sequence/
│   ├── sequence.svh
│   ├── test.svh
│   └── trans.svh
├── sim/
│   ├── cover.do
│   ├── session.tcl
│   ├── simvision.svcf
│   └── wave.do
└── top/
    ├── interface.sv
    ├── test_pkg.sv
    └── top.sv
```

It also populates several `.sv` and `.svh` files with starter content for a UVM environment.

### 4. Default UVM Template

```bash
./create_uvm_project_elmar_default.sh my_uvm_project
```

Generated structure:

```text
prj/my_uvm_project/
├── agents/
│   ├── agent.svh
│   ├── driver.svh
│   └── monitor.svh
├── docs/
│   └── README.md
├── env/
│   ├── coverage_in.svh
│   ├── coverage_out.svh
│   ├── env.svh
│   └── refmod.svh
├── rtl/
│   └── dut.sv
├── sequence/
│   ├── sequence.svh
│   ├── test.svh
│   └── trans.svh
├── sim/
│   ├── cover.do
│   ├── session.tcl
│   ├── simvision.svcf
│   └── wave.do
└── top/
    ├── interface.sv
    ├── test_pkg.sv
    └── top.sv
```

This version is useful when you want a more generic starting point with placeholders that can be adapted to your DUT and verification flow.

## Notes

- All generated projects are created inside the `prj/` directory.
- If a project with the same name already exists, the script stops to avoid overwriting it.
- Some generated UVM files are templates and may require manual fixes or adaptation before use in a simulator.

## Example

```bash
./create_prj.sh alu
./create_prj_complet.sh divider_top
./create_uvm_project_elmar.sh fifo_uvm
```

## License

No license file is included yet. Add one if you plan to share or publish this repository.
