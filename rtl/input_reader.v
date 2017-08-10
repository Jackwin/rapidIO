`timescale 1ns/1ns
module input_reader # (
    parameter DATA_WIDTH = 64,
    parameter DATA_LENGTH_WIDTH = 20,
    parameter RAM_ADDR_WIDTH = 10
    )
(
    input clk,    // Clock
    input clk_en, // Clock Enable
    input reset,

    input [DATA_WIDTH-1:0] data_in,
    input data_valid_in,
    input [DATA_WIDTH/8-1:0] data_keep_in,
    input [DATA_LENGTH_WIDTH-1:0] data_len_in,
    input data_last_in,
    output data_ready_out,
    output ack_o,

    input fetch_data_in,
    input output_tready,
    output reg [DATA_WIDTH-1:0] output_tdata,
    output reg output_tvalid,
    output reg [DATA_WIDTH/8-1:0] output_tkeep,
    output wire output_tlast
);

reg [DATA_LENGTH_WIDTH-1:0] data_len_r1, data_len_r2, data_len_reg;
reg data_valid_r1, data_valid_r2, data_valid_p;
reg [DATA_WIDTH-1:0] data_in_r1, data_in_r2;
reg [1:0] data_last_r;
wire data_tfirst, data_tlast, data_tvalid;
reg [DATA_WIDTH/8-1:0] data_keep_r1, data_keep_r2;

//Counter signals

// FIFO signals
localparam MEM_DPTH = 2**RAM_ADDR_WIDTH;
reg [DATA_WIDTH+5+8-1:0] mem[MEM_DPTH-1:0];
reg [DATA_WIDTH+5+8-1:0] rd_data_reg, rd_data;
wire [DATA_WIDTH+5+8-1:0] wr_data;
reg [RAM_ADDR_WIDTH:0] wr_ptr_reg, wr_ptr_next, rd_ptr_reg, rd_ptr_next;
reg rd_data_valid_next, rd_data_valid_reg;

wire full = ((wr_ptr_reg[RAM_ADDR_WIDTH] != rd_ptr_reg[RAM_ADDR_WIDTH])
            && (wr_ptr_reg[RAM_ADDR_WIDTH-1:0] == rd_ptr_reg[RAM_ADDR_WIDTH-1:0]));
wire empty = (wr_ptr_reg == rd_ptr_reg);
reg write;
// The last written packet
wire wr_tail;
reg read;

reg rd_data_valid;


// Data length signals. 256-byte data is called as PACKET
reg [DATA_LENGTH_WIDTH-3-1:0] counter;
wire counter_ena, counter_reset;
wire wr_pack_tfirst, wr_pack_tlast;
wire rd_data_tfirst, rd_data_tlast, rd_pack_tfirst, rd_pack_tlast;
reg rd_pack_valid;
wire [DATA_WIDTH/8:0] rd_pack_tkeep;
reg [DATA_LENGTH_WIDTH-1-8:0] trans_256B_times_reg, trans_256B_times;
reg [7:0] pad_length_reg, pad_length;
reg [7:0] rounded_length_reg, rounded_length;
reg [7:0] trans_tail_length, trans_tail_length_reg;
reg [DATA_LENGTH_WIDTH-1-8:0] pack_cnt;
wire pack_reset;

//Output
reg output_strobe;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        {data_valid_r1, data_valid_r1} <= 2'h0;
        data_valid_p <= 1'b0;
        data_len_r1 <= 'h0;
        data_len_r2 <= 'h0;
        data_last_r <= 'h0;
        data_in_r1 <= 'h0;
        data_in_r2 <= 'h0;
        data_keep_r1 <= 'h0;
        data_keep_r2 <= 'h0;
    end
    else begin
        data_valid_r1 <= data_valid_in;
        data_valid_r2 <= data_valid_r1;
        data_valid_p <= data_valid_in & ~data_valid_r1;
        data_len_r1 <= data_len_in;
        data_len_r2 <= data_len_r1;
        data_last_r[1:0] <= {data_last_r[0], data_last_in};
        data_in_r1 <= data_in;
        data_in_r2 <= data_in_r1;
        data_keep_r1 <= data_keep_in;
        data_keep_r2 <= data_keep_r1;
    end
end
assign data_tfirst = data_valid_p;
assign data_tlast  = data_last_r[1];
assign data_tvalid  = data_valid_r2;
assign wr_data = wr_tail ? {data_in_r2, data_keep_r2, data_tfirst, data_tlast,
                wr_pack_tfirst, wr_pack_tlast}
                : {64'h0, 8'h0, 1'b0, (counter[4:0] == trans_tail_length), 1'b0, (counter[4:0] == trans_tail_length)};

// Data length process
always @(posedge clk) begin
    if (reset) begin
        data_len_reg <= 'h0;
    end
    else begin
        if (data_tfirst) begin
            data_len_reg <= data_len_r1;
        end
    end
end

always @* begin
    transLengthComp(data_len_r1, trans_256B_times, pad_length, rounded_length);
end


always @(posedge clk) begin
    if (reset) begin
        trans_256B_times_reg <= 'hff;
        pad_length_reg <= 'h0;
        rounded_length_reg <= 'h0;
        trans_tail_length_reg <= 'h0;
    end
    else begin
        if (data_tfirst) begin
            trans_256B_times_reg <= trans_256B_times;
            pad_length_reg <= pad_length;
            //rounded_length_reg <= rounded_length;
            trans_tail_length_reg <= rounded_length;
        end
    end
end

// 256-byte Package

always @(posedge clk) begin
    if (reset) begin
        counter <= 'h0;
    end
    else begin
        if (counter_reset) begin
            counter <= 'h0;
        end
        else if (counter_ena) begin
            counter <= counter + 'h1;
        end
    end
end

//Flag of unused data writtten to RAM
assign wr_tail = (counter[DATA_LENGTH_WIDTH-3-1:0] == trans_256B_times_reg
                && (counter[4:0] > trans_tail_length)) ? 1'b1 : 1'b0;

assign wr_pack_tfirst = (counter_ena == 1'b1 && counter[4:0] == 'h0) ? 1'b1 : 1'b0;
assign wr_pack_tlast = (counter_ena == 1'b1 && counter == 'h1f) ? 1'b1 : 1'b0;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        pack_cnt <= 'h0;
    end
    else begin
        if (rd_data_tlast) begin
            pack_cnt <= 'h0;
        end
        else if (rd_pack_tlast) begin
            pack_cnt <= pack_cnt + 'h1;
        end
    end
end

always @(posedge clk ) begin
    if (reset) begin
        rd_pack_valid <= 1'b0;
    end
    else begin
        if (rd_pack_tfirst) begin
            rd_pack_valid <= 1'b1;
        end
        else if (rd_pack_tlast) begin
            rd_pack_valid <= 1'b0;
        end
        else begin
            rd_pack_valid <= rd_pack_valid;
        end
    end
end

always @* begin
    if (pack_cnt != trans_256B_times_reg) begin
        output_tkeep = {(DATA_WIDTH/8){1'b1}};
    end
    else begin
        if (rd_pack_valid) begin
            output_tkeep = rd_pack_tkeep;
        end
        else begin
            output_tkeep = {(DATA_WIDTH/8){1'b0}};
        end
    end
end

assign output_tlast = rd_pack_tlast;

always @* begin
    if (pack_cnt != trans_256B_times_reg && rd_pack_tfirst) begin
        output_tdata = 'hff;
    end
    else if (pack_cnt == trans_256B_times_reg && rd_pack_tfirst) begin
        output_tdata = rounded_length;
    end
end

// Write FIFO
always @* begin
    write = 1'b0;
    wr_ptr_next = wr_ptr_reg;
    if ((data_tvalid && ~full) || wr_tail ) begin
        write = 1'b1;
        wr_ptr_next = wr_ptr_reg + 'h1;
    end
end

always @(posedge clk or posedge reset) begin
    if(reset) begin
        wr_ptr_reg  <= 0;
    end
    else begin
        wr_ptr_reg  <= wr_ptr_next;
       if (write) begin
                mem[wr_ptr_reg[RAM_ADDR_WIDTH-1:0]] <= wr_data;
         end
    end
end

// Read FIFO

//assign read = output_tready && fetch_data_in && ~empty ;

always @* begin
    rd_ptr_next = rd_ptr_reg;
    read = 1'b0;
    rd_data_valid_next = rd_data_valid_reg;

    if (output_strobe | ~rd_data_valid_reg) begin
        if (~empty) begin
            read = 1'b1;
            rd_ptr_next = rd_ptr_reg + 'h1;
            rd_data_valid_next = 1'b1;
        end
        else begin
            rd_data_valid_next <= 1'b0;
        end
    end
end

reg [7:0] rd_data_cnt;

always @(posedge clk) begin
    if (reset) begin
        rd_data_cnt <= 'h0;
    end
    else begin
        if (rd_data_tlast) begin
            rd_data_cnt <= 'h0;
        end
        else if (read) begin
            rd_data_cnt <= rd_data_cnt + 'h1;
        end
    end
end

always @(posedge clk) begin
    if (reset) begin
        rd_ptr_reg  <= 'h0;
        rd_data_valid_reg <= 1'b0;
        rd_data <= 'h0;
    end
    else begin
        rd_ptr_reg <= rd_ptr_next;
        rd_data_valid_reg <= rd_data_valid_next;
        if (read) begin
            rd_data <= mem[rd_ptr_reg[RAM_ADDR_WIDTH-1:0]];
        end
    end
end

assign rd_data_tfirst = rd_data[3];
assign rd_data_tlast = rd_data[2];
assign rd_pack_tfirst  = rd_data[1];
assign rd_pack_tlast = rd_data[0];
assign rd_pack_tkeep = rd_data[11:4];


task transLengthComp;
    input [19:0] data_length_in; // in the size of byte, the number of bytes in the transfer minus one
    output [11:0] trans_256B_times; // times of 256B transaction
    output [7:0] pad_length; // the data added to round up to the closest boundary
    output [7:0] rounded_length;  // the closest supported value
    begin
        trans_256B_times = data_length_in[19:8];
        casex(data_length_in[7:0])
            8'b00000xxx: begin
                pad_length = 7 - data_length_in[2:0];
                rounded_length = 8'd8;
            end // 20'b00000000000000000xxx:
            8'b00001xxx: begin
                pad_length = 15 - data_length_in[3:0];
                rounded_length = 8'd16;
            end // 20'b00000000000000001xxx:
            8'b0001xxxx: begin
                pad_length = 31 - data_length_in[4:0];
                rounded_length = 8'd32;
            end
            8'b001xxxxx: begin
                pad_length = 63 - data_length_in[5:0];
                rounded_length = 8'd64;
            end
            8'b01xxxxxx: begin
                pad_length = 127 - data_length_in[6:0];
                rounded_length = 8'd128;
            end
            8'b1xxxxxxx: begin
                pad_length = 255 - data_length_in[7:0];
                rounded_length = 8'd256;
            end
            default: begin
                pad_length = 'h0;
                rounded_length = 'h0;
            end
        endcase
    end
endtask



endmodule