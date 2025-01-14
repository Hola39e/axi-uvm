////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2017, Matt Dew
//
// This program is free software (firmware): you can redistribute it and/or
// modify it under the terms of  the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
// License:	GPL, v3, as defined and found on www.gnu.org,
//		http://www.gnu.org/licenses/gpl.html
//
//
////////////////////////////////////////////////////////////////////////////////
`ifndef _PARAMS_PKG
`define _PARAMS_PKG
/*! \package params_pkg
 *  \brief Parameters used in the design and testbench are kept here.
 *
 *  The top level module, tb, in this case, imports this package and references it
 *  to set the design and tb parameters.
 *  For example, in tb.sv:
 *    import params_pkg::*;
 *    parameter C_AXI_ID_WIDTH   = params_pkg::AXI_ID_WIDTH;
 *    @see tb.sv
 */
package params_pkg;

// The obvious question is what to do with multiple instantiations of
// different sizes?
  parameter AXI_ID_WIDTH   = 5;
  parameter AXI_ADDR_WIDTH = 32;
  parameter AXI_DATA_WIDTH = 8;
  parameter AXI_LEN_WIDTH  = 8;


endpackage : params_pkg

`endif