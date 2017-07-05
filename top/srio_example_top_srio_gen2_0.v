//
// (c) Copyright 2010 - 2014 Xilinx, Inc. All rights reserved.
//
//                                                                 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// 	PART OF THIS FILE AT ALL TIMES.                                
`timescale 1ps/1ps
(* DowngradeIPIdentifiedWarnings = "yes" *)

`define SIM
module srio_example_top_srio_gen2_0 #(
	parameter MIRROR = 0,
	parameter SIM_1 = 1,
    parameter SIM_VERBOSE               = 0, // If set, generates unsynthesizable reporting
    parameter VALIDATION_FEATURES       = 0, // If set, uses internal instruction sequences for hw and sim test
    parameter QUICK_STARTUP             = 0, // If set, quick-launch configuration access is contained here
    parameter STATISTICS_GATHERING      = 0, // If set, I/O can be rerouted to the maint port [0,1]
    parameter C_LINK_WIDTH              = 1
    )
   //  port declarations ----------------
   (
    // Clocks and Resets
	
    input            sys_clkp,              // MMCM reference clock
    input            sys_clkn,              // MMCM reference clock

    input            sys_rst_n,               // Global reset signal

    // high-speed IO
    input           srio_rxn0,              // Serial Receive Data
    input           srio_rxp0,              // Serial Receive Data



    output          srio_txn0,              // Serial Transmit Data
    output          srio_txp0,              // Serial Transmit Data

	output 			si53301_OEA,
    output 			si53301_OEB,
    output 			si53301_CLKSEL,

   // input           sim_train_en,           // Set this only when simulating to reduce the size of counters
   `ifdef SIM
	output [3:0] led0
	`else
    output  [1:0]   led0
	`endif
	

   );
   //  ----------------------------------


  // wire declarations ----------------
//
// -----------------------------------------------------------------------------
// Note : Below portion of the wire declaration should be commented when
//        used in non-shared mode AND the SRIO core 2nd instance is used to share
//        common logic like clk, rst and GT Common with another instance of SRIO
//        with Shared Logic (in DUT) option if the simulator throws errors.
// -----------------------------------------------------------------------------
    wire            log_clk;
    wire            phy_clk;
    wire            gt_pcs_clk;
    wire            log_rst;
    wire            phy_rst;
    wire            clk_lock;               // asserts from the MMCM
//

    // signals into the DUT


    wire            ireq_tvalid;
    wire            ireq_tready;
    wire            ireq_tlast;
    wire   [63:0]   ireq_tdata;
    wire   [7:0]    ireq_tkeep;
    wire   [31:0]   ireq_tuser;

    wire            iresp_tvalid;
    wire            iresp_tready;
    wire            iresp_tlast;
    wire    [63:0]  iresp_tdata;
    wire    [7:0]   iresp_tkeep;
    wire    [31:0]  iresp_tuser;

    wire            treq_tvalid;
    wire            treq_tready;
    wire            treq_tlast;
    wire    [63:0]  treq_tdata;
    wire    [7:0]   treq_tkeep;
    wire    [31:0]  treq_tuser;

    wire            tresp_tvalid;
    wire            tresp_tready;
    wire            tresp_tlast;
    wire   [63:0]   tresp_tdata;
    wire   [7:0]    tresp_tkeep;
    wire   [31:0]   tresp_tuser;

    wire            maintr_rst = 1'b0;

    wire            maintr_awvalid;
    wire            maintr_awready;
    wire   [31:0]   maintr_awaddr;
    wire            maintr_wvalid;
    wire            maintr_wready;
    wire   [31:0]   maintr_wdata;
    wire            maintr_bvalid;
    wire            maintr_bready;
    wire   [1:0]    maintr_bresp;

    wire            maintr_arvalid;
    wire            maintr_arready;
    wire   [31:0]   maintr_araddr;
    wire            maintr_rvalid;
    wire            maintr_rready;
    wire   [31:0]   maintr_rdata;
    wire   [1:0]    maintr_rresp;

    // signals from Validation modules
    wire            val_ireq_tvalid;
    wire            val_ireq_tready;
    wire            val_ireq_tlast;
    wire   [63:0]   val_ireq_tdata;
    wire   [7:0]    val_ireq_tkeep;
    wire   [31:0]   val_ireq_tuser;

    wire            val_iresp_tvalid;
    wire            val_iresp_tready;
    wire            val_iresp_tlast;
    wire    [63:0]  val_iresp_tdata;
    wire    [7:0]   val_iresp_tkeep;
    wire    [31:0]  val_iresp_tuser;

    wire            val_treq_tvalid;
    wire            val_treq_tready;
    wire            val_treq_tlast;
    wire    [63:0]  val_treq_tdata;
    wire    [7:0]   val_treq_tkeep;
    wire    [31:0]  val_treq_tuser;

    wire            val_tresp_tvalid;
    wire            val_tresp_tready;
    wire            val_tresp_tlast;
    wire   [63:0]   val_tresp_tdata;
    wire   [7:0]    val_tresp_tkeep;
    wire   [31:0]   val_tresp_tuser;

    wire            val_maintr_awvalid;
    wire            val_maintr_awready;
    wire   [31:0]   val_maintr_awaddr;
    wire            val_maintr_wvalid;
    wire            val_maintr_wready;
    wire   [31:0]   val_maintr_wdata;
    wire            val_maintr_bvalid;
    wire            val_maintr_bready;
    wire   [1:0]    val_maintr_bresp;

    wire            val_maintr_arvalid;
    wire            val_maintr_arready;
    wire   [31:0]   val_maintr_araddr;
    wire            val_maintr_rvalid;
    wire            val_maintr_rready;
    wire   [31:0]   val_maintr_rdata;
    wire   [1:0]    val_maintr_rresp;


//--
//----------------------------------------------------------------------------//
//wire [C_LINK_WIDTH-1:0]         gt_drpdo_out            ;
//wire [C_LINK_WIDTH-1:0]         gt_drprdy_out           ;
wire [C_LINK_WIDTH*9-1:0]         gt_drpaddr_in           ;
wire [C_LINK_WIDTH*16-1:0]        gt_drpdi_in             ;
wire [C_LINK_WIDTH-1:0]           gt_drpen_in             ;
wire [C_LINK_WIDTH-1:0]           gt_drpwe_in             ;
wire [C_LINK_WIDTH-1:0]           gt_txpmareset_in        ;
wire [C_LINK_WIDTH-1:0]           gt_rxpmareset_in        ;
wire [C_LINK_WIDTH-1:0]           gt_txpcsreset_in        ;
wire [C_LINK_WIDTH-1:0]           gt_rxpcsreset_in        ;
wire [C_LINK_WIDTH-1:0]           gt_eyescanreset_in      ;
wire [C_LINK_WIDTH-1:0]           gt_eyescantrigger_in    ;
//wire [C_LINK_WIDTH-1:0]         gt_eyescandataerror_out ;
wire[C_LINK_WIDTH*3-1:0]          gt_loopback_in          ;
wire                            gt_rxpolarity_in        ;
wire                            gt_txpolarity_in        ;
wire                            gt_rxlpmen_in           ;
wire [C_LINK_WIDTH*5-1:0]         gt_txprecursor_in       ;
wire [C_LINK_WIDTH*5-1:0]         gt_txpostcursor_in      ;
wire [3:0]                gt0_txdiffctrl_in;
wire                      gt_txprbsforceerr_in ;
wire [C_LINK_WIDTH*3-1:0]   gt_txprbssel_in      ;
wire [C_LINK_WIDTH*3-1:0]   gt_rxprbssel_in      ;
//wire                      gt_rxprbserr_out     ;
wire                      gt_rxprbscntreset_in ;
wire                      gt_rxcdrhold_in      ;
wire                      gt_rxdfelpmreset_in  ;
//wire                      gt_rxcommadet_out    ;
//wire [C_LINK_WIDTH*8-1:0]   gt_dmonitorout_out   ;
//wire [C_LINK_WIDTH-1:0]     gt_rxresetdone_out   ;
//wire [C_LINK_WIDTH-1:0]     gt_txresetdone_out   ;
//wire [C_LINK_WIDTH*3-1:0]   gt_rxbufstatus_out   ;
//wire [C_LINK_WIDTH*3-1:0]   gt_txbufstatus_out   ;


//--

    // other core output signals that may be used by the user
    wire     [23:0] port_timeout;           // Timeout value user can use to detect a lost packet
    wire            phy_rcvd_mce;           // MCE control symbol received
    (* mark_debug = "true" *)
    wire            phy_rcvd_link_reset;    // Received 4 consecutive reset symbols
    wire            port_error;             // In Port Error State
    //(* mark_debug = "true" *)// this constraint is commented as it is failing due to new MLO flow
    wire            mode_1x;                // Link is trained down to 1x mode
    wire            srio_host;              // Endpoint is the system host
    wire    [223:0] phy_debug;              // Useful debug signals
    
    wire            gtrx_disperr_or;        // GT disparity error (reduce ORed)
    
    wire            gtrx_notintable_or;     // GT not in table error (reduce ORed)
    wire     [15:0] deviceid;               // Device ID
    wire            port_decode_error;      // No valid output port for the RX transaction
    (* mark_debug = "true" *)
    wire            idle_selected;          // The IDLE sequence has been selected
    (* mark_debug = "true" *)
    wire            idle2_selected;         // The PHY is operating in IDLE2 mode
    wire            autocheck_error;        // when set, packet didn't match expected
    (* mark_debug = "true" *)
    wire            port_initialized;       // Port is Initialized
    (* mark_debug = "true" *)
    wire            link_initialized;       // Link is Initialized
    wire            exercise_done;          // sets when the generator(s) has completed

    // other core output signals that may be used by the user
    wire            phy_mce = 1'b0;         // Send MCE control symbol
    wire            phy_link_reset = 1'b0;  // Send link reset control symbols
    wire            force_reinit = 1'b0;    // Force reinitialization


    // convert to ports when not using the pattern generator


    wire            axis_ireq_tvalid;
    wire            axis_ireq_tready;
    wire            axis_ireq_tlast;
    wire   [63:0]   axis_ireq_tdata;
    wire   [7:0]    axis_ireq_tkeep;
    wire   [31:0]   axis_ireq_tuser;

    wire            axis_iresp_tvalid;
    wire            axis_iresp_tready;
    wire            axis_iresp_tlast;
    wire    [63:0]  axis_iresp_tdata;
    wire    [7:0]   axis_iresp_tkeep;
    wire    [31:0]  axis_iresp_tuser;

    wire            axis_treq_tvalid;
    wire            axis_treq_tready = 1'b1;
    wire            axis_treq_tlast;
    wire    [63:0]  axis_treq_tdata;
    wire    [7:0]   axis_treq_tkeep;
    wire    [31:0]  axis_treq_tuser;

    wire            axis_tresp_tvalid = 1'b0;
    wire            axis_tresp_tready;
    wire            axis_tresp_tlast = 1'b0;
    wire   [63:0]   axis_tresp_tdata = 'h0;
    wire   [7:0]    axis_tresp_tkeep = 'h0;
    wire   [31:0]   axis_tresp_tuser ='h0;

    wire            axis_maintr_rst = 1'b0;
    wire            axis_maintr_awvalid = 1'b0;
    wire            axis_maintr_awready;
    wire   [31:0]   axis_maintr_awaddr = 1'b0;
    wire            axis_maintr_wvalid = 1'b0;
    wire            axis_maintr_wready;
    wire   [31:0]   axis_maintr_wdata = 1'b0;
    wire   [3:0]    axis_maintr_wstrb = 1'b0;
    wire            axis_maintr_bvalid;
    wire            axis_maintr_bready = 1'b0;
    wire   [1:0]    axis_maintr_bresp;

    wire            axis_maintr_arvalid = 1'b0;
    wire            axis_maintr_arready;
    wire   [31:0]   axis_maintr_araddr = 1'b0;
    wire            axis_maintr_rvalid;
    wire            axis_maintr_rready = 1'b0;
    wire   [31:0]   axis_maintr_rdata;
    wire   [1:0]    axis_maintr_rresp;

    wire            ireq_autocheck_error;
    wire            ireq_request_done;
    wire            maint_autocheck_error;
    wire            maint_done;

    // Vivado debug outputs for control of
    (* mark_debug = "true" *)
    wire            peek_poke_go;
    (* mark_debug = "true" *)
    wire [23:0]     user_addr;
    (* mark_debug = "true" *)
    wire  [3:0]     user_ftype;
    (* mark_debug = "true" *)
    wire  [3:0]     user_ttype;
    (* mark_debug = "true" *)
    wire  [7:0]     user_size;
    (* mark_debug = "true" *)
    wire [63:0]     user_data;
    (* mark_debug = "true" *)
    wire  [3:0]     user_hop;
    (* mark_debug = "true" *)
    wire [15:0]     dest_id;
    (* mark_debug = "true" *)
    wire [15:0]     source_id;
    (* mark_debug = "true" *)
    wire            id_override;
    (* mark_debug = "true" *)
    wire            register_reset;
    (* mark_debug = "true" *)
    wire            reset_all_registers;
    (* mark_debug = "true" *)
    wire  [3:0]     stats_address;
    //(* mark_debug = "true" *)
    // wire            send_pna;
    // (* mark_debug = "true" *)
    // wire  [2:0]     sent_pna_cause_lsb;
    // (* mark_debug = "true" *)
    // wire            in_recoverable_detect;
    // (* mark_debug = "true" *)
    // wire            in_retry_detect;
    // (* mark_debug = "true" *)
    // wire            out_recoverable_detect;
    // (* mark_debug = "true" *)
    // wire            out_fatal_detect;
    
    wire       core_sent_pna;
    
    wire       core_received_pna;
    
    wire       core_sent_pr;
    
    wire       core_received_pr;

    // Debug signals
    wire            go_req   = peek_poke_go && user_ftype != 4'h8;
    wire            go_maint = peek_poke_go && user_ftype == 4'h8;
    wire            maint_inst = user_ttype == 4'h0;
    reg   [63:0]    captured_data;
    (* mark_debug = "true" *)
    wire            continuous_go;
    reg             continuous_go_q;
    reg             ireq_autocheck_error_q;
    reg             ireq_request_done_q;
    reg             reset_request_gen;
    (* mark_debug = "true" *)
    reg             continuous_in_process;
    reg             reset_continuous_set;
    (* mark_debug = "true" *)
    reg             stop_continuous_test;
    reg   [15:0]    reset_continuous_srl;
    wire  [31:0]    stats_data;
  // }}} End wire declarations ------------

 //Added by Chunjie
  wire sys_rst;
  
   wire [7:0] src_id = 8'h01;
  wire [7:0] des_id = 8'hf0;

  wire rapidIO_ready;
  wire nwr_ready;
  wire nwr_busy;
  wire nwr_done;
  reg nwr_req_p;
  reg nwr_ready_r0, nwr_ready_r1;
  
  wire user_ready;
  wire [33:0] user_taddr;
  wire user_tready	;
  wire [11:0] user_tsize;
  
  wire [63:0] user_tdata;
  wire user_tvalid;
  wire [7:0] user_tkeep;
  wire user_tlast;
  
  reg [12:0] initialized_cnt;
  reg  initialized_delay_r;
  wire initialized_delay;
 /* wire ireq_tvalid;
  wire ireq_tready;
  wire ireq_tlast;
  wire [63:0] ireq_tdata;
  wire [7:0] ireq_tkeep;
  wire [31:0] ireq_tuser;
  
  wire iresp_tvalid;
  wire iresp_tready;
  wire iresp_tlast;
  wire [63:0] iresp_tdata;
  wire [7:0] iresp_tkeep;
  wire [31:0] iresp_tuser;
  */
  // signals for target endpoint

  wire [1:0] ed_ready = 2'd1;
 /* wire treq_tvalid;
  wire treq_tready;
  wire treq_tlast;
  wire [63:0] treq_tdata;
  wire [7:0] treq_tkeep;
  wire [31:0] treq_tuser;

  wire tresp_tready;
  wire tresp_tvalid;
  wire tresp_tlast;
  wire [63:0] tresp_tdata;
  wire [7:0] tresp_tkeep;
  wire [31:0] tresp_tuser;
  */
  // enable pulse 
  reg db_self_check_en, db_self_check_r;
  wire [0:0] db_self_check;
  reg nwr_req_en, nwr_req_en_r;
  wire [0:0] nwr_req;
  
  // Debug signals
  wire [0:0] mode_1x_vio;
  wire [0:0] port_initialized_vio;
  wire [0:0] link_initialized_vio;
  wire [0:0] clk_lock_vio;
   
  wire [0:0] nwr_ready_ila;
  wire [0:0] nwr_busy_ila;
  
  wire [0:0] nwr_done_ila;
  wire [0:0] link_initialized_ila;
  wire [0:0] user_tready_ila;
  wire [0:0] ireq_tvalid_ila;
  wire [0:0] ireq_tlast_ila;
  
  wire sim_train_en = 1'b0;
  assign sys_rst = ~sys_rst_n;
  `ifdef SIM
	assign led0[0] = !mode_1x;
    assign led0[1] = port_initialized;
    assign led0[2] = link_initialized;
	assign led0[3] = clk_lock;
	`else
	assign led0[0] = !mode_1x;
    assign led0[1] = ~link_initialized;
	`endif
  // {{{ Drive LEDs to Development Board -------
   // assign led0[0] = 1'b1;
   // assign led0[1] = 1'b1;
   // assign led0[0] = !mode_1x;
   // assign led0[1] = port_initialized;
   // assign led0[1] = ~link_initialized;
   // assign led0[3] = clk_lock;
  //  assign led0[6] = sim_train_en ? autocheck_error : 1'b0;
  //  assign led0[7] = sim_train_en ? exercise_done : 1'b0;
  // }}} End LEDs to Development Board ---------

    // assign send_pna               = phy_debug[0];
    // assign sent_pna_cause_lsb     = phy_debug[34:32];
    // assign in_recoverable_detect  = phy_debug[40];
    // assign in_retry_detect        = phy_debug[39];
    // assign out_recoverable_detect = phy_debug[38];
    // assign out_fatal_detect       = phy_debug[37];
    // assign send_pna               = phy_debug[0];
    assign core_sent_pna     = phy_debug[160];
    assign core_received_pna = phy_debug[161];
    assign core_sent_pr      = phy_debug[162];
    assign core_received_pr  = phy_debug[163];

      assign continuous_go        = 1'b0;
      assign peek_poke_go         = 1'b0;
      assign user_addr            = 24'b0;
      assign user_ftype           = 4'b0;
      assign user_ttype           = 4'b0;
      assign user_size            = 8'b0;
      assign user_data            = 64'b0;
      assign user_hop             = 4'b0;
      assign dest_id              = 16'b0;
      assign source_id            = 16'b0;
      assign id_override          = 1'b0;
      assign register_reset       = 1'b0;
      assign reset_all_registers  = 1'b0;
      assign stats_address        = 4'b0;
	  
   	// control Si53301
   assign si53301_OEA = 1'bz;
   assign si53301_OEB = 1'bz;
   assign si53301_CLKSEL = 1'b0;
   
  assign mode_1x_vio[0] = mode_1x;
  assign port_initialized_vio[0] = port_initialized;
  assign link_initialized_vio[0] = link_initialized;
  assign clk_lock_vio[0] = clk_lock;

  assign nwr_ready_ila[0] = nwr_ready;
  assign nwr_busy_ila[0] = nwr_busy;
  assign nwr_done_ila[0] = nwr_done;
  assign link_initialized_ila[0] = link_initialized;
  assign user_tready_ila[0] = user_tready;
  assign ireq_tvalid_ila[0] = ireq_tvalid;
  assign ireq_tlast_ila[0] = ireq_tlast;
   
   // Generate doorbell self-check enable and nwr request enable by VIO
   `ifndef SIM
   	always @(posedge log_clk) begin
		if (log_rst) begin
			db_self_check_en <= 1'b0;
			db_self_check_r <= 1'b0;
			nwr_req_en <= 1'b0;
			nwr_req_en_r <= 1'b0;
		end
	else begin
		db_self_check_r <= db_self_check[0];
		db_self_check_en <= !db_self_check_r & db_self_check[0];
		nwr_req_en_r <= nwr_req[0];
		nwr_req_en <= !nwr_req_en_r & nwr_req[0] ;
		end
	end
	`endif
	
	// Used only in simulation to generate doorbell request
	`ifdef SIM
	always @(posedge log_clk) begin
		if (log_rst) begin
			initialized_cnt <= 'h0;
		end
		else if (link_initialized && ~initialized_delay) begin
			initialized_cnt <= initialized_cnt + 'h1;
		end
		else if (!link_initialized) begin
			initialized_cnt <= 'h0;
		end
	end
	
	assign initialized_delay = initialized_cnt[12];
	
	// Generate doorbell self-check enable pulse
	always @(posedge log_clk) begin
		if (log_rst) begin
			initialized_delay_r <= 1'b0;
		end
		else begin
			initialized_delay_r <= initialized_delay;
			db_self_check_en <= ~initialized_delay_r & initialized_delay;
		end
	end
	
	// Generate NWR enable pulse
	always @(posedge log_clk) begin
		if (log_rst) begin
			nwr_ready_r0 <= 1'b0;
			nwr_ready_r1 <= 1'b1;
		end
		else begin
			nwr_ready_r0 <= nwr_ready;
			nwr_ready_r1 <= nwr_ready_r0;
			nwr_req_en <= ~nwr_ready_r1 & nwr_ready_r0;
		end
	end
	
	`endif
	
	generate if (!VALIDATION_FEATURES && !MIRROR) begin: db_req_gen
	
	db_req db_req_i
		(
		.log_clk(log_clk),
		.log_rst(log_rst),
		
		.src_id(src_id),
		.des_id(des_id),
		
		.self_check_in(db_self_check_en),
		.nwr_req_in(nwr_req_en),
		.rapidIO_ready_o(rapidIO_ready),
		.link_initialized(link_initialized),
		
		.nwr_ready_o(nwr_ready),
		.nwr_busy_o(nwr_busy),
		.nwr_ack_done_o(nwr_done),
		
		.user_tready_o(user_tready),
		.user_addr(user_taddr),
		.user_tsize_in(user_tsize),
		
		.user_tdata_in(user_tdata),
		.user_tvalid_in(user_tvalid),
		.user_tkeep_in(user_tkeep),
		.user_tlast_in(user_tlast),
		
		.ireq_tvalid_o(ireq_tvalid),
		.ireq_tready_in(ireq_tready),
		.ireq_tlast_o(ireq_tlast),
		.ireq_tdata_o(ireq_tdata),
		.ireq_tkeep_o(ireq_tkeep),
		.ireq_tuser_o(ireq_tuser),
		
		.iresp_tvalid_in(iresp_tvalid),
		.iresp_tready_o(iresp_tready),
		.iresp_tlast_in(iresp_tlast),
		.iresp_tdata_in(iresp_tdata),
		.iresp_tkeep_in(iresp_tkeep),
		.iresp_tuser_in(iresp_tuser)
		);
	user_logic user_logic_i
	(
		.log_clk(log_clk),
		.log_rst(log_rst),
		
		.nwr_ready_in(nwr_ready),
		.nwr_busy_in(nwr_busy),
		.nwr_done_in(nwr_done),
		
		.user_tready_in(user_tready),
		.user_addr_o(user_taddr),
		.user_tsize_o(user_tsize),
		.user_tdata_o(user_tdata),
		.user_tvalid_o(user_tvalid),
		.user_tkeep_o(user_tkeep),
		.user_tlast_o(user_tlast)
		
	);
	end
	endgenerate
	
	generate if (!VALIDATION_FEATURES && MIRROR) begin: db_resp_gen
	
	// db_resp is used to simulate the bahavor of target, when synthesize, comment it.
    db_resp 
	#(.SIM(SIM_1))
	db_resp_i (
      .log_clk(log_clk),
      .log_rst(log_rst),
  
      .src_id(8'h01),
      .des_id(8'h01),
  
      .ed_ready_in(ed_ready),
  
      .treq_tvalid_in(treq_tvalid),
      .treq_tready_o(treq_tready),
      .treq_tlast_in(treq_tlast),
      .treq_tdata_in(treq_tdata),
      .treq_tkeep_in(treq_tkeep),
      .treq_tuser_in(treq_tuser),
  
      // response interface
      .tresp_tready_in(tresp_tready),
      .tresp_tvalid_o(tresp_tvalid),
      .tresp_tlast_o(tresp_tlast),
      .tresp_tdata_o(tresp_tdata),
      .tresp_tkeep_o(tresp_tkeep),    
      .tresp_tuser_o(tresp_tuser)
      );
	  
	`ifndef SIM
	vio_0 vio_i (
	.clk(log_clk),                // input wire clk
	.probe_in0(mode_1x_vio),    // input wire [0 : 0] probe_in0
	.probe_in1(port_initialized_vio),    // input wire [0 : 0] probe_in1
	.probe_in2(link_initialized_vio),    // input wire [0 : 0] probe_in2
	.probe_in3(clk_lock_vio),    // input wire [0 : 0] probe_in3
	.probe_in4(clk_lock_vio),    // input wire [0 : 0] probe_in4
	.probe_out0(db_self_check),  // output wire [0 : 0] probe_out0
	.probe_out1(nwr_req)  // output wire [0 : 0] probe_out1
);

	ila_0 ila_i (
		.clk(log_clk), // input wire clk
		.probe0(nwr_ready_ila), // input wire [0:0]  probe0  
		.probe1(nwr_busy_ila), // input wire [0:0]  probe1 
		.probe2(nwr_done_ila), // input wire [0:0]  probe2 
		.probe3(link_initialized_ila), // input wire [0:0]  probe3 
		.probe4(user_tready_ila), // input wire [0:0]  probe4 
		.probe5(ireq_tvalid_ila), // input wire [0:0]  probe5 
		.probe6(ireq_tlast_ila), // input wire [0:0]  probe6 
		.probe7(ireq_tuser), // input wire [31:0]  probe7 
		.probe8(ireq_tdata), // input wire [63:0]  probe8 
		.probe9(ireq_tkeep) // input wire [7:0]  probe9
	);
	`endif
	end
endgenerate
//end

  // feed back the last captured data to VIO
  always @(posedge log_clk) begin
    if (log_rst) begin
      captured_data <= 64'h0;
    // IO interface
    end else if (iresp_tvalid && iresp_tready) begin
      captured_data <= axis_iresp_tdata;
    // maintenance interface
    end else if (maintr_rvalid && maintr_rready) begin
      captured_data <= axis_maintr_rdata;
    end
  end

  // Continuous data flow
  always @(posedge log_clk) begin
    continuous_go_q        <= continuous_go;
    ireq_request_done_q    <= ireq_request_done;
    ireq_autocheck_error_q <= ireq_autocheck_error;
    reset_request_gen      <= sim_train_en ? log_rst : |reset_continuous_srl && continuous_in_process;
  end

  always @(posedge log_clk) begin
    if (log_rst) begin
      continuous_in_process <= 1'b0;
    end else if (continuous_go && !continuous_go_q) begin
      continuous_in_process <= 1'b1;
    end else if (!continuous_go && continuous_go_q) begin
      continuous_in_process <= 1'b0;
    end
  end
  always @(posedge log_clk) begin
    if (log_rst) begin
      reset_continuous_set <= 1'b0;
      stop_continuous_test <= 1'b0;
    end else if (continuous_go && !continuous_go_q) begin
      reset_continuous_set <= 1'b1;
      stop_continuous_test <= 1'b0;
    end else if (!ireq_autocheck_error_q && ireq_autocheck_error && continuous_in_process) begin
      stop_continuous_test <= 1'b1;
    end else if (!stop_continuous_test && !ireq_request_done_q && ireq_request_done &&
                  continuous_in_process) begin
      reset_continuous_set <= 1'b1;
    end else begin
      reset_continuous_set <= 1'b0;
    end
  end
  always @(posedge log_clk) begin
    if (log_rst) begin
      reset_continuous_srl <= 16'h0;
    end else if (reset_continuous_set) begin
      reset_continuous_srl <= 16'hFFFF;
    end else begin
      reset_continuous_srl <= {reset_continuous_srl[14:0], 1'b0};
    end
  end

  // SRIO_DUT instantation -----------------
  // for production and shared logic in the core
  srio_gen2_0  srio_gen2_0_inst
     (//---------------------------------------------------------------
      .sys_clkp                (sys_clkp  ),
      .sys_clkn                (sys_clkn  ),
      .sys_rst                 (sys_rst   ),
      // all clocks as output in shared logic mode
      .log_clk_out             (log_clk   ),
      .phy_clk_out             (phy_clk   ),
      .gt_clk_out              (gt_clk    ),
      .gt_pcs_clk_out          (gt_pcs_clk),

      .drpclk_out              (drpclk    ),

      .refclk_out              (refclk    ),

      .clk_lock_out            (clk_lock  ),
      // all resets as output in shared logic mode
      .log_rst_out             (log_rst   ),
      .phy_rst_out             (phy_rst   ),
      .buf_rst_out             (buf_rst   ),
      .cfg_rst_out             (cfg_rst   ),
      .gt_pcs_rst_out          (gt_pcs_rst),

//---------------------------------------------------------------
      .gt0_qpll_clk_out        (gt0_qpll_clk_out        ),
      .gt0_qpll_out_refclk_out (gt0_qpll_out_refclk_out ),




// //---------------------------------------------------------------
      .srio_rxn0               (srio_rxn0),
      .srio_rxp0               (srio_rxp0),

      .srio_txn0               (srio_txn0),
      .srio_txp0               (srio_txp0),

      .s_axis_ireq_tvalid            (ireq_tvalid),
      .s_axis_ireq_tready            (ireq_tready),
      .s_axis_ireq_tlast             (ireq_tlast),
      .s_axis_ireq_tdata             (ireq_tdata),
      .s_axis_ireq_tkeep             (ireq_tkeep),
      .s_axis_ireq_tuser             (ireq_tuser),

      .m_axis_iresp_tvalid           (iresp_tvalid),
      .m_axis_iresp_tready           (iresp_tready),
      .m_axis_iresp_tlast            (iresp_tlast),
      .m_axis_iresp_tdata            (iresp_tdata),
      .m_axis_iresp_tkeep            (iresp_tkeep),
      .m_axis_iresp_tuser            (iresp_tuser),

      .s_axis_tresp_tvalid           (tresp_tvalid),
      .s_axis_tresp_tready           (tresp_tready),
      .s_axis_tresp_tlast            (tresp_tlast),
      .s_axis_tresp_tdata            (tresp_tdata),
      .s_axis_tresp_tkeep            (tresp_tkeep),
      .s_axis_tresp_tuser            (tresp_tuser),

      .m_axis_treq_tvalid            (treq_tvalid),
      .m_axis_treq_tready            (treq_tready),
      .m_axis_treq_tlast             (treq_tlast),
      .m_axis_treq_tdata             (treq_tdata),
      .m_axis_treq_tkeep             (treq_tkeep),
      .m_axis_treq_tuser             (treq_tuser),

      .s_axi_maintr_rst              (maintr_rst),

      .s_axi_maintr_awvalid          (maintr_awvalid),
      .s_axi_maintr_awready          (maintr_awready),
      .s_axi_maintr_awaddr           (maintr_awaddr),
      .s_axi_maintr_wvalid           (maintr_wvalid),
      .s_axi_maintr_wready           (maintr_wready),
      .s_axi_maintr_wdata            (maintr_wdata),
      .s_axi_maintr_bvalid           (maintr_bvalid),
      .s_axi_maintr_bready           (maintr_bready),
      .s_axi_maintr_bresp            (maintr_bresp),

      .s_axi_maintr_arvalid          (maintr_arvalid),
      .s_axi_maintr_arready          (maintr_arready),
      .s_axi_maintr_araddr           (maintr_araddr),
      .s_axi_maintr_rvalid           (maintr_rvalid),
      .s_axi_maintr_rready           (maintr_rready),
      .s_axi_maintr_rdata            (maintr_rdata),
      .s_axi_maintr_rresp            (maintr_rresp),

      .sim_train_en                  (sim_train_en),
      .phy_mce                       (phy_mce),
      .phy_link_reset                (phy_link_reset),
      .force_reinit                  (force_reinit),


      .phy_rcvd_mce                  (phy_rcvd_mce       ),
      .phy_rcvd_link_reset           (phy_rcvd_link_reset),
      .phy_debug                     (phy_debug          ),
      .gtrx_disperr_or               (gtrx_disperr_or    ),
      .gtrx_notintable_or            (gtrx_notintable_or ),

      .port_error                    (port_error         ),
      .port_timeout                  (port_timeout       ),
      .srio_host                     (srio_host          ),
      .port_decode_error             (port_decode_error  ),
      .deviceid                      (deviceid           ),
      .idle2_selected                (idle2_selected     ),
      .phy_lcl_master_enable_out     (), // these are side band output only signals
      .buf_lcl_response_only_out     (),
      .buf_lcl_tx_flow_control_out   (),
      .buf_lcl_phy_buf_stat_out      (),
      .phy_lcl_phy_next_fm_out       (),
      .phy_lcl_phy_last_ack_out      (),
      .phy_lcl_phy_rewind_out        (),
      .phy_lcl_phy_rcvd_buf_stat_out (),
      .phy_lcl_maint_only_out        (),
//---





//---
      .port_initialized              (port_initialized  ),
      .link_initialized              (link_initialized  ),
      .idle_selected                 (idle_selected     ),
      .mode_1x                       (mode_1x           )
     );
  // End of SRIO_DUT instantiation ---------


  // Initiator-driven side --------------------


  // {{{ IREQ Interface ---------------------------
  // Select between internally-driven sequences or user sequences
  assign ireq_tvalid = (VALIDATION_FEATURES) ? val_ireq_tvalid : axis_ireq_tvalid;
  assign ireq_tlast  = (VALIDATION_FEATURES) ? val_ireq_tlast  : axis_ireq_tlast;
  assign ireq_tdata  = (VALIDATION_FEATURES) ? val_ireq_tdata  : axis_ireq_tdata;
  assign ireq_tkeep  = (VALIDATION_FEATURES) ? val_ireq_tkeep  : axis_ireq_tkeep;
  assign ireq_tuser  = (VALIDATION_FEATURES) ? val_ireq_tuser  : axis_ireq_tuser;

  assign axis_ireq_tready = (!VALIDATION_FEATURES) && ireq_tready;
  assign val_ireq_tready  = (VALIDATION_FEATURES)  && ireq_tready;
	


  // When enabled, report results.
  // This is a simulation-only option and cannot be synthesized
  generate if (SIM_VERBOSE) begin: ireq_reporting_gen
   srio_report
     #(.VERBOSITY        (2),
       .DIRECTION        (1),
       .NAME             (0))  // Data is flowing into the core
     srio_ireq_report_inst
      (
      .log_clk                 (log_clk),
      .log_rst                 (log_rst),

      .tvalid                  (ireq_tvalid),
      .tready                  (ireq_tready),
      .tlast                   (ireq_tlast),
      .tdata                   (ireq_tdata),
      .tkeep                   (ireq_tkeep),
      .tuser                   (ireq_tuser)
     );
  end
  endgenerate
  // }}} End of IREQ Interface --------------------


  // {{{ Initiator Generator/Checker --------------

  // If internally-driven sequences are required
  generate if (VALIDATION_FEATURES) begin: ireq_validation_gen
   srio_request_gen_srio_gen2_0
     #(.SEND_SWRITE       (1),
       .SEND_NWRITER      (1),
       .SEND_NWRITE       (1),
       .SEND_NREAD        (1),
       .SEND_FTYPE9       (0),
       .SEND_DB           (1),
       .SEND_MSG          (1))
     srio_request_gen_inst (
      .log_clk                 (log_clk),
      .log_rst                 (reset_request_gen),

      .deviceid                (deviceid),
      .dest_id                 (dest_id),
      .source_id               (source_id),
      .id_override             (id_override),

      .val_ireq_tvalid         (val_ireq_tvalid),
      .val_ireq_tready         (val_ireq_tready),
      .val_ireq_tlast          (val_ireq_tlast),
      .val_ireq_tdata          (val_ireq_tdata),
      .val_ireq_tkeep          (val_ireq_tkeep),
      .val_ireq_tuser          (val_ireq_tuser),

      .val_iresp_tvalid        (val_iresp_tvalid),
      .val_iresp_tready        (val_iresp_tready),
      .val_iresp_tlast         (val_iresp_tlast),
      .val_iresp_tdata         (val_iresp_tdata),
      .val_iresp_tkeep         (val_iresp_tkeep),
      .val_iresp_tuser         (val_iresp_tuser),

      .link_initialized        (link_initialized),

      // use these ports to peek/poke IO transactions
      .go                      (go_req),
      .user_addr               ({10'h000, user_addr}),
      .user_ftype              (user_ftype),
      .user_ttype              (user_ttype),
      .user_size               (user_size),
      .user_data               (user_data),

      .request_autocheck_error (ireq_autocheck_error),
      .request_done            (ireq_request_done)
     );
  end
  endgenerate
  // }}} End of Initiator Generator/Checker -------


  // {{{ IRESP Interface --------------------------
  // Select between internally-driven sequences or user sequences

  assign iresp_tready = (VALIDATION_FEATURES) ? val_iresp_tready : axis_iresp_tready;

  assign val_iresp_tvalid  = (VALIDATION_FEATURES) && iresp_tvalid;
  assign val_iresp_tlast   = iresp_tlast;
  assign val_iresp_tdata   = iresp_tdata;
  assign val_iresp_tkeep   = iresp_tkeep;
  assign val_iresp_tuser   = iresp_tuser;

  assign axis_iresp_tvalid = (!VALIDATION_FEATURES) && iresp_tvalid;
  assign axis_iresp_tlast  = iresp_tlast;
  assign axis_iresp_tdata  = iresp_tdata;
  assign axis_iresp_tkeep  = iresp_tkeep;
  assign axis_iresp_tuser  = iresp_tuser;


  // When enabled, report results.
  // This is a simulation-only option and cannot be synthesized
  generate if (SIM_VERBOSE) begin: iresp_reporting_gen
   srio_report
     #(.VERBOSITY              (2),
       .DIRECTION              (0),
       .NAME                   (1))  // Data is flowing out of the core
     srio_iresp_report_inst
      (
      .log_clk                 (log_clk),
      .log_rst                 (log_rst),

      .tvalid                  (iresp_tvalid),
      .tready                  (iresp_tready),
      .tlast                   (iresp_tlast),
      .tdata                   (iresp_tdata),
      .tkeep                   (iresp_tkeep),
      .tuser                   (iresp_tuser)
     );
  end
  endgenerate
  // }}} End of IRESP Interface -------------------





  assign autocheck_error         = ireq_autocheck_error || maint_autocheck_error;
  assign exercise_done           = ireq_request_done && maint_done;

  // }}} End of Initiator-driven side -------------


  // {{{ Target-driven side -----------------------

  // {{{ TRESP Interface --------------------------
  // Select between internally-driven sequences or user sequences
/*  `ifndef SIM
  assign tresp_tvalid = (VALIDATION_FEATURES) ? val_tresp_tvalid : axis_tresp_tvalid;
  assign tresp_tlast  = (VALIDATION_FEATURES) ? val_tresp_tlast  : axis_tresp_tlast;
  assign tresp_tdata  = (VALIDATION_FEATURES) ? val_tresp_tdata  : axis_tresp_tdata;
  assign tresp_tkeep  = (VALIDATION_FEATURES) ? val_tresp_tkeep  : axis_tresp_tkeep;
  assign tresp_tuser  = (VALIDATION_FEATURES) ? val_tresp_tuser  : axis_tresp_tuser;
`endif*/
  assign axis_tresp_tready = (!VALIDATION_FEATURES) && tresp_tready;
  assign val_tresp_tready  = (VALIDATION_FEATURES)  && tresp_tready;


  // When enabled, report results.
  // This is a simulation-only option and cannot be synthesized
  generate if (SIM_VERBOSE) begin: tresp_reporting_gen
   srio_report
     #(.VERBOSITY              (2),
       .DIRECTION              (1),
       .NAME                   (8))  // Data is flowing into the core
     srio_tresp_report_inst
      (
      .log_clk                 (log_clk),
      .log_rst                 (log_rst),

      .tvalid                  (tresp_tvalid),
      .tready                  (tresp_tready),
      .tlast                   (tresp_tlast),
      .tdata                   (tresp_tdata),
      .tkeep                   (tresp_tkeep),
      .tuser                   (tresp_tuser)
     );
  end
  endgenerate
  // }}} End of TRESP Interface -------------------


  // {{{ Target Generator/Checker -----------------

  // If internally-driven sequences are required
  generate if (VALIDATION_FEATURES) begin: tresp_validation_gen
   srio_response_gen_srio_gen2_0 srio_response_gen_inst (
      .log_clk                 (log_clk),
      .log_rst                 (log_rst),

      .deviceid                (deviceid),
      .source_id               (source_id),
      .id_override             (id_override),

      .val_tresp_tvalid        (val_tresp_tvalid),
      .val_tresp_tready        (val_tresp_tready),
      .val_tresp_tlast         (val_tresp_tlast),
      .val_tresp_tdata         (val_tresp_tdata),
      .val_tresp_tkeep         (val_tresp_tkeep),
      .val_tresp_tuser         (val_tresp_tuser),

      .val_treq_tvalid         (val_treq_tvalid),
      .val_treq_tready         (val_treq_tready),
      .val_treq_tlast          (val_treq_tlast),
      .val_treq_tdata          (val_treq_tdata),
      .val_treq_tkeep          (val_treq_tkeep),
      .val_treq_tuser          (val_treq_tuser)
     );
  end
  endgenerate
  // }}} End of Target Generator/Checker ----------


  // {{{ TREQ Interface ---------------------------
  // Select between internally-driven sequences or user sequences
  /*
`ifndef SIM
  assign treq_tready = (VALIDATION_FEATURES) ? val_treq_tready : axis_treq_tready;
`endif
*/
  assign val_treq_tvalid  = (VALIDATION_FEATURES) && treq_tvalid;
  assign val_treq_tlast   = treq_tlast;
  assign val_treq_tdata   = treq_tdata;
  assign val_treq_tkeep   = treq_tkeep;
  assign val_treq_tuser   = treq_tuser;

  assign axis_treq_tvalid = (!VALIDATION_FEATURES) && treq_tvalid;
  assign axis_treq_tlast  = treq_tlast;
  assign axis_treq_tdata  = treq_tdata;
  assign axis_treq_tkeep  = treq_tkeep;
  assign axis_treq_tuser  = treq_tuser;


  // When enabled, report results.
  // This is a simulation-only option and cannot be synthesized
  generate if (SIM_VERBOSE) begin: treq_reporting_gen
   srio_report
     #(.VERBOSITY              (2),
       .DIRECTION              (0),
       .NAME                   (9))  // Data is flowing out of the core
     srio_treq_report_inst
      (
      .log_clk                 (log_clk),
      .log_rst                 (log_rst),

      .tvalid                  (treq_tvalid),
      .tready                  (treq_tready),
      .tlast                   (treq_tlast),
      .tdata                   (treq_tdata),
      .tkeep                   (treq_tkeep),
      .tuser                   (treq_tuser)
     );
  end
  endgenerate
  // }}} End of TREQ Interface --------------------



  // }}} End of Target-driven side ----------------

  // {{{ Maintenance Interface --------------------

  // Select between internally-driven sequences or user sequences
  assign maintr_awvalid = (QUICK_STARTUP) ? val_maintr_awvalid : axis_maintr_awvalid;
  assign maintr_awaddr  = (QUICK_STARTUP) ? val_maintr_awaddr  : axis_maintr_awaddr;
  assign maintr_wvalid  = (QUICK_STARTUP) ? val_maintr_wvalid  : axis_maintr_wvalid;
  assign maintr_wdata   = (QUICK_STARTUP) ? val_maintr_wdata   : axis_maintr_wdata;
  assign maintr_bready  = (QUICK_STARTUP) ? val_maintr_bready  : axis_maintr_bready;

  assign maintr_arvalid = (QUICK_STARTUP) ? val_maintr_arvalid : axis_maintr_arvalid;
  assign maintr_araddr  = (QUICK_STARTUP) ? val_maintr_araddr  : axis_maintr_araddr;
  assign maintr_rready  = (QUICK_STARTUP) ? val_maintr_rready  : axis_maintr_rready;


  assign axis_maintr_awready = (!QUICK_STARTUP) && maintr_awready;
  assign axis_maintr_wready = (!QUICK_STARTUP) && maintr_wready;
  assign axis_maintr_bvalid = (!QUICK_STARTUP) && maintr_bvalid;
  assign axis_maintr_bresp = maintr_bresp;

  assign axis_maintr_arready = (!QUICK_STARTUP) && maintr_arready;
  assign axis_maintr_rvalid = (!QUICK_STARTUP) && maintr_rvalid;
  assign axis_maintr_rdata = maintr_rdata;
  assign axis_maintr_rresp = maintr_rresp;

  assign val_maintr_awready = (QUICK_STARTUP) && maintr_awready;
  assign val_maintr_wready = (QUICK_STARTUP) && maintr_wready;
  assign val_maintr_bvalid = (QUICK_STARTUP) && maintr_bvalid;
  assign val_maintr_bresp = maintr_bresp;

  assign val_maintr_arready = (QUICK_STARTUP) && maintr_arready;
  assign val_maintr_rvalid = (QUICK_STARTUP) && maintr_rvalid;
  assign val_maintr_rdata = maintr_rdata;
  assign val_maintr_rresp = maintr_rresp;


  // If internally-driven sequences are required
  generate if (QUICK_STARTUP) begin: quick_maint_gen
   srio_quick_start_srio_gen2_0 srio_quick_start_inst (
      .log_clk                 (log_clk),
      .log_rst                 (log_rst),

      .maintr_awvalid          (val_maintr_awvalid),
      .maintr_awready          (val_maintr_awready),
      .maintr_awaddr           (val_maintr_awaddr),
      .maintr_wvalid           (val_maintr_wvalid),
      .maintr_wready           (val_maintr_wready),
      .maintr_wdata            (val_maintr_wdata),
      .maintr_bvalid           (val_maintr_bvalid),
      .maintr_bready           (val_maintr_bready),
      .maintr_bresp            (val_maintr_bresp),

      .maintr_arvalid          (val_maintr_arvalid),
      .maintr_arready          (val_maintr_arready),
      .maintr_araddr           (val_maintr_araddr),
      .maintr_rvalid           (val_maintr_rvalid),
      .maintr_rready           (val_maintr_rready),
      .maintr_rdata            (val_maintr_rdata),
      .maintr_rresp            (val_maintr_rresp),

      // use these ports to peek/poke maintenance transactions
      .go                      (go_maint),
      .user_hop                (user_hop),
      .user_inst               (maint_inst),
      .user_addr               (user_addr),
      .user_data               (user_data[31:0]),

      .link_initialized        (link_initialized),
      .maint_done              (maint_done),
      .maint_autocheck_error   (maint_autocheck_error)
     );
  end else begin : no_quick_maint_gen
    assign maintr_awaddr         = 32'h0;
    assign maintr_wvalid         = 1'b0;
    assign maintr_wdata          = 32'h0;
    assign maintr_bready         = 1'b0;
    assign maintr_arvalid        = 1'b0;
    assign maintr_araddr         = 32'h0;
    assign maintr_rready         = 1'b0;
    assign maint_done            = 1'b1;
    assign maint_autocheck_error = 1'b0;
  end
  endgenerate

  // }}} End of Maintenance Interface -------------


  // {{{ Statistics Gatherer ----------------------

  // When enabled, statistics gatherer collects details about performance.
  // This module is synthesizable and may be accessed through Chipscope
  generate if (STATISTICS_GATHERING) begin: stats_gen
   srio_statistics_srio_gen2_0 srio_statistics_inst (
      .log_clk                 (log_clk),
      .phy_clk                 (phy_clk),
      .gt_pcs_clk              (gt_pcs_clk),
      .log_rst                 (log_rst),
      .phy_rst                 (phy_rst),

      // outgoing port 1
      .tvalid_o1                  (ireq_tvalid),
      .tready_o1                  (ireq_tready),
      .tlast_o1                   (ireq_tlast),
      .tdata_o1                   (ireq_tdata),

      // outgoing port 2
      .tvalid_o2                  (iresp_tvalid),
      .tready_o2                  (iresp_tready),
      .tlast_o2                   (iresp_tlast),
      .tdata_o2                   (iresp_tdata),

      // incoming port 1
      .tvalid_i1                  (treq_tvalid),
      .tready_i1                  (treq_tready),
      .tlast_i1                   (treq_tlast),
      .tdata_i1                   (treq_tdata),

      // incoming port 2
      .tvalid_i2                  (tresp_tvalid),
      .tready_i2                  (tresp_tready),
      .tlast_i2                   (tresp_tlast),
      .tdata_i2                   (tresp_tdata),

      .link_initialized        (link_initialized),
      .phy_debug               (phy_debug),
      .gtrx_disperr_or         (gtrx_disperr_or),
      .gtrx_notintable_or      (gtrx_notintable_or),

      .register_reset          (register_reset),
      .reset_all_registers     (reset_all_registers),
      .stats_address           (stats_address),

      .stats_data              (stats_data)
     );
  end
  endgenerate

  // }}} End of Statistics Gatherer ---------------

endmodule
