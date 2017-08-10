`timescale 1ns/1ns
module input_reader_tb();

localparam DATA_WIDTH = 64;
localparam DATA_LENGTH_WIDTH = 20;
localparam RAM_ADDR_WIDTH = 10;
logic log_clk;
logic log_rst;
logic [DATA_WIDTH-1:0] data_gen;
logic  data_gen_valid;
logic [DATA_WIDTH/8-1:0] data_gen_tkeep;
logic [DATA_LENGTH_WIDTH-1:0] data_gen_len;
logic data_gen_tlast;
logic data_ready_out;

initial begin
    log_clk = 0;
forever
    #5 log_clk  = ~log_clk;
end // initial

initial  begin
    log_rst = 1;
    #38;
    log_rst = 0;
end // initial

initial begin
    data_gen = 'h0;
    data_gen_valid = 'h0;
    data_gen_tlast = 'h0;
    data_gen_tkeep = 'h0;
    data_gen_len = 'h0;
    # 350;
    for(integer k = 0; k < 267; k++) begin
        @(posedge log_clk);
        data_gen_len = 'd268;
        data_gen_valid = 1'b1;
        data_gen = data_gen + 'h1;
        data_gen_tkeep = 'hff;
    end
    data_gen_tlast = 'h1;
    data_gen_tkeep = 'hff;
    @(posedge log_clk);
    data_gen_valid = 'h0;
    data_gen_tlast = 'h0;
    data_gen_tkeep = 'h0;
    $stop;

end

 input_reader # (
    .DATA_WIDTH(DATA_WIDTH),
    .DATA_LENGTH_WIDTH(DATA_LENGTH_WIDTH),
    .RAM_ADDR_WIDTH(RAM_ADDR_WIDTH)
    )
input_reader_i (
    .clk(log_clk),    // Clock
    .reset(log_rst),

    .data_in(data_gen),
    .data_valid_in(data_gen_valid),
    .data_keep_in(data_gen_tkeep),
    .data_len_in(data_gen_len),
    .data_last_in(data_gen_tlast),
    .data_ready_out(),
    .ack_o(),

    .fetch_data_in(),
    .output_tready(),
    .output_tdata(),
    .output_tvalid(),
    .output_tkeep(),
    .output_tlast()
);

endmodule // input_reader
