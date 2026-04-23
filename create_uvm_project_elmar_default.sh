#!/bin/bash

# Check if the project name was provided as an argument
if [ -z "$1" ]; then
 echo "Error: please provide the project name."
 echo "Usage: ./create_prj.sh <project_name>"
 exit 1
fi

PRJ_NAME=$1
BASE_DIR="prj/$PRJ_NAME"

# Check if the project directory already exists
if [ -d "$BASE_DIR" ]; then
 echo "Error: project '$PRJ_NAME' already exists."
 exit 1
fi

# =========================
# Create project structure
# =========================

# Agents, docs, env, rtl, sequence, sim, top
mkdir -p "$BASE_DIR"/agents
mkdir -p "$BASE_DIR"/docs
mkdir -p "$BASE_DIR"/env
mkdir -p "$BASE_DIR"/rtl
mkdir -p "$BASE_DIR"/sequence
mkdir -p "$BASE_DIR"/sim
mkdir -p "$BASE_DIR"/top

# =========================
# Create placeholder files
# =========================

touch "$BASE_DIR"/agents/{agent.svh,driver.svh,monitor.svh}
touch "$BASE_DIR"/env/{coverage_in.svh,coverage_out.svh,env.svh,refmod.svh}
touch "$BASE_DIR"/rtl/{dut.sv}
touch "$BASE_DIR"/sequence/{sequence.svh,test.svh,trans.svh}
touch "$BASE_DIR"/sim/{cover.do,wave.do,session.tcl,simvision.svcf}
touch "$BASE_DIR"/top/{interface.sv,top.sv,test_pkg.sv}

# Create README 
touch "$BASE_DIR/docs/README.md"

# =========================
# Create files UVM
# =========================

#agents: agent.svh
cat <<'EOF' > "$BASE_DIR"/agents/agent.svh
class agent extends uvm_agent;
  `uvm_component_utils(agent)
    
   uvm_analysis_port #(a_tr) out;
    
   sequencer sequencer_h;
   driver_master driver_h;
   monitor monitor_h;

   function new(string name, uvm_component parent);
     super.new(name, parent);
   endfunction

   function void build_phase(uvm_phase phase);
     super.build_phase(phase);
     out = new("out", this);
     if(get_is_active() == UVM_ACTIVE) begin
        sequencer_h = sequencer::type_id::create("sequencer_h", this);
        driver_h = driver_master::type_id::create("driver_h", this);
     end
     monitor_h = monitor::type_id::create("monitor_h", this);
   endfunction

   function void connect_phase(uvm_phase phase);
     monitor_h.out.connect (out);
     if(get_is_active() == UVM_ACTIVE) begin
        driver_h.seq_item_port.connect( sequencer_h.seq_item_export );
     end
   endfunction
    
endclass
EOF

########################## driver ##########################
#agents: driver.svh
cat <<'EOF' > "$BASE_DIR"/agents/driver.svh
class driver_master extends uvm_driver #(a_tr);
  `uvm_component_utils(driver_master)

   function new(string name, uvm_component parent);
     super.new(name, parent);
   endfunction

   // a virtual interface must be substituted later with an actual interface instance
   virtual a_if a_vi; 

   function void build_phase(uvm_phase phase);
     super.build_phase(phase);
     // get interface instance from database
     assert( uvm_config_db #(virtual a_if)::get(this, "", "a_vi", a_vi) );
   endfunction

   task run_phase(uvm_phase phase);
    // insert your logical initialization here, for example:
     a_vi.valid <= 'x; a_vi.a  <= 'x;   
    // reset may occur at any time, therefore let's treat is in a separate task
     fork 
       reset_signals(); get_and_drive();
     join
   endtask

   task reset_signals();
      forever begin
      // insert your reset logic here, for example:
         wait (a_vi.reset === 1); | a_vi.valid <= 0; | a_vi.a  <= 'x;   
         @(negedge a_vi.reset);
      end
   endtask

   task get_and_drive();
   // insert your get and drive logic here
      a_tr tr_sequencer; // transaction coming from sequencer

      forever begin
          wait (a_vi.reset === 0);
          seq_item_port.get_next_item(tr_sequencer); // get transaction
          // wiggle interface signals
          @(posedge a_vi.clock);
          a_vi.valid <= 1; a_vi.a <= tr_sequencer.a;
          seq_item_port.item_done(); // notify sequencer that transaction is completed
          @(posedge a_vi.clock);
          a_vi.valid <= 0;
          @(posedge a_vi.clock);

        end
   endtask

endclass
EOF

#agents: monitor.svh
cat <<'EOF' > "$BASE_DIR"/agents/monitor.svh
class monitor extends uvm_monitor;  
   `uvm_component_utils(monitor)

   uvm_analysis_port #(a_tr) out;
    
   virtual a_if a_vi; 

   function new(string name, uvm_component parent);
      super.new(name, parent);
      out = new("out", this);
   endfunction: new
    
   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      assert( uvm_config_db #(virtual a_if)::get(this, "", "a_vi", a_vi) );
   endfunction
   
   task run_phase(uvm_phase phase);
      a_tr tr;
      forever begin
         wait (a_vi.reset === 0); // wait for reset positive edge
         tr = a_tr::type_id::create("tr");
         @(posedge a_vi.clock iff (a_vi.valid)); // at next rising clock which has valid set
         `bvm_begin_tr(tr) // start transaction recording
         tr.a = a_vi.a; // get transaction property value
       
         out.write(tr);
      end
   endtask

endclass
EOF

########################## env ##########################
#env: coverage_in.svh
cat <<'EOF' > "$BASE_DIR"/env/coverage_in.svh
class coverage_in extends bvm_cover #(a_tr);
   `uvm_component_utils(coverage_in)

   covergroup transaction_covergroup;  // predefined name of covergroup
      option.per_instance = 1;
      // Create a coverpoint for transaction property 'a' with your bins
      // Coverage_transaction is predefined name of transaction instance
      coverpoint coverage_transaction."variable" { 
        ... "your bins here" ...
      }
   endgroup
   `bvm_cover_utils(a_tr)
    
endclass
EOF
#env: coverage_out.svh
cat <<'EOF' > "$BASE_DIR"/env/coverage_out.svh
class coverage_out extends bvm_cover #(a_tr);
   `uvm_component_utils(coverage_out)

  \\ Define your covergroup here
   covergroup transaction_covergroup;  
      option.per_instance = 1; // Each instance of coverage_out will have its own coverage data
      coverpoint coverage_transaction."variable" {
        .... "your bins here" ...
      }
    endgroup
   `bvm_cover_utils(a_tr)
    
endclass
EOF

#env: env.svh
cat <<'EOF' > "$BASE_DIR"/env/env.svh
class env extends uvm_env;
   `uvm_component_utils(env)

  \\ Define your environment components here, for example:
   agent agent_in_h;
   agent agent_out_h;
   coverage_in coverage_in_h;
   coverage_out coverage_out_h;
   uvm_tlm_analysis_fifo #(a_tr) agent_refmod;
   refmod refmod_h;
   bvm_comparator #(a_tr) comparator_h;

  \\ The build_phase is where you create your components and set their configuration
   function new(string name, uvm_component parent);
     super.new(name, parent);
   endfunction

  \\ In the build_phase, we create the components and set their configuration
   function void build_phase(uvm_phase phase);
     super.build_phase(phase);
     set_config_int("agent_in_h", "is_active", UVM_ACTIVE);
     agent_in_h = agent::type_id::create("agent_in_h", this);
     set_config_int("agent_out_h", "is_active", UVM_PASSIVE);
     agent_out_h = agent::type_id::create("agent_out_h", this);
     coverage_in_h = coverage_in::type_id::create("cover_in_h", this);
     coverage_out_h = coverage_out::type_id::create("cover_out_h", this);
     agent_refmod = new("agent_refmod",this);
     refmod_h = refmod::type_id::create("refmod_h", this);
     comparator_h = bvm_comparator#(a_tr)::type_id::create("comparator_h", this);
   endfunction

  \\ In the connect_phase, we connect the ports and exports of the components together
   function void connect_phase(uvm_phase phase);
     agent_in_h.out.connect (coverage_in_h.analysis_export);
     agent_in_h.out.connect (agent_refmod.analysis_export);
     refmod_h.in.connect (agent_refmod.get_export );
     refmod_h.out.connect( comparator_h.from_refmod );
     agent_out_h.out.connect( comparator_h.from_dut );
     agent_out_h.out.connect (coverage_out_h.analysis_export);
   endfunction
   
endclass
EOF

#env: refmod.svh
cat <<'EOF' > "$BASE_DIR"/env/refmod.svh
class refmod extends uvm_component;
   `uvm_component_utils(refmod)

   uvm_get_port #(a_tr) in; 
   uvm_blocking_put_port #(a_tr) out;  

  \\ The refmod can be implemented in any way, for example, as a simple transaction transformer 
   function new(string name, uvm_component parent=null);
      super.new(name,parent);
      in  = new("in",  this);
      out = new("out", this);
   endfunction : new
  \\ The run_phase is where you implement the behavior of the refmod, for example, transforming the transaction coming from the agent_in_h and sending it to the comparator
   task run_phase (uvm_phase phase);

  \\ Insert your refmod behavior here, for example:
     a_tr tr_in, tr_out;

    #  forever begin
    #     in.get(tr_in);
    #     #10;
    #     `bvm_end_tr(tr_in);
    #     tr_out = a_tr::type_id::create("tr_out", this);
    #     tr_out.a = tr_in.a + 100;
    #     `bvm_begin_tr(tr_out)
    #     #10;
    #     out.put(tr_out);
     end

   endtask

endclass
EOF

########################## rtl ##########################
#rtl: dut.sv
cat <<'EOF' > "$BASE_DIR"/rtl/dut.svh
module dut (...);
    // Insert your DUT implementation here, for example:
endmodule
EOF

########################## sequence ##########################
#sequence: sequence.svh
cat <<'EOF' > "$BASE_DIR"/sequence/sequence.svh
class a_sequence extends uvm_sequence #(a_tr);
    `uvm_object_utils(a_sequence)
    
    // The new function is where you can set default values for the sequence, for example:
    function new (string name = "a_sequence");
      super.new(name);
    endfunction: new

    // The body task is where you implement the sequence behavior, for example, generating transactions in a loop
    task body;
      a_tr tr;

    // Insert your sequence behavior here, for example:
      forever begin
        `uvm_do(tr)
      end
    endtask
  
endclass

EOF
#sequence: test.svh
cat <<'EOF' > "$BASE_DIR"/sequence/test.svh
class a_sequence extends uvm_sequence #(a_tr);
    `uvm_object_utils(a_sequence)
    
    // The new function is where you can set default values for the sequence, for example:
    function new (string name = "a_sequence");
      super.new(name);
    endfunction: new

    // The body task is where you implement the sequence behavior, for example, generating transactions in a loop
    task body;
      a_tr tr;

    // Insert your sequence behavior here, for example:
      forever begin
        `uvm_do(tr)
      end
    endtask
   
endclass
EOF
#sequence: trans.svh
cat <<'EOF' > "$BASE_DIR"/sequence/trans.svh
class a_tr extends uvm_sequence_item;

  // Define your transaction properties here, for example:
  rand int a; constraint a_positive { a > 0; }; constraint a_small { a < 20; }

  // The new function is where you can set default values for the transaction properties, for example:
  `uvm_object_utils_begin(a_tr)  // needed for transaction recording
     `uvm_field_int(a, UVM_ALL_ON | UVM_DEC)
  `uvm_object_utils_end

endclass
EOF
########################## sim ##########################
#sim: cover.do
cat <<'EOF' > "$BASE_DIR"/sim/.cover.do
noview .main_pane.structure
noview objects
view covergroups
EOF
#sim: wave.do
cat <<'EOF' > "$BASE_DIR"/sim/.wave.do
onerror {resume}
noview .main_pane.structure .main_pane.library .main_pane.objects .main_pane.process
quietly WaveActivateNextPane {} 0
add wave -noupdate -height 30 -expand -subitemconfig {/uvm_root/uvm_test_top/env_h/agent_in_h/sequencer_h/seq.s1 {-childformat {{/uvm_root/uvm_test_top/env_h/agent_in_h/sequencer_h/seq.s1.a -radix decimal}} -expand} /uvm_root/uvm_test_top/env_h/agent_in_h/sequencer_h/seq.s1.a {-height 16 -radix decimal}} /uvm_root/uvm_test_top/env_h/agent_in_h/sequencer_h/seq
add wave -noupdate /top/in/clock
add wave -noupdate /top/in/reset
add wave -noupdate /top/in/valid
add wave -noupdate -radix decimal /top/in/a
add wave -noupdate -childformat {{/uvm_root/uvm_test_top/env_h/agent_in_h/monitor_h/tr.t0.a -radix decimal}} -expand -subitemconfig {/uvm_root/uvm_test_top/env_h/agent_in_h/monitor_h/tr.t0.a {-radix decimal}} /uvm_root/uvm_test_top/env_h/agent_in_h/monitor_h/tr
add wave -noupdate /top/out/valid
add wave -noupdate -radix decimal /top/out/a
add wave -noupdate -childformat {{/uvm_root/uvm_test_top/env_h/agent_out_h/monitor_h/tr.t0.a -radix decimal}} -expand -subitemconfig {/uvm_root/uvm_test_top/env_h/agent_out_h/monitor_h/tr.t0.a {-radix decimal}} /uvm_root/uvm_test_top/env_h/agent_out_h/monitor_h/tr
add wave -noupdate -childformat {{/uvm_root/uvm_test_top/env_h/refmod_h/tr_out.t0.a -radix decimal}} -expand -subitemconfig {/uvm_root/uvm_test_top/env_h/refmod_h/tr_out.t0.a {-radix decimal}} /uvm_root/uvm_test_top/env_h/refmod_h/tr_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {5 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 400
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {250 ns}
EOF

#sim: session.tcl
cat <<'EOF' > "$BASE_DIR"/sim/.session.tcl
gui_open_db -design V1 -file vcdplus.vpd -nosource
gui_set_radix -radix {decimal} -signals {V1:top.in.a}
gui_set_radix -radix {decimal} -signals {V1:top.out.a}
set TopLevel.1 TopLevel.1

set Wave.1 [gui_create_window -type {Wave}  -parent ${TopLevel.1}]

set _session_group_1 transaction
gui_sg_create "$_session_group_1"
set transaction "$_session_group_1"
gui_sg_addsignal -group "$_session_group_1" { {uvm_test_top$env_h$agent_in_h$sequencer_h}
                                              top.in.clock top.in.reset top.in.valid top.in.a
                                              {uvm_test_top_env_h_agent_in_h_monitor_h_tr}
                                              top.out.valid top.out.a
                                              {uvm_test_top_env_h_agent_out_h_monitor_h_tr}
                                              {uvm_test_top_env_h_refmod_h_tr_out} }   -objtype stream
gui_list_add_group -id ${Wave.1} -after {New Group} {transaction}
gui_list_set_height -id ${Wave.1} -height 131  -name {V1:uvm_test_top$env_h$agent_in_h$sequencer_h} -occurrence 1 -group ${transaction}
gui_list_set_height -id ${Wave.1} -height 80  -name {V1:uvm_test_top_env_h_agent_in_h_monitor_h_tr} -occurrence 1 -group ${transaction}
gui_list_set_height -id ${Wave.1} -height 80  -name {V1:uvm_test_top_env_h_agent_out_h_monitor_h_tr} -occurrence 1 -group ${transaction}
gui_list_set_height -id ${Wave.1} -height 80  -name {V1:uvm_test_top_env_h_refmod_h_tr_out} -occurrence 1 -group ${transaction}

gui_close_window -type HSPane
gui_close_window -type DLPane
gui_close_window -type Transaction
gui_close_window -type Source
gui_close_window -type Console

gui_wv_zoom_timerange -id ${Wave.1} 0 160
EOF

#sim: simvision.svcf
cat <<'EOF' > "$BASE_DIR"/sim/.simvision.svcf
# SimVision Command Script (Tue Mar 07 09:00:44 PM BRT 2017)
#
# Version 15.20.s013
#
# You can restore this configuration with:
#
#     simvision -input simvision.svcf
#

#
# Databases
#
database require waves -search {
      ./waves.shm/waves.trn
}

#
# Waveform windows
#

window new WaveWindow -name "Waveform 1"
window target "Waveform 1" on
waveform using {Waveform 1}

set id [waveform add -signals  {
      waves::$uvm:{uvm_test_top.env_h.agent_in_h.sequencer_h}.seq
      waves::$uvm:{uvm_test_top.env_h.agent_in_h.monitor_h}.tr
      } ]
waveform hierarchy set -expandtype Attr:begin_time $id
waveform add -signals  { waves::top.in.clock
                         waves::top.in.reset
                         waves::top.in.valid }
set id [waveform add -signals  {
        {waves::top.in.a[7:0]}
        } ]
waveform format $id -radix %d
waveform add -signals  { waves::top.out.valid }
set id [waveform add -signals  {
        {waves::top.out.a[7:0]}
        } ]
waveform format $id -radix %d
set id [waveform add -signals  {
      waves::$uvm:{uvm_test_top.env_h.agent_out_h.monitor_h}.tr
      waves::$uvm:{uvm_test_top.env_h.refmod_h}.tr_out
	} ]
waveform hierarchy set -expandtype Attr:begin_time $id

EOF

########################## top ##########################
#top: interface.sv
cat <<'EOF' > "$BASE_DIR"/top/interface.sv
// The collection of signal ports for DUT and testbench
interface a_if (input logic clock, reset);

  logic valid; // handshake signal: a is valid at rising clock when valid=1
  logic [7:0] a; // not using parameter to keep it simpler

  // The interface input port is for incoming data.
  modport inp (input clock, reset, input valid, input a);

  // The interface output port is for outcoming data.
  modport outp (input clock, reset, output valid, output a);

endinterface
EOF

#top: top.sv
cat <<'EOF' > "$BASE_DIR"/top/top.sv
module top;
   import uvm_pkg::*;
   import test_pkg::*;

   // Clock generator
   logic clock;
   initial begin
     clock = 0; forever #5 clock = ~clock;
   end

   // reset generator
   logic reset;
   initial begin
     reset = 1;
     repeat(2) @(negedge clock);
     reset = 0;
   end

   // input and output interface instance for DUT
   a_if in(.*); //
   a_if out(.*); //
   dut d(.*);

   initial begin
      // vendor dependent waveform recording
      `ifdef INCA
        $shm_open("waves.shm");
        $shm_probe("AS");
      `endif
      `ifdef VCS
        $vcdpluson;
      `endif
      `ifdef QUESTA
        $wlfdumpvars();
      `endif

      // register the input and output interface instance in the database
      uvm_config_db #(virtual a_if)::set(null, "uvm_test_top.env_h.agent_in_h.*", "a_vi", in);
      uvm_config_db #(virtual a_if)::set(null, "uvm_test_top.env_h.agent_out_h.*", "a_vi", out);

      run_test("test");
   end
endmodule
EOF
#top: test_pkg.sv
cat <<'EOF' > "$BASE_DIR"/top/test_pkg.sv
`include "uvm_macros.svh"
`include "bvm_macros.svh" // macros created by Brazil-IP / UFCG

package test_pkg;

  import uvm_pkg::*;
  import bvm_pkg::*;

  `include "trans.svh"
  `include "sequence.svh"
  typedef uvm_sequencer #(a_tr) sequencer; //
  `include "driver.svh"
  `include "monitor.svh"
  `include "agent.svh"
  `include "coverage_in.svh"
  `include "coverage_out.svh"
  `include "refmod.svh"
  `include "env.svh"
  `include "test.svh"

endpackage
EOF










echo "Project '$PRJ_NAME' successfully created inside prj/"