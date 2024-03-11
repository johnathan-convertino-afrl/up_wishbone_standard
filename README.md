# WISHBONE CLASSIC SLAVE
### Wishbone slave to Analog Devices uP interface
---

   author: Jay Convertino   
   
   date: 2024.02.19
   
   details: Interface analog devices uP interface devices to Wishbone Classic bus
   
   license: MIT   
   
---

### Version
#### Current
  - V1.0.0 - initial release

#### Previous
  - none

### Dependencies
#### Build
  - AFRL:utility:helper:1.0.0
  
#### Simulation
  - AFRL:simulation:axis_stimulator

### IP USAGE
#### INSTRUCTIONS


#### PARAMETERS

### COMPONENTS
#### SRC

* wishbone_slave.v

  
#### TB

* tb_wishbone_slave.v
  
### fusesoc

* fusesoc_info.core created.
* Simulation uses icarus to run data through the core.

#### TARGETS

* RUN WITH: (fusesoc run --target=sim VENDER:CORE:NAME:VERSION)
  - default (for IP integration builds)
  - sim
