`timescale 1ns/1ns

module db_resp
(
	input log_clk,
	input log_rst,

	input wire [15:0] src_id,
	input wire [15:0] des_id,

	input wire [1:0] ed_ready_in,

	input wire treq_tvalid_in,
	output wire treq_tready_o,
	input wire treq_tlast_in,
	input wire [63:0] treq_tdata_in,
	input wire [7:0] treq_tkeep_in,
	input wire [31:0] treq_tuser_in,

	// response interface
	input wire 			tresp_tready_in,
	output reg 			tresp_tvalid_o,
	output reg 			tresp_tlast_o,
	output reg [63:0]	tresp_tdata_o,
	output reg [7:0] 	tresp_tkeep_o,	
	output reg [31:0] 	tresp_tuser_o
	);
// Local parameter
localparam [3:0] NREAD  = 4'h2;
localparam [3:0] NWRITE = 4'h5;
localparam [3:0] SWRITE = 4'h6;
localparam [3:0] DOORB  = 4'hA;
localparam [3:0] MESSG  = 4'hB;
localparam [3:0] RESP   = 4'hD;

localparam [3:0] TNWR   = 4'h4;
localparam [3:0] TNWR_R = 4'h5;
localparam [3:0] TNRD   = 4'h4;

localparam [3:0] TNDATA = 4'h0;
localparam [3:0] MSGRSP = 4'h1;
localparam [3:0] TWDATA = 4'h8;

localparam [64*2-1:0] db_instr = {
// srcTID  FTYPE  R    R      prio  CRF    R     Info      R
	{8'h00, DOORB, 4'b0, 1'b0, 2'h1, 1'b0, 12'b0, 16'h0100, 16'h0},   //endpoint is ready
	{8'h00, DOORB, 4'b0, 1'b0, 2'h1, 1'b0, 12'b0, 16'h01FF, 16'h0}    // endpoint is not ready
};

  // incoming packet fields
wire  [7:0] current_tid;
wire  [3:0] current_ftype;
wire  [3:0] current_ttype;
wire  [7:0] current_size;
wire  [1:0] current_prio;
wire [33:0] current_addr;
wire [15:0] current_srcid;
wire [15:0] current_db_info;

// request signals

wire treq_advance_condition;
reg tresp_advance_condition;

reg first_beat;
reg generate_a_response;

reg ed_ready;
reg [15:0] log_rst_shift;
wire log_rst_q;

assign treq_advance_condition = treq_tvalid_in;
assign treq_tready_o = 1'b1;
//tresp_advance_condition = tresp_tready_in && tresp_tvalid_in;

// Generate log reset 
always @(posedge log_clk or posedge log_rst) begin
	if (log_rst) begin
		log_rst_shift <= 16'hff;
	end
	else begin
		log_rst_shift <= {log_rst_shift[14:0], 1'b0};
	end
end
assign log_rst_q = log_rst_shift[15];


always @(posedge log_clk) begin
	if (log_rst_q) begin
 	 first_beat <= 1'b1;
	end 
	else if (treq_advance_condition && treq_tlast_in) begin
  		first_beat <= 1'b1;
	end
	else if (treq_advance_condition) begin
  	first_beat <= 1'b0;
	end
end

assign current_tid   = treq_tdata_in[63:56];
assign current_ftype = treq_tdata_in[55:52];
assign current_ttype = treq_tdata_in[51:48];
assign current_size  = treq_tdata_in[43:36];
assign current_prio  = treq_tdata_in[46:45] + 2'b01;
assign current_addr  = treq_tdata_in[33:0];
assign current_db_info = treq_tdata_in[31:16];
assign current_srcid = treq_tuser_in[31:16];

always @(posedge log_clk) begin
	if (current_ftype == DOORB && treq_tvalid_in) begin
		$display("Get a request from target, whose src_id is %x", current_srcid);
		$display("The inform in the request is %x",current_db_info);
	end
end

// Generate a response flag
always @(posedge log_clk) begin
    if (log_rst_q) begin
      generate_a_response <= 1'b0;
    end else if (first_beat && treq_advance_condition) begin
      generate_a_response <= (current_ftype == DOORB);
    end else begin
      generate_a_response <= 1'b0;
    end
  end

always @(posedge log_clk) begin
	if (log_rst_q) begin
		//treq_tready_o <= 1'b1;
		tresp_advance_condition <= 1'b0;
	end
	else begin
		if (generate_a_response) begin
			tresp_advance_condition <= 1'b1;
		//	treq_tready_o <= 1'b0;
		end
		else begin
			tresp_advance_condition <= 1'b0;
		end

		if (tresp_advance_condition && tresp_tready_in) begin
			if (ed_ready_in == 2'h1) begin
				tresp_tdata_o <= db_instr[64*2-1:64];
			end
			else begin
				tresp_tdata_o <= db_instr[63:0];
			end
			tresp_tkeep_o <= 8'hff;
			tresp_tlast_o <= 1'b1;
			tresp_tvalid_o <= 1'b1;
			tresp_tuser_o <= {src_id, des_id};
			//tresp_advance_condition <= 1'b0;
		end
		else begin
			//treq_tready_o <= 1'b1;
			tresp_tvalid_o <= 1'b0;
			tresp_tdata_o <= 64'h0;
			tresp_tkeep_o <= 8'h0;
			tresp_tuser_o <= 32'h0;
			tresp_tlast_o <= 1'b0;
			//tresp_advance_condition <= tresp_advance_condition;
		end
	end
end

endmodule
