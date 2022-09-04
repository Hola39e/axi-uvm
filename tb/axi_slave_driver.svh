class axi_slave_driver extends uvm_driver #(axi_seq_item);
	`uvm_component_utils(axi_slave_driver)

	axi_if_abstract vif;
	axi_agent_config m_config;
	memory m_memory;
	virtual axi_if #(
		.C_AXI_ADDR_WIDTH(params_pkg::AXI_ADDR_WIDTH),
		.C_AXI_DATA_WIDTH(params_pkg::AXI_DATA_WIDTH),
		.C_AXI_ID_WIDTH(params_pkg::AXI_ID_WIDTH),
		.C_AXI_LEN_WIDTH(params_pkg::AXI_LEN_WIDTH)) axi_vif ;

	mailbox #(axi_seq_item) writeaddress_mbx  = new(0);  //unbounded mailboxes
	mailbox #(axi_seq_item) writedata_mbx     = new(0);
	mailbox #(axi_seq_item) writeresponse_mbx = new(0);
	mailbox #(axi_seq_item) readaddress_mbx   = new(0);
	mailbox #(axi_seq_item) readdata_mbx      = new(0);

	extern function new (string name="axi_slave_driver", uvm_component parent=null);

	extern function void build_phase     (uvm_phase phase);
	extern function void connect_phase   (uvm_phase phase);
	extern task          run_phase       (uvm_phase phase);
	extern function string print_axi_seq_item_write_vector(axi_seq_item_aw_vector_s aws);
	extern function void read_aw (axi_seq_item_aw_vector_s s);

	extern task          write_address   ();
    extern task          write_data      ();
//    extern task          write_response  ();
	extern task          read_address    ();
//    extern task          read_data       ();
endclass:axi_slave_driver

function axi_slave_driver::new(string name="axi_slave_driver", uvm_component parent=null);
	super.new(name, parent);
endfunction

/*! \brief Creates the virtual interface */
function void axi_slave_driver::build_phase (uvm_phase phase);
	super.build_phase(phase);
	if(!uvm_config_db #(virtual axi_if #(
					.C_AXI_ADDR_WIDTH(params_pkg::AXI_ADDR_WIDTH),
					.C_AXI_DATA_WIDTH(params_pkg::AXI_DATA_WIDTH),
					.C_AXI_ID_WIDTH(params_pkg::AXI_ID_WIDTH),
					.C_AXI_LEN_WIDTH(params_pkg::AXI_LEN_WIDTH)))
			::get(this, "", "vif", axi_vif))begin
		`uvm_fatal("AXI SLAVE", "CANNOT GET interface")
	end
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
		//write_response();
		read_address();
	//read_data();
	join_none
endtask

//task axi_slave_driver::write_address();
//
//    axi_seq_item slv_wtrans;
//    vif.set_awvalid(1'b0);
//
//    vif.wait_for_not_in_reset();
//
//    forever begin
//        vif.wait_for_clks(.cnt(1));
//        wait_for_awvalid();
//        slv_wtrans.id     = vif.s_drv_cb.iawid;
//        slv_wtrans.addr   = vif.s_drv_cb.iawaddr;
//        slv_wtrans.burst_size = vif.s_drv_cb.iawsize;
//        slv_wtrans.burst_type = B_TYPE'(vif.s_drv_cb.iawburst);
//        slv_wtrans.axlen  = vif.s_drv_cb.iawlen;
//
//        // should push here to support outstanding
//    end
//
//
//endtask

function string axi_slave_driver::print_axi_seq_item_write_vector(axi_seq_item_aw_vector_s aws);
	string str = "";
	$sformat(str, "%s awid 		= %0b   \n", str, aws.awid);
	$sformat(str, "%s awaddr 	= 0x%0x \n", str, aws.awaddr);
	$sformat(str, "%s awvalid 	= %0b \n",   str, aws.awvalid);
	$sformat(str, "%s awready 	= %0b \n",   str, aws.awready);
	$sformat(str, "%s awlen 	= %0b \n",   str, aws.awlen);
	$sformat(str, "%s awlock 	= %0b \n",   str, aws.awlock);
	$sformat(str, "%s awcache 	= %0b \n",   str, aws.awcache);
	$sformat(str, "%s awprot 	= %0b \n",   str, aws.awprot);
	$sformat(str, "%s awqos 	= %0b \n",   str, aws.awqos);
	return str;
endfunction


task axi_slave_driver::write_address();
	axi_seq_item_aw_vector_s s;
	vif.wait_for_not_in_reset();

	forever begin
//      vif.wait_for_clks(.cnt(1));
		@(posedge axi_vif.clk);
		if(axi_vif.s_drv_cb.iawvalid && axi_vif.iawready)begin
			assert(axi_vif.s_drv_cb.iawvalid );
			assert(axi_vif.iawready);
//          s.awid     = vif.get_awid();
//          s.awaddr   = vif.get_awaddr();
//          s.awsize = vif.get_awsize();
//          s.awburst = vif.get_awburst();
//          s.awlen  = vif.get_awlen();

			vif.read_aw(s);
			`uvm_info("SLAVE", $sformatf("\n WTRANS %s", print_axi_seq_item_write_vector(s)), UVM_LOW);
			`uvm_info("SLAVE", $sformatf("\n WTRANS %0b", axi_vif.s_drv_cb.iawvalid), UVM_LOW);
			writedata_mbx.put(item);
		end
	// should push here to support outstanding
	end
endtask

task axi_slave_driver::write_data();
	axi_seq_item item = null;
	writedata_mbx.get(item);
	axi_vif.s_drv_cb.iawready <= 1'b0;
	
endtask


task axi_slave_driver::read_address();

	axi_seq_item slv_rtrans;
	vif.set_arvalid(1'b0);

	vif.wait_for_not_in_reset();

	forever begin
		vif.wait_for_clks(.cnt(1));
		vif.wait_for_arvalid();
		slv_rtrans.id     = vif.get_arid();
		slv_rtrans.addr   = vif.get_araddr();
		slv_rtrans.burst_size = vif.get_arsize();
		slv_rtrans.burst_type = vif.get_arburst();
		slv_rtrans.axlen  = vif.get_arlen();
		slv_rtrans.print();
	// should push here to support outstanding
	end

endtask

function void axi_slave_driver::read_aw (axi_seq_item_aw_vector_s s);
	s.awvalid = axi_vif.s_drv_cb.iawvalid;
	s.awready = axi_vif.s_drv_cb.iawready;
	s.awid    = axi_vif.s_drv_cb.iawid;
	s.awaddr  = axi_vif.s_drv_cb.iawaddr;
	s.awlen   = axi_vif.s_drv_cb.iawlen;
	s.awsize  = axi_vif.s_drv_cb.iawsize;
	s.awburst = axi_vif.s_drv_cb.iawburst;
	s.awlock  = axi_vif.s_drv_cb.iawlock;
	s.awcache = axi_vif.s_drv_cb.iawcache;
	s.awprot  = axi_vif.s_drv_cb.iawprot;
	s.awqos   = axi_vif.s_drv_cb.iawqos;
endfunction