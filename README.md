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
This core is made to interface a Wishbone Classic bus to uP based device cores. This is part of a family of converters based on Analog Devices uP specification. Using this allows usage of Analog Devices AXI Lite core, AFRL APB3, AFRL Wishbone Classic, and AFRL Wishbone Pipeline converters. Meaning any uP core can be easily customized to any bus quickly. These are made for relativly slow speed bus device interfaces.

#### uP example

```
  //output signals assigned to registers.
  assign up_rack  = r_up_rack & up_rreq;
  assign up_wack  = r_up_wack & up_wreq;
  assign up_rdata = r_up_rdata;
  assign irq      = r_irq;

  assign s_rx_ren = ((up_raddr[3:0] == RX_FIFO_REG) && up_rreq ? r_up_rack & r_rx_ren : 0);

  //up registers decoder
  always @(posedge clk)
  begin
    if(rstn == 1'b0)
    begin
      r_up_rack   <= 1'b0;
      r_up_wack   <= 1'b0;
      r_up_rdata  <= 0;

      r_rx_ren    <= 1'b0;

      r_overflow  <= 1'b0;

      r_control_reg <= 0;
    end else begin
      r_up_rack   <= 1'b0;
      r_up_wack   <= 1'b0;
      r_tx_wen    <= 1'b0;
      r_rx_ren    <= 1'b0;
      r_up_rdata  <= r_up_rdata;
      //clear reset bits
      r_control_reg[RESET_RX_BIT] <= 1'b0;
      r_control_reg[RESET_TX_BIT] <= 1'b0;

      if(rx_full == 1'b1)
      begin
        r_overflow <= 1'b1;
      end

      //read request
      if(up_rreq == 1'b1)
      begin
        r_up_rack <= 1'b1;

        case(up_raddr[3:0])
          RX_FIFO_REG: begin
            r_up_rdata <= rx_rdata & {{(BUS_WIDTH*8-DATA_BITS){1'b0}}, {DATA_BITS{1'b1}}};
            r_rx_ren <= 1'b1;
          end
          STATUS_REG: begin
            r_up_rdata <= {{(BUS_WIDTH*8-8){1'b0}}, s_parity_err, s_frame_err, r_overflow, r_irq_en, tx_full, tx_empty, rx_full, rx_valid};
            r_overflow <= 1'b0;
          end
          default:begin
            r_up_rdata <= 0;
          end
        endcase
      end

      //write request
      if(up_wreq == 1'b1)
      begin
        r_up_wack <= 1'b1;

        //only allow write once ack (Analog Devices does the same)
        if(r_up_wack == 1'b1) begin
          case(up_waddr[3:0])
            TX_FIFO_REG: begin
              r_tx_wdata  <= up_wdata;
              r_tx_wen    <= 1'b1;
            end
            CONTROL_REG: begin
              r_control_reg <= up_wdata;
            end
            default:begin
            end
          endcase
        end
      end
    end
  end

  //up control register processing and fifo reset
  always @(posedge clk)
  begin
    if(rstn == 1'b0)
    begin
      r_rstn_rx_delay <= ~0;
      r_rstn_tx_delay <= ~0;
      r_irq_en <= 1'b0;
    end else begin
      r_rstn_rx_delay <= {1'b1, r_rstn_rx_delay[FIFO_DEPTH-1:1]};
      r_rstn_tx_delay <= {1'b1, r_rstn_rx_delay[FIFO_DEPTH-1:1]};

      if(r_control_reg[RESET_RX_BIT])
      begin
        r_rstn_rx_delay <= {FIFO_DEPTH{1'b0}};
      end

      if(r_control_reg[RESET_TX_BIT])
      begin
        r_rstn_tx_delay <= {FIFO_DEPTH{1'b0}};
      end

      if(r_control_reg[ENABLE_INTR_BIT] != r_irq_en)
      begin
        r_irq_en <= r_control_reg[ENABLE_INTR_BIT];
      end
    end
  end
```

#### PARAMETERS

* ADDRESS_WIDTH : Bit width of the address bus.
* BUS_WIDTH     : Bus width in number of bytes.

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
