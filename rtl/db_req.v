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

	output reg 			ireq_tvalid_o,
	input wire 			ireq_tready_in,
	output reg 			ireq_tlast_o,
	output reg [63:0]	ireq_tdata_o,
	output reg [7:0] 	ireq_tkeep_o,	
	output reg [31:0] 	ireq_tuser_o


	);
localparam [3:0] DOORB = 4'hA;
localparam [63:0] db_instr = {
// srcTID  FTYPE  R    R      prio  CRF    R     Info      R
	{8'h00, DOORB, 4'b0, 1'b0, 2'h1, 1'b0, 12'b0, 16'h0101, 16'h0}
};

reg dr_req_r1, dr_req_p;

always @(posedge log_clk) begin
	dr_req_r1 <= dr_req_in;
	dr_req_p <= ~dr_req_r1 & dr_req_in;
end

always @(posedge clk or posedge rst) begin
	if (rst) begin
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

