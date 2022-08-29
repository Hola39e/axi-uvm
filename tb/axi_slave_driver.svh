class axi_slave_driver extends uvm_driver #(axi_seq_item);
    `uvm_component_utils(axi_slave_driver)

    axi_if_abstract vif;
    axi_agent_config m_config;
    memmory m_memory;

    mailbox #(axi_seq_item) writeaddress_mbx  = new(0);  //unbounded mailboxes
    mailbox #(axi_seq_item) writedata_mbx     = new(0);
    mailbox #(axi_seq_item) writeresponse_mbx = new(0);
    mailbox #(axi_seq_item) readaddress_mbx   = new(0);
    mailbox #(axi_seq_item) readdata_mbx      = new(0);

    extern function new (string name="axi_driver", uvm_component parent=null);

    extern function void build_phase     (uvm_phase phase);
    extern function void connect_phase   (uvm_phase phase);
    extern task          run_phase       (uvm_phase phase);

    extern task          write_address   ();
    extern task          write_data      ();
    extern task          write_response  ();
    extern task          read_address    ();
    extern task          read_data       ();
endclass

function axi_slave_driver::new(string name = "axi_slave_driver", uvm_component parent = null);
    super.new(name, parent);
endfunction

/*! \brief Creates the virtual interface */
function void axi_slave_driver::build_phase (uvm_phase phase);
    super.build_phase(phase);

    vif = axi_if_abstract::type_id::create("vif", this);
endfunction : build_phase

/*! \brief
*
* Nothing to connect so doesn't actually do anything except call parent connect phase */
function void axi_slave_driver::connect_phase (uvm_phase phase);
    super.connect_phase(phase);
endfunction : connect_phase

task axi_slave_driver::run_phase(uvm_phase phase);
    fork
        write_address();
        write_data();
        write_response();
        read_address();
        read_data();
    join_none
endtask

task axi_slave_driver::write_address();

    axi_seq_item slv_wtrans;
    vif.set_awvalid(1'b0);

    vif.wait_for_not_in_reset();

    forever begin
        vif.wait_for_clks(.cnt(1));
        wait
        slv_wtrans.id = vif.AWID;
    end
endtask