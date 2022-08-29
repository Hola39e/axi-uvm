////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2017, Matt Dew @ Dew Technologies, LLC
//
// This program is free software (logic verification): you can redistribute it
// and/or modify it under the terms of the GNU Lesser General Public License (LGPL)
// as published by the Free Software Foundation, either version 3 of the License,
// or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License
// for more details.
//
// License: LGPL, v3, as defined and found on www.gnu.org,
//      http://www.gnu.org/licenses/lgpl.html
//
//
// Author's intent:  If you use this AXI verification code and find or fix bugs
//                   or make improvements, then share those fixes or improvements.
//                   If you use this in a bigger project, I don't care about,
//                   or want, any changes or code outside this block.
//                   Example: If you use this in an SoC simulation/testbench
//                            I don't want, or care about, your SoC or other blocks.
//                            I just care about the enhancements to these AXI files.
//                   That's why I have choosen the LGPL instead of the GPL.
////////////////////////////////////////////////////////////////////////////////
/*! \class axi_base_test
 * \brief base test.  AXI tests are to be extended from this test.
 *
 * This test creates the driver sequence and the responder sequence.
 * Tests that extend this, can type_override to change the sequence.
 * // \todo: what if want to restart a seq?
 */
import params_pkg::*;
class axi_base_test extends uvm_test;


	parameter C_AXI_ID_WIDTH   = params_pkg::AXI_ID_WIDTH;
	parameter C_AXI_ADDR_WIDTH = params_pkg::AXI_ADDR_WIDTH;
	parameter C_AXI_DATA_WIDTH = params_pkg::AXI_DATA_WIDTH;
	parameter C_AXI_LEN_WIDTH  = params_pkg::AXI_LEN_WIDTH;
	`uvm_component_utils(axi_base_test)

	axi_env m_env;
	axi_seq m_seq;
	axi_responder_seq  m_resp_seq;



	//memory m_memory;

	function new (string name="axi_base_test", uvm_component parent=null);
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);

		int transactions;

		super.build_phase(phase);

		m_env = axi_env::type_id::create("m_env", this);

		m_seq = axi_seq::type_id::create("m_seq");

		if ($value$plusargs("transactions=%d", transactions)) begin
			`uvm_info("plusargs", $sformatf("TRANSACTIONS: %0d", transactions), UVM_INFO)
			m_seq.set_transaction_count(transactions);
		end


		m_resp_seq = axi_responder_seq::type_id::create("m_resp_seq");

//      if(!uvm_config_db #(int)::get(this, "", "AXI_ADDR_WIDTH", C_AXI_ADDR_WIDTH))
//          `uvm_fatal(get_name(), "config cannot be found in ConfigDB!")
//
//      uvm_config_db #(int)::get(this, "", "AXI_ADDR_WIDTH", C_AXI_ADDR_WIDTH);
//      uvm_config_db #(int)::get(this, "", "AXI_DATA_WIDTH", C_AXI_DATA_WIDTH);
//      uvm_config_db #(int)::get(this, "", "AXI_ID_WIDTH",   C_AXI_ID_WIDTH);
//      uvm_config_db #(int)::get(this, "", "AXI_LEN_WIDTH",  C_AXI_LEN_WIDTH);
		$display("parameter AXI_ID_WIDTH = %d", C_AXI_ID_WIDTH);


	endfunction : build_phase

	task run_phase(uvm_phase phase);
		phase.raise_objection(this);

		fork
			m_resp_seq.start(m_env.m_responder_seqr);
		join_none

		m_seq.start(m_env.m_driver_seqr);

		phase.drop_objection(this);
	endtask : run_phase

	function void end_of_elaboration_phase(uvm_phase phase);
		super.end_of_elaboration_phase(phase);
		uvm_top.print_topology();
	endfunction: end_of_elaboration_phase


endclass : axi_base_test
