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

	extern task 		wait_for_write_data();
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

// ----------------------- task for write adress --------------------------
//Summary:  wait wirte address to get write transaction, and put 
// 			item into write data mailbox.

// -------------------------------------------------------------------------
task axi_slave_driver::write_address();
	axi_seq_item_aw_vector_s s;
	vif.wait_for_not_in_reset();
	axi_seq_item_aw_vector_s ws_q[$];
	forever begin

		@(posedge axi_vif.clk);
		if(axi_vif.s_drv_cb.iawvalid && axi_vif.iawready)begin
			assert(axi_vif.s_drv_cb.iawvalid );
			assert(axi_vif.iawready);

			vif.read_aw(s);
			`uvm_info("SLAVE", $sformatf("\n WTRANS %s", print_axi_seq_item_write_vector(s)), UVM_LOW);
			`uvm_info("SLAVE", $sformatf("\n WTRANS %0b", axi_vif.s_drv_cb.iawvalid), UVM_LOW);
			writedata_mbx.put(item);
		end
	// should push here to support outstanding
	end
endtask

// ----------------------- task for write data --------------------------
//Summary:  read bus and get write data, write into memory

// -------------------------------------------------------------------------

task axi_slave_driver::write_data();
	


	axi_seq_item_w_vector_s s;
	axi_seq_item_w_vector_s ws_q[$];
	axi_seq_item item = null;
	axi_seq_item cloned_item = null;
	bit [ADDR_WIDTH-1:0] read_addr;
	int beat_cntr;
	int beat_cntr_max = 0;
	int Lower_Byte_Lane, Upper_Byte_Lane;
	int offset;
	string msg_s;

	// axi_vif.s_drv_cb.iawready <= 1'b0;

	forever begin
		`uvm_info(this.get_type_name(), 
			"======> wait for write data",
			UVM_LOW)
		wait_for_write_data(s);
		`uvm_info(this.get_type_name,
			"======> wait for write data done",
			UVM_LOW)

		// push item into queue
		ws_q.push_back(s);

		if(item == null)begin
			if(writedata_mbx.num() > 0)begin
				writedata_mbx.get(item);
				$cast(cloned_item, item.clone());
				cloned_item.set_id_info(item);

				cloned_item.cmd = e_WRITE_DATA;
				cloned_item.data = new[cloned_item.len];

				beat_cntr = 0;
				beat_cntr_max = axi_pkg::calculate_axlen(
					cloned_item.addr,
					cloned_item.burst_size,
					cloned_item.len
					) + 1;
			end
		end

		if(item != null)begin
			while (item != null && ws_q.size() > 0)begin
				s = ws_q.push_front();
                axi_pkg::get_beat_N_byte_lanes(.addr         (cloned_item.addr),
                .burst_size   (cloned_item.burst_size),
                .burst_length (cloned_item.len),
                .burst_type   (cloned_item.burst_type),
                .beat_cnt        (beat_cntr),
                .data_bus_bytes  (vif.get_data_bus_width()/8),
                .Lower_Byte_Lane  (Lower_Byte_Lane),
                .Upper_Byte_Lane (Upper_Byte_Lane),
                .offset          (offset));

                msg_s="";
				$sformat(msg_s, "%s beat_cntr:%0d",       msg_s, beat_cntr);
				$sformat(msg_s, "%s beat_cntr_max:%0d",   msg_s, beat_cntr_max);
				$sformat(msg_s, "%s data_bus_bytes:%0d",  msg_s, vif.get_data_bus_width()/8);
				$sformat(msg_s, "%s Lower_Byte_Lane:%0d", msg_s, Lower_Byte_Lane);
				$sformat(msg_s, "%s Upper_Byte_Lane:%0d", msg_s, Upper_Byte_Lane);
				$sformat(msg_s, "%s offset:%0d",          msg_s, offset);

                msg_s="data: 0x";
				for (int z=(vif.get_data_bus_width()/8)-1;z>=0;z--) begin
					$sformat(msg_s, "%s%02x", msg_s, s.rdata[z*8+:8]);
				end

                for (int z=Lower_Byte_Lane;z<=Upper_Byte_Lane;z++) begin
					if (offset < cloned_item.len) begin
						cloned_item.data[offset++] = s.rdata[z*8+:8];
					end
				end

                beat_cntr++;

                if(beat_cnt >= beat_cntr_max)begin
                    //seq_item_port.put(cloned_item)
                    cloned_item.print();
                    item = null;
                    beat_cntr = 0;
                end
			end

		end
	end
	
endtask

task axi_slave_driver::wait_for_write_data(output axi_seq_item_w_vector_s s);

	forever begin
		@(posedge axi_vif.s_drv_cb)begin
			if(axi_vif.s_drv_cb.iwvalid == 1'b1 && axi_vif.iwready == 1'b1)begin
			s.wvalid = axi_vif.s_drv_cb.wvalid;
			s.wdata = axi_vif.s_drv_cb.wdata;
			s.wstrb = axi_vif.s_drv_cb.wstrb;
			s.wlast = axi_vif.s_drv_cb.wlast;
			return;
			end
		end
	end
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