# WISHBONE STANDARD SLAVE
### Wishbone Classic Standard Slave B4 to Analog Devices uP interface

![image](docs/manual/img/AFRL.png)

---

  author: Jay Convertino   
  
  date: 2024.02.19
  
  details: Interface analog devices uP interface devices to Wishbone Classic Standard bus B4 no burst modes.
  
  license: MIT   
   
  Actions:  

  [![Lint Status](../../actions/workflows/lint.yml/badge.svg)](../../actions)  
  [![Manual Status](../../actions/workflows/manual.yml/badge.svg)](../../actions)  
  
---

### Version
#### Current
  - V1.0.0 - initial release

#### Previous
  - none

### DOCUMENTATION
  For detailed usage information, please navigate to one of the following sources. They are the same, just in a different format.

  - [up_wishbone_standard.pdf](docs/manual/up_wishbone_standard.pdf)
  - [github page](https://johnathan-convertino-afrl.github.io/up_wishbone_standard/)

### PARAMETERS

* ADDRESS_WIDTH : Bit width of the address bus.
* BUS_WIDTH     : Bus width in number of bytes.

### COMPONENTS
#### SRC

* up_wishbone_standard.v
  
#### TB

* tb_wishbone_slave.v
* tb_cocotb.v
* tb_cocotb.py
  
### FUSESOC

* fusesoc_info.core created.
* Simulation uses icarus to run data through the core.

#### Targets

* RUN WITH: (fusesoc run --target=sim VENDER:CORE:NAME:VERSION)
  - default (for IP integration builds)
  - lint
  - sim
  - sim_cocotb
