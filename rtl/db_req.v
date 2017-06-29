/*  Author: chunjie Wang
	Date: 2017-06-01
	Description: Self check via Doorbell message.

*/

`timescale 1ns/1ns
module db_req (
	input log_clk,
	input log_rst,

	input wire [7:0] src_id,
	input wire [7:0] des_id,

	// Before NWR, the system should finish self-check via doorbell
	input wire self_check_in,
	input wire nwr_req_in,
	output reg rapidIO_ready_o,
	input wire link_initialized,

	// Indicate NWR is ready to receive data from user logic
	output reg nwr_ready_o,
	output reg nwr_busy_o,
	output reg nwr_done_o,

	
	output wire user_tready_o,
	input wire [33:0] user_addr,
    input wire [3:0] user_ftype,
    input wire [3:0] user_ttype,
    input wire [11:0] user_tsize_in,

    input wire [63:0] user_tdata_in,
    input wire user_tvalid_in,
    input wire [7:0] user_tkeep_in,
    input wire user_tlast_in,
    //Bytelength

	output reg 			ireq_tvalid_o,
	input wire 			ireq_tready_in,
	output reg 			ireq_tlast_o,
	output reg [63:0]	ireq_tdata_o,
	output reg [7:0] 	ireq_tkeep_o,	
	output reg [31:0] 	ireq_tuser_o,

    input             iresp_tvalid_in,
    output wire        iresp_tready_o,
    input             iresp_tlast_in,
    input      [63:0] iresp_tdata_in,
    input       [7:0] iresp_tkeep_in,
    input      [31:0] iresp_tuser_in	
	);
localparam [3:0] DOORB = 4'hA;
localparam [3:0] NWR = 4'h5;

localparam [3:0] TNWR   = 4'h4;

localparam [63:0] db_instr = {
// srcTID  FTYPE  R    R      prio  CRF    R     Info      R
	{8'h00, DOORB, 4'h0, 1'b0, 2'h1, 1'b0, 12'b0, 16'h0101, 16'h0}
};
/*localparam [63:0] nwr_instr = {
	srcTID, nwr, TNWR, 1'b0, 2'h1, 1'b0, (size-1), 2'h0, addr}
};
*/

// FSM signals
localparam [2:0] IDLE_s = 3'h0;
localparam [2:0] DB_REQ_s = 3'h1;
localparam [2:0] DB_RESP_s = 3'h2;
localparam [2:0] NWR_s = 3'h3;
localparam [2:0] END_s = 3'h4;
reg [2:0] state;

reg  [15:0] log_rst_shift;
wire        log_rst_q;

// nwr signals
wire [63:0] nwr_instr;
reg nwr_first_beat;
wire nwr_advance_condition;
reg nwr_done ;
wire [7:0] nwr_srcID;
reg [33:0] target_ed_addr;
// After the NWR operation, enable doorbell request and send the address (0x0200+n)
reg db_req_ena;
reg [15:0] db_req_inform;


// Update the source ID
reg bit_reverse;

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

// FIFO signals
wire fifo_clk;
wire fifo_rst;
wire [74:0] fifo_din;
wire fifo_wr_en;
reg fifo_rd_en;
wire [74:0] fifo_dout;
wire fifo_full;
wire fifo_empty;
wire [8:0] fifo_data_cnt;
reg fifo_data_first;


// User logic signals
reg user_tvalid_r;
reg [63:0] 	user_tdata_r;
reg user_tlast_r;
reg [7:0] user_tkeep_r;
wire [63:0] current_user_data;
wire current_user_valid;
wire current_user_first;
wire [7:0] current_user_keep;
wire current_user_last;
wire [11:0] current_user_size;

reg [8:0] nwr_byte_cnt;
reg [8:0] nwr_8byte_cnt;
reg [4:0] nwr_packect_transfer_cnt; // A whole packect contains 256 bytes
reg user_data_first;
reg [4:0] packect_transfer_times;
wire [7:0] byte_left;

always @(posedge log_clk or posedge log_rst) begin
	if (log_rst)
  		log_rst_shift <= 16'hFFFF;
	else
  		log_rst_shift <= {log_rst_shift[14:0], 1'b0};
end
assign log_rst_q = log_rst_shift[15];

// put a sufficient delay on the initialization to improve simulation time.
// Not needed for actual hardware but does no damage if kept.
/*always @(posedge log_clk) begin
    if (log_rst_q) begin
      link_initialized_cnt <= 0;
    end else if (link_initialized && !link_initialized_delay) begin
      link_initialized_cnt <= link_initialized_cnt + 1'b1;
    end else if (!link_initialized) begin
      link_initialized_cnt <= 0;
    end
 end
*/

always @(posedge log_clk) begin
	if (log_rst_q) begin
		state <= IDLE_s;
	end
	else begin
		case (state)
		IDLE_s: begin
			if (db_req_ena || self_check_in && link_initialized) begin
				state <= DB_REQ_s;
			end
			else if (nwr_req_in && link_initialized) begin
				state <= NWR_s;
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
		end
		DB_RESP_s: begin
			if (target_ready) begin
				nwr_ready_o	<= 1'b1;
				state <= IDLE_s;
			end
			else if (target_busy) begin
				nwr_busy_o <= 1'b1;
				state <= IDLE_s;
			end
			else begin
				nwr_ready_o <= 1'b0;
				nwr_busy_o <= 1'b0;
				state <= DB_RESP_s;
			end
		end
		NWR_s: begin
			nwr_ready_o <= 1'b0;
			if (nwr_done) begin
				state <= IDLE_s	;
			end
			else begin
				state <= NWR_s;
			end
		end
		default: begin
			state <= IDLE_s;
		end
		endcase

	end
end

assign iresp_tready_o = 1'b1;
always @(posedge log_clk) begin
	if (log_rst_q) begin
		ireq_tvalid_o <= 1'b0;
		ireq_tlast_o <= 1'b0;
		ireq_tdata_o <= 1'b0;
		ireq_tkeep_o <= 'h0;
		ireq_tuser_o <= 1'b0;
		fifo_rd_en	<= 1'b0;
		nwr_byte_cnt <= 'h0;
		nwr_8byte_cnt <= 'h0;
		nwr_packect_transfer_cnt <= 'h0;
		nwr_done <= 1'b0;
		rapidIO_ready_o <= 1'b1;
		db_req_ena <= 1'b0;
	end
	else begin
		ireq_tvalid_o <= 1'b0;
		ireq_tlast_o <= 1'b0;
		ireq_tdata_o <= 1'b0;
		ireq_tkeep_o <= 8'hff;
		ireq_tuser_o <= 1'b0;
		ireq_tvalid_o <= 1'b0;
		fifo_rd_en	<= 1'b0;
		nwr_done <= 1'b0;
		rapidIO_ready_o <= 1'b1;
		case (state)
		IDLE_s: begin
			rapidIO_ready_o <= 1'b1;
			db_req_ena <= db_req_ena;
		end
		DB_REQ_s: begin
			rapidIO_ready_o <= 1'b0;
			db_req_ena <= 1'b0;
			if (ireq_tready_in) begin
				// Send self-check 
				if (~db_req_ena) begin
					ireq_tdata_o <= db_instr[63:0];
					ireq_tvalid_o <= 1'b1;
					ireq_tkeep_o <= 8'hff;
					ireq_tlast_o <= 1'b1;
					ireq_tuser_o <= {8'h0, src_id, 8'h0, des_id};	
					$display("Source->Target: Self doorbell check");
				end
				// Send data integration check
				else begin
					ireq_tdata_o <= {db_instr[63:32],db_req_inform,16'h0};
					ireq_tvalid_o <= 1'b1;
					ireq_tkeep_o <= 8'hff;
					ireq_tlast_o <= 1'b1;
					ireq_tuser_o <= {src_id, des_id};
					$display("Source->Target: Data integration doorbell reqest");
					$display("Source->Target: Address is %x",db_req_inform);
				end
			end
		end
		DB_RESP_s: begin
			rapidIO_ready_o <= 1'b0;
			db_req_ena <= 1'b0;
		end
		NWR_s: begin
			// Enable doorbell request
			db_req_ena <= 1'b1;

			rapidIO_ready_o <= 1'b0;
		
		// Once the NWR operation is done, so fifo_rd_en should be deasserted
			if (current_user_last || ireq_tlast_o) begin
				fifo_rd_en <= 1'b0;
			end
			else begin
				fifo_rd_en <= ~fifo_empty;
			end // else

			ireq_tdata_o <= (current_user_valid && current_user_first) ? {nwr_srcID, NWR, TNWR, 
						1'b0, 2'h1, 1'b0, current_user_size[7:0] , 2'h0, target_ed_addr}
						: ((current_user_valid && ~current_user_first) ? current_user_data 
						: 'h0);
			ireq_tvalid_o <= current_user_valid;
			ireq_tkeep_o <= current_user_keep;

			// In one transfer, called as packet here, the maximum length is 256 bytes.
			if (current_user_first && current_user_valid) begin
				//nwr_byte_cnt <= 'h0;
				nwr_8byte_cnt <= 'h0;
				nwr_packect_transfer_cnt <= 'h0;
			end
			else if (current_user_valid) begin
				if (nwr_8byte_cnt == 8'd31) begin
					nwr_packect_transfer_cnt <= nwr_packect_transfer_cnt + 4'h1;
					nwr_8byte_cnt <= 'h0;
				end
				else begin
					nwr_8byte_cnt <= nwr_8byte_cnt + 8'h1;  
				end
			end 
			else begin
				nwr_8byte_cnt <= nwr_8byte_cnt;
				nwr_packect_transfer_cnt <= nwr_packect_transfer_cnt;
			end

			// current_user_last means the last of the user data, so everything should be cleared, and set nwr_done
			if (current_user_last) begin
				nwr_8byte_cnt <= 'h0;
				nwr_done <= 1'b1;
			end
			if(ireq_tlast_o) begin
				ireq_tvalid_o <= 1'b0;
			end

			if (current_user_valid && current_user_first) begin
				// 256 bytes as one whole packet
				packect_transfer_times <= current_user_data[12:8];
			end
			else begin
				packect_transfer_times <= packect_transfer_times;
			end
			// Using ireq_last to indicate the packet boundary. When the number of transferred
			// packects is packect_transfer_times, the ireq_last_o depends on the actual last user data
			// flag, that is the eof bit from FIFO.
			if (nwr_packect_transfer_cnt == packect_transfer_times) begin 
				ireq_tlast_o <= current_user_last;
				
			end
			else if (nwr_8byte_cnt == 8'd31) begin  // The end of a 64-Dword packect
				ireq_tlast_o <= 1'b1;

			end
			else begin
				ireq_tlast_o <= 1'b0;
			end

/*			if (nwr_packect_transfer_cnt == packect_transfer_times && 
				nwr_8byte_cnt == current_user_size[7:0]) beginreg	nwr_done 			end
*/
/*		else begin
			    fifo_rd_en	<= 1'b0;
				ireq_tdata_o <= current_user_data;
				ireq_tkeep_o <= current_user_keep;
				ireq_tvalid_o <= current_user_valid;

				nwr_packect_transfer_cnt <= nwr_packect_transfer_cnt;
				ireq_tlast_o <= ireq_tlast_o;
				nwr_byte_cnt <= nwr_byte_cnt;

			end
			*/
		end // NWR_s:

		default: begin
			rapidIO_ready_o <= 1'b1;
		end
		endcase
	end
end
//assign fifo_rd_en = (state == NWR_s && ~fifo_empty) ? 1'b1 : 1'b0;
// One NWR opearation is done
// When the last dat in reg logic is it is nwr_done
/*asreg nwr_done _packect_transfer_cnt == packect_transfer_times && 
					((nwr_8byte_cnt[7:3] == current_user_size[7:3] - 1 && current_user_size[2:0] == 'h0)
					|| (nwr_8byte_cnt[7:3] == current_user_size[7:3] && current_user_size[2:0] != 'h0)));reg
					*/
assign nw_o = nwr_done;

always @(posedge log_clk) begin
	if (state == NWR_s && current_user_first) begin
		$display("Source->Target: Now sending NWR packet, and the length is %d", current_user_size+1);
		$display("Source->Target: The target ID is %x", target_ed_addr);
	end
end


// nwr_srcID control logic
always @(posedge log_clk ) begin
	if (log_rst_q) begin
		bit_reverse <= 'h0;
	end
	else begin
		if (nwr_done) begin
			bit_reverse <= ~bit_reverse;
		end
		else begin
			bit_reverse <= bit_reverse;
		end 
	end
end

assign nwr_srcID = {7'h0, bit_reverse};

// Target endpoint address nwr_srcID x 1M
always @(posedge log_clk) begin
	if (log_rst_q) begin
		target_ed_addr <= 'h0;
		db_req_inform <= 0;
	end
	else begin
		if (~bit_reverse) begin
			target_ed_addr <= 'h0;
			// Doorbell content is 0x0200 + n (n=0,1)
			db_req_inform <= 16'h0200 + 16'h1;  
		end
		else begin
			target_ed_addr	<= (34'h1 << 20);
			db_req_inform <= 16'h0200;
		end
	end
end

// Response signals

assign current_resp_tid   = iresp_tdata_in[63:56];
assign current_resp_ftype = iresp_tdata_in[55:52];
assign current_resp_ttype = iresp_tdata_in[51:48];
assign current_resp_size  = iresp_tdata_in[43:36];
assign current_resp_prio  = iresp_tdata_in[46:45] + 2'b01; // Response priority should be increased by 1
assign current_resp_addr  = iresp_tdata_in[33:0];
assign current_resp_db_info = iresp_tdata_in[31:16];
assign current_resp_srcid = iresp_tuser_in[31:16];

assign get_a_response =  (current_resp_ftype == DOORB && current_resp_srcid == 8'hf0 && iresp_tdata_in) ? 1'b1: 1'b0;
// Indicate the requested endpoint is ready
assign target_ready = (get_a_response && current_resp_db_info == 16'h0100) ? 1'b1: 1'b0;
assign target_busy =  (get_a_response && current_resp_db_info == 16'h01ff) ? 1'b1 : 1'b0;

always @(posedge get_a_response) begin
	//if (get_a_response) begin
	$display("Source->Target: Get a response from target and the src_id is %x.", current_resp_srcid);
	$display("Source->Target: The inform in the response is %x.",current_resp_db_info);
/*		if (target_ready) begin
			$display("Source->Target: The target endpoint is ready.");
		end
		else if (target_busy) begin
			$display("Source->Target: The target endpoint is busy.");
		end
	//end
*/
end

always @(posedge target_ready) begin
	$display("Source->Target: The target endpoint is ready.");
end
always @(posedge target_ready) begin
	$display("Source->Target: The target endpoint is busy.");
end	

/*
1. consider about the relationship of user size and packet size
2. the times of a whole packet transfer and the remaining transfer
3. update the nwr_srcID
*/


assign nwr_advance_condition = ireq_tready_in && ireq_tvalid_o && (state == NWR_s);

always @(posedge log_clk) begin
	if (log_rst_q) begin
		nwr_first_beat <= 1'b1;
	end
	else begin
		if (nwr_advance_condition && ireq_tlast_o) begin
			nwr_first_beat <= 1'b1;
		end
		else if (nwr_advance_condition) begin
			nwr_first_beat <= 1'b0;
		end
	end
end

//Logic for user data

assign user_tready_o = ~fifo_full;
assign fifo_clk = log_clk;
assign fifo_rst = log_rst_q;
assign fifo_din = {user_tvalid_r, fifo_data_first, user_tkeep_r, user_tlast_r, user_tdata_r};
assign fifo_wr_en = user_tvalid_r;

assign current_user_valid = fifo_dout[74];
assign current_user_first = fifo_dout[73];
assign current_user_keep = fifo_dout[72:65];
assign current_user_last = fifo_dout[64];
assign current_user_data = fifo_dout[63:0];


/*
always @(posedge log_clk) begin
	if (log_rst_q) begin
		current_user_size <= 'h0;
	end
	else begin
		if (user_data_first) begin
			current_user_size <= user_tdata_r[11:0] ; // The maximum transter length is 256 bytes, equal to 64 Dwords
		end
		else begin
			current_user_size <= current_user_size;
		end
	end
end
*/

assign current_user_size = (user_data_first) ? user_tdata_r[7:0]  : current_user_size;

//assign packect_transfer_times = current_user_size[11:8];
assign byte_left = current_user_size[7:0];

always @(posedge fifo_clk) begin
	if (fifo_rst) begin
		user_tvalid_r <= 1'b0;
		user_tdata_r <= 1'b0;
		user_tlast_r <= 1'b0;
		user_tkeep_r <= 'h0;
	end
	else begin
		user_tvalid_r <= user_tvalid_in;
		user_data_first <= ~user_tvalid_r & user_tvalid_in;

		fifo_data_first	<= ~user_tvalid_r & user_tvalid_in;

		user_tdata_r <= user_tdata_in;
		user_tkeep_r <= user_tkeep_in;
		user_tlast_r <= user_tlast_in;
	end
end

fifo_75x512 user_data_fifo (
  .clk(fifo_clk),                // input wire clk
  .srst(fifo_rst),              // input wire srst
  .din(fifo_din),                // input wire [65 : 0] din
  .wr_en(fifo_wr_en),            // input wire wr_en
  .rd_en(fifo_rd_en),            // input wire rd_en
  .dout(fifo_dout),              // output wire [65 : 0] dout
  .full(fifo_full),              // output wire full
  .empty(fifo_empty),            // output wire empty
  .data_count(fifo_data_cnt)  // output wire [8 : 0] data_count
);
endmodule

