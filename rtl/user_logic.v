`timescale 	1ns/1ns

module user_logic (

	input wire log_clk,
	input wire log_rst,

	input wire nwr_ready_in,
	input wire nwr_busy_in,
	input wire nwr_done_in,

	input wire user_tready_in,
	output wire [33:0] user_addr_o,


    output wire [11:0] user_tsize_o,

    output wire [63:0] user_tdata_o,
    output reg user_tvalid_o,
    output reg [7:0] user_tkeep_o,
    output wire user_tlast_o

	);

localparam DATA_SIZE0 = 255;
localparam DATA_SIZE1 = 256;
localparam DATA_SIZE2 = 257;
localparam DATA_SIZE3 = 258;
localparam DATA_SIZE4 = 259;
localparam DATA_SIZE5 = 260;
localparam DATA_SIZE6 = 512;
localparam DATA_SIZE7 = 513;

localparam IDLE_s = 2'd0;
localparam GEN_DATA_s = 2'd1;
localparam END_s = 2'd2;

reg [2:0] data_sel;

reg [1:0] state;
reg [63:0] gen_data;
reg [11:0] user_tsize;

reg [11:0] byte_cnt;

// Count the sent data in the unit of qword
reg [9:0] qword_cnt;
reg data_first;


assign user_tsize_o = user_tsize-1;
assign user_tlast_o = ((qword_cnt == (user_tsize[11:3] ) && user_tsize[2:0] == 2'd0) ||
						(qword_cnt == (user_tsize[11:3] + 1) && user_tsize[2:0] != 2'd0));
assign user_tdata_o = gen_data;

always @(user_tlast_o) begin
	if (user_tlast_o) begin
		case(user_tsize[2:0]) 
			// Data placement is from left to high, like little-endian.
			3'd0: user_tkeep_o = 8'hff;
			3'h1: user_tkeep_o = 8'h80;
			3'h2: user_tkeep_o = 8'ha0;
			3'h3: user_tkeep_o = 8'he0;
			3'h4: user_tkeep_o = 8'hf0;
			3'h5: user_tkeep_o = 8'hf8;
			3'h6: user_tkeep_o = 8'hfa;
			3'h7: user_tkeep_o = 8'hfe;
			default: user_tkeep_o = 8'h0;
		endcase
	end
	else begin
		user_tkeep_o = 8'hff;
	end
end

always @(posedge log_clk or posedge	log_rst) begin
	if (log_rst) begin
		state <= IDLE_s;
		data_sel <= 2'h0;
		gen_data <= 'h0;
		qword_cnt <= 'h0;
		byte_cnt <= 'h0;
		user_tsize <= 12'hfff;
	end
	else begin
		user_tvalid_o <= 1'b0;
		case(state)
			IDLE_s: begin
				data_sel <= 2'h0;
				gen_data <= 'h0;
				qword_cnt <= 'h0;
				byte_cnt <= 'h0;
				if (nwr_ready_in && user_tready_in) begin
					state <= GEN_DATA_s;
					data_sel <= data_sel + 4'h1;
					gen_data <= {52'h0, user_tsize-1};
					user_tvalid_o <= 1'b1;
				end
				else begin
					state <= IDLE_s;
				end

				case(data_sel)
					3'd0: user_tsize <= DATA_SIZE0;
					3'd1: user_tsize <= DATA_SIZE1;
					3'd2: user_tsize <= DATA_SIZE2;
					3'd3: user_tsize <= DATA_SIZE3;
					3'd4: user_tsize <= DATA_SIZE4;
					3'd5: user_tsize <= DATA_SIZE5;
					3'd6: user_tsize <= DATA_SIZE6;
					3'd7: user_tsize <= DATA_SIZE7;
				endcase // data_sel
			end
			GEN_DATA_s: begin

				if (user_tready_in) begin
					gen_data <= gen_data + 64'h1;
					user_tvalid_o <= 1'b1;
					qword_cnt <= qword_cnt + 1;
		
				end
				else begin
					gen_data <= gen_data;
					user_tvalid_o <= 1'b0;
					qword_cnt <= qword_cnt;
				end

				if (user_tlast_o) begin
					state <= END_s;
					user_tvalid_o <= 1'b0;
				end
				else begin
					state <= GEN_DATA_s;
				end // else
			end
			END_s: begin
				data_sel <= 2'h0;
				gen_data <= 'h0;
				qword_cnt <= 'h0;
				byte_cnt <= 'h0;
			end
			default: begin
				state <= IDLE_s;
			end
		endcase // data_sel
	end
end

always @(posedge log_clk or posedge log_rst) begin
	if (log_rst) begin
		data_first <= 1'b1;
	end
	else begin
		if (user_tlast_o && user_tvalid_o) begin
			data_first <= 1'b1;
		end
		else if (user_tvalid_o) begin
			data_first <= 1'b0;
		end
	end
end
				
endmodule // user_logic	
