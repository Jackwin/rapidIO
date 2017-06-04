/*  Author: chunjie Wang
	Date: 2017-06-01
	Description: Self check via Doorbell message.

*/
`timescale 1ps/1ps
module db_req (
	input log_clk,
	input log_rst,

	input wire [15:0] src_id,
	input wire [15:0] des_id,

	input wire dr_req_in,
	input wire nwr_req_in,
	input wire link_initialized,

	output reg target_ready_o,
	output reg target_busy_o,

	input go,
	input      [33:0] user_addr,
    input       [3:0] user_ftype,
    input       [3:0] user_ttype,
    input       [7:0] user_size,
    input      [63:0] user_data,

	output reg 			ireq_tvalid_o,
	input wire 			ireq_tready_in,
	output reg 			ireq_tlast_o,
	output reg [63:0]	ireq_tdata_o,
	output reg [7:0] 	ireq_tkeep_o,	
	output reg [31:0] 	ireq_tuser_o,

    input             iresp_tvalid,
    output reg        iresp_tready,
    input             iresp_tlast,
    input      [63:0] iresp_tdata,
    input       [7:0] iresp_tkeep,
    input      [31:0] iresp_tuser	
	);
localparam [3:0] DOORB = 4'hA;
localparam [3:0] NWRITE = 4'h5;

localparam [3:0] TNWR   = 4'h4;

localparam [63:0] db_instr = {
// srcTID  FTYPE  R    R      prio  CRF    R     Info      R
	{8'h00, DOORB, 4'h0, 1'b0, 2'h1, 1'b0, 12'b0, 16'h0101, 16'h0}
};
/*localparam [63:0] nwrite_instr = {
	srcTID, NWRITE, TNWR, 1'b0, 2'h1, 1'b0, (size-1), 2'h0, addr}
};
*/

// FSM signals
localparam [2:0] IDLE_s = 3'h0;
localparam [2:0] DB_REQ_s = 3'h1;
localparam [2:0] DB_RESP_s = 3'h2;
localparam [2:0] NWRITE_s = 3'h3;
localparam [2:0] END_s = 3'h4;
reg [2:0] state;

reg  [15:0] log_rst_shift;
wire        log_rst_q;

wire [63:0] nwrite_instr;

reg dr_req_r1, dr_req_p;

// Response signals
wire  [7:0] current_resp_tid;
wire  [3:0] current_resp_ftype;
wire  [3:0] current_resp_ttype;
wire  [7:0] current_resp_size;
wire  [1:0] current_resp_prio;
wire [33:0] current_resp_addr;
wire [15:0] current_resp_srcid;
wire [15:0] current_resp_db_info;
wire [15:0] resp_dest_id;
wire [15:0] resp_src_id;

wire get_a_response;
wire target_ready;
wire target_busy;

always @(posedge log_clk or posedge log_rst) begin
	if (log_rst)
  		log_rst_shift <= 16'hFFFF;
	else
  		log_rst_shift <= {log_rst_shift[14:0], 1'b0};
end
assign log_rst_q = log_rst_shift[15];

// put a sufficient delay on the initialization to improve simulation time.
// Not needed for actual hardware but does no damage if kept.
always @(posedge log_clk) begin
    if (log_rst_q) begin
      link_initialized_cnt <= 0;
    end else if (link_initialized && !link_initialized_delay) begin
      link_initialized_cnt <= link_initialized_cnt + 1'b1;
    end else if (!link_initialized) begin
      link_initialized_cnt <= 0;
    end
 end

always @(posedge log_clk) begin
	dr_req_r1 <= dr_req_in;
	dr_req_p <= ~dr_req_r1 & dr_req_in;
end

always @(posedge log_clk) begin
	if (log_rst_q) begin
		state <= IDLE_s;
		ireq_tvalid_o <= 1'b0;
		ireq_tlast_o <= 1'b0;
		ireq_tdata_o <= 1'b0;
		ireq_tkeep_o <= 1'b0;
		ireq_tuser_o <= 1'b0;
	end
	else begin
		ireq_tvalid_o <= 1'b0;
		ireq_tlast_o <= 1'b0;
		ireq_tdata_o <= 1'b0;
		ireq_tkeep_o <= 1'b0;
		ireq_tuser_o <= 1'b0;
		case (state)
		IDLE_s: begin
			if (dr_req_in) begin
				state <= DB_REQ_s;
			end
			else if (nwr_req_in) begin
				state <= NWRITE_s;
			end
			else begin
				state <= IDLE_s;
			end
		end
		DB_REQ_s: begin
			if (ireq_tready_in) begin
				state <= DB_RESP_s;
			end
			else begin
				state <= DB_REQ_s;
			end

			if (ireq_tready_in) begin
				ireq_tdata_o <= db_instr[63:0];
				ireq_tvalid_o <= 1'b1;
				ireq_tkeep_o <= 8'hff;
				ireq_tlast_o <= 1'b1;
				ireq_tuser_o <= {src_id, des_id};	
			end
		end
		DB_RESP_s: begin
			if (target_ready) begin
				target_ready_o	<= 1'b1;
				state <= IDLE_s;
			end
			else if (target_busy_o) begin
				target_busy_o <= 1'b1;
				state <= IDLE_s;
			end
			else begin
				target_ready_o <= 1'b0;
				target_busy_o <= 1'b0;
				state <= DB_RESP_s;
			end
		end
		NWRITE_s：begin
		end
		
	end
end

assign current_resp_tid   = treq_tdata[63:56];
assign current_resp_ftype = treq_tdata[55:52];
assign current_resp_ttype = treq_tdata[51:48];
assign current_resp_size  = treq_tdata[43:36];
assign current_resp_prio  = treq_tdata[46:45] + 2'b01; // Response priority should be increased by 1
assign current_resp_addr  = treq_tdata[33:0];
assign current_resp_db_info = treq_tdata[31:16];
assign current_srcid = treq_tuser[31:16];


assign get_a_response = 1'b1 ? (current_resp_ftype == DOORB	&& current_srcid == 0xf0) : 1'b0;
assign target_ready = 1'b1 ? (get_a_response && current_resp_db_info == 0x0100) : 1'b0;
assign target_busy = 1'b1 ? (get_a_response && current_resp_db_info == 0x0100) : 1'b0;


always @(posedge log_clk or posedge log_rst) begin
	if (log_rst) begin
		ireq_tvalid_o <= 1'b0;
		ireq_tlast_o <= 1'b0;
		ireq_tdata_o <= 1'b0;
		ireq_tkeep_o <= 1'b0;
		ireq_tuser_o <= 1'b0;
	end
	else if (dr_req_p && ireq_tready_in) begin
		ireq_tdata_o <= db_instr[63:0];
		ireq_tvalid_o <= 1'b1;
		ireq_tkeep_o <= 8'hff;
		ireq_tlast_o <= 1'b1;
		ireq_tuser_o <= {src_id, des_id};	
	end
	else begin
		ireq_tvalid_o <= 1'b0;
		ireq_tlast_o <= 1'b0;
		ireq_tdata_o <= 1'b0;
		ireq_tkeep_o <= 1'b0;
		ireq_tuser_o <= 1'b0;
	end
end

endmodule

