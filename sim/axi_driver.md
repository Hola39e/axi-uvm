# uvm axi master driver design

## main data types and methods

five mailbox, used to 5 threads
- mailbox #(axi_seq_item) writeaddress_mbx  = new(0);  
- mailbox #(axi_seq_item) writedata_mbx     = new(0);
- mailbox #(axi_seq_item) writeresponse_mbx = new(0);
- mailbox #(axi_seq_item) readaddress_mbx   = new(0);
- mailbox #(axi_seq_item) readdata_mbx      = new(0);

memory block
- memory

axi configuration
- axi_config

virtual interface
- axi_if

## run phase threads

main code of run phase
```verilog

task run_phase(uvm_phase phase);
  axi_seq_item item;

    // child treads
    fork
       write_address();
       write_data();
       write_response();
       read_address();
       read_data();
    join_none

    forever begin
        seq_item_port.get(item);

        `uvm_info(this.get_type_name(),
                $sformatf("Item: %s", item.convert2string()),
                UVM_INFO)

        case (item.cmd)
            axi_uvm_pkg::e_WRITE : begin
                writeaddress_mbx.put(item);
            end
            axi_uvm_pkg::e_READ  : begin
                readaddress_mbx.put(item);
            end
        endcase
    end 
endtask
```

### analysis

the run phase start 5 child thread to write address / write data / write response / read address / read data, and in the forever loop, the `seq_item_port` get sequence item from sequencer, and put seq item to write mailbox or read mailbox.

## what do in write address thread

there are serveral data types in write address thread:
- `axi_seq_item item;` used to get mailbox axi_seq_item
- `axi_seq_item_aw_vector_s;` which contain more imformation to send on axi_bus, such as aligned address, etc.
- `bit [ADDR_WIDTH-1:0] aligned addr;` 
- `bit wstrb[]` 
- `int minval, maxval;` range about wait cycles to next AWVALID asssert.
- `int wait_clks_before_next_aw;` which is wait how many cycles to start transcation.


### write address thread operation

when the write addres init (first run):
- set `AXVALID <= 0;`
- wait rest_n is not 0 (blocking)
  - **then get into forever loop**
  - get sequence_item from writeaddress mailbox 
  - convert and calculate axi_sequence_item to axi_seq_item_aw_vector_s
    - what do in convert? 
      - calculate burst aligned address
      - calculate axlen
      - assign orther values, such as burst_size, burst_type, lock...
  - `@(posedge clk)`
  - put item into mailbox

#### about calculate_burst_aligned_address

the burst aligned address depends on AWBURST (burst size in every transfer), could according to this:
```verilog
aligned_address = address;
case (burst_size)
    e_1BYTE    : aligned_address      = address;
    e_2BYTES   : aligned_address[0]   = 1'b0;
    e_4BYTES   : aligned_address[1:0] = 2'b00;
    e_8BYTES   : aligned_address[2:0] = 3'b000;
    e_16BYTES  : aligned_address[3:0] = 4'b0000;
    e_32BYTES  : aligned_address[4:0] = 5'b0_0000;
    e_64BYTES  : aligned_address[5:0] = 6'b00_0000;
    e_128BYTES : aligned_address[6:0] = 7'b000_0000;
endcase
```

#### about calculate axlen



```verilog
        // ---------------------------forever loop below ------------------------
        if (item == null) begin
            writeaddress_mbx.get(item);
            `uvm_info("axi_driver::write_address",
                        $sformatf("Item: %s", item.convert2string()),
                        UVM_HIGH)

            axi_uvm_pkg::aw_from_class(.t(item), .v(v));
        end
        vif.wait_for_clks(.cnt(1));
      // if done with this xfer (write address is only one clock, done with valid & ready
      // if get awready and awvalid handshake success, get into this:
      //    1. put write data into mailbox
      //    2. assign the minval and maxval to set delay
      //    3. try get next axi_sequence item.
       if (vif.get_awready_awvalid == 1'b1) begin
          writedata_mbx.put(item);
          item=null;

          minval=m_config.min_clks_between_aw_transfers;
          maxval=m_config.max_clks_between_aw_transfers;
          wait_clks_before_next_aw=$urandom_range(maxval,minval);

          // Check if delay wanted
          if (wait_clks_before_next_aw==0) begin
             // if not, check if there's another item

            if (writeaddress_mbx.try_get(item)) begin
                    `uvm_info("axi_driver::write_address",
                $sformatf("Item: %s", item.convert2string()),
                UVM_HIGH)

                axi_uvm_pkg::aw_from_class(.t(item), .v(v));
             end
          end
       end
       // Initialize values  <-no need

       // Update values <- No need in write address (only one clk per)

       // Write out
       // drive write address channel:
       /* in write_aw function:
                iawvalid <= valid;
                iawid    <= s.awid;
                iawaddr  <= s.awaddr;
                iawlen   <= s.awlen;
                iawsize  <= s.awsize;
                iawburst <= s.awburst;
                iawlock  <= s.awlock;
                iawcache <= s.awcache;
                iawprot  <= s.awprot;
                iawqos   <= s.awqos;
        */
       if (item != null) begin
          vif.write_aw(.s(v), .valid(1'b1));
       end  
       else begin// if (item != null)
            // if there is no item:
            // No item for next clock, so close out bus
            v.awaddr  = 'h0;
            v.awid    = 'h0;
            v.awsize  = 'h0;
            v.awburst = 'h0;
            vif.write_aw(.s(v), .valid(1'b0));


            // delay for next transaction
            if (wait_clks_before_next_aw > 0) begin
            vif.wait_for_clks(.cnt(wait_clks_before_next_aw-1)); // -1 because another wait
                                                                    // // at beginning of loop
            end
        end
```

### write data thread
