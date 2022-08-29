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
/*! \class axi_env
 *  \brief Creates two active AXI agents, one master and one slave/responder, plus a memory
 *
 */
class axi_env extends uvm_env;
	`uvm_component_utils(axi_env)


	axi_agent_config       m_agent_config;
	axi_sequencer          m_driver_seqr;
	axi_sequencer          m_responder_seqr;

	axi_agent        m_axidriver_agent;
	axi_agent        m_axiresponder_agent;
	axi_agent        m_axislave_agent;

	virtual axi_if #(
		.C_AXI_ADDR_WIDTH(params_pkg::AXI_ADDR_WIDTH),
		.C_AXI_DATA_WIDTH(params_pkg::AXI_DATA_WIDTH),
		.C_AXI_ID_WIDTH(params_pkg::AXI_ID_WIDTH),
		.C_AXI_LEN_WIDTH(params_pkg::AXI_LEN_WIDTH)) axi_vif ;

	memory           m_memory;

	extern function new (string name="axi_env", uvm_component parent=null);

	extern function void build_phase              (uvm_phase phase);
	extern function void connect_phase            (uvm_phase phase);

endclass : axi_env

/*! \brief Constructor
 *
 * Doesn't actually do anything except call parent constructor */
function axi_env::new (string name="axi_env", uvm_component parent=null);
	super.new(name, parent);
endfunction : new

/*! \brief Creates the two AXI agents and the memory */
function void axi_env::build_phase (uvm_phase phase);
	super.build_phase(phase);


	m_axidriver_agent    = axi_agent::type_id::create("m_axidriver_agent", this);

	if (uvm_config_db #(axi_agent_config)::get(this, "", "m_axidriver_agent.m_config", m_axidriver_agent.m_config)) begin
		`uvm_info(this.get_type_name,
			"Found m_axidriver_agent.m_config in config db.",
			UVM_INFO)
	end else begin
		`uvm_info(this.get_type_name,
			"Unable to fetch m_axidriver_agent.m_config from config db. Using defaults",
			UVM_INFO)

		m_axidriver_agent.m_config = axi_agent_config::type_id::create("m_axidriver_agent.m_config", this);


		assert(m_axidriver_agent.m_config.randomize());

		m_axidriver_agent.m_config.m_active            = UVM_ACTIVE;
		m_axidriver_agent.m_config.drv_type            = e_DRIVER;
	end





	m_axiresponder_agent = axi_agent::type_id::create("m_axiresponder_agent", this);


	if (uvm_config_db #(axi_agent_config)::get(this, "", "m_axiresponder_agent.m_config", m_axiresponder_agent.m_config)) begin
		`uvm_info(this.get_type_name,
			"Found m_axiresponder_agent.m_config in config db.",
			UVM_INFO)
	end else begin
		`uvm_info(this.get_type_name,
			"Unable to fetch m_axiresponder_agent.m_config from config db. Using defaults",
			UVM_INFO)

		m_axiresponder_agent.m_config = axi_agent_config::type_id::create("m_axiresponder_agent.m_config", this);


		assert(m_axiresponder_agent.m_config.randomize());

		m_axiresponder_agent.m_config.m_active            = UVM_ACTIVE;
		m_axiresponder_agent.m_config.drv_type            = e_RESPONDER;
	end





	m_axislave_agent = axi_agent::type_id::create("m_axislave_agent", this);


	if (uvm_config_db #(axi_agent_config)::get(this, "", "m_axislave_agent.m_config", m_axislave_agent.m_config)) begin
		`uvm_info(this.get_type_name,
			"Found m_axislave_agent.m_config in config db.",
			UVM_INFO)
	end else begin
		`uvm_info(this.get_type_name,
			"Unable to fetch m_axislave_agent.m_config from config db. Using defaults",
			UVM_INFO)

		m_axislave_agent.m_config = axi_agent_config::type_id::create("m_axislave_agent.m_config", this);


		assert(m_axislave_agent.m_config.randomize());

		m_axislave_agent.m_config.m_active            = UVM_ACTIVE;
		m_axislave_agent.m_config.drv_type            = e_SLAVE;
	end


	m_memory = memory::type_id::create("m_memory", this);
	uvm_config_db #(memory)::set(null, "*", "m_memory", m_memory);
	m_axiresponder_agent.m_memory = m_memory;
	m_axidriver_agent.m_memory    = m_memory;
	uvm_config_db #(virtual axi_if #(
			.C_AXI_ADDR_WIDTH(params_pkg::AXI_ADDR_WIDTH),
			.C_AXI_DATA_WIDTH(params_pkg::AXI_DATA_WIDTH),
			.C_AXI_ID_WIDTH(params_pkg::AXI_ID_WIDTH),
			.C_AXI_LEN_WIDTH(params_pkg::AXI_LEN_WIDTH)))
	::set(this, "", "vif", axi_vif);
//uvm_config_db #(virtual axi_if #(1, 2, 3, 4))
//  ::get(this, "", "vif", axi_vif);

endfunction : build_phase
/*! \brief Sets sequencer pointers/handles
 *
 */
function void axi_env::connect_phase (uvm_phase phase);
	super.connect_phase(phase);

	m_driver_seqr    = m_axidriver_agent.m_seqr;
	m_responder_seqr = m_axiresponder_agent.m_seqr;

endfunction : connect_phase
