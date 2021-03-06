`timescale 1ns/1ns

module db_req_tb();

	logic log_clk;
	logic log_rst;
	logic [15:0] req_src_id = 16'h01;
	logic [15:0] req_des_id = 16'hf0;

	logic dr_req_in;
	logic nwr_req_in;
	logic rapidIO_ready;
	logic link_initialized;

	logic nwr_ready_o;
	logic nwr_busy_o;

	logic go;
	logic [33:0] user_addr;
    logic [3:0] user_ftype;
    logic [3:0] user_ttype;
    logic [7:0] user_size;

    logic [63:0] user_tdata_in;
    logic user_tvalid_in;
    logic [7:0] user_tkeep_in;
    logic user_tlast_in;

    logic [11:0] user_tsize_in;
    logic user_tready_o;

	logic ireq_tvalid_o;
	logic ireq_tready_in;
	logic ireq_tlast_o;
	logic [63:0]	ireq_tdata_o;
	logic [7:0] 	ireq_tkeep_o;	
	logic [31:0] 	ireq_tuser_o;

    logic         iresp_tvalid;
    logic       iresp_tready;
    logic             iresp_tlast;
    logic      [63:0] iresp_tdata;
    logic       [7:0] iresp_tkeep;
    logic      [31:0] iresp_tuser;	

    // Response endpoint signals
	logic [15:0] resp_src_id = 16'hf0;
	logic [15:0] resp_des_id = 16'h01;    

    logic resp_ed_ready;
    logic treq_tvalid_in;
    logic treq_tready_o;
    logic treq_tlast_in;
    logic [63:0] treq_tdata_in;
    logic [7:0] treq_tkeep_in;
    logic [31:0] treq_tuser_in;

    logic          tresp_tready_in;
    logic          tresp_tvalid_o;
    logic          tresp_tlast_o;
    logic [63:0]   tresp_tdata_o;
    logic [7:0]    tresp_tkeep_o;
    logic [31:0]   tresp_tuser_o;


    initial begin
    	log_clk	= 0;
    	forever
    	#5 log_clk	= ~log_clk;
    end // initial

    initial	 begin
    	log_rst	= 1;
    	#38;
    	log_rst	= 0;
    end // initial

    initial	 begin
    	dr_req_in <= 0;
    	nwr_req_in <= 0;

    	#200;
    	@(posedge log_clk) begin
    		if (rapidIO_ready) begin
    			dr_req_in <= 1;
    			$display("Tb:Doorbell is requesting",);
    		end // if (rapidIO_ready)
    	end
    	@(posedge log_clk);
    	dr_req_in <= 0;

    	wait (nwr_ready_o);
    	@(posedge log_clk);
    	nwr_req_in <= 1;
    	@(posedge log_clk);
    	nwr_req_in <= 0;	
    end // initial



	 db_req db_req_i(
	 .log_clk(log_clk),
	 .log_rst(log_rst),

	 .src_id(req_src_id),
	 .des_id(req_des_id),

	.self_check_in(dr_req_in),
	 .nwr_req_in(nwr_req_in),
	 .rapidIO_ready_o (rapidIO_ready),
	.link_initialized(link_initialized),

	.nwr_ready_o(nwr_ready_o),
	.nwr_busy_o(nwr_busy_o),

	.go(go),
	.user_addr(user_addr),
    .user_ftype(user_ftype),
    .user_ttype(user_ttype),


    .user_tdata_in(user_tdata_in),
    .user_tvalid_in(user_tvalid_in),
    .user_tkeep_in(user_tkeep_in),
    .user_tlast_in(user_tlast_in),
    //Byte length
    .user_tsize_in(user_tsize_in), 
    .user_tready_o(user_tready_o),

	.ireq_tvalid_o(ireq_tvalid_o),
	.ireq_tready_in(ireq_tready_in),
	.ireq_tlast_o(ireq_tlast_o),
	.ireq_tdata_o(ireq_tdata_o),
	.ireq_tkeep_o(ireq_tkeep_o),	
	.ireq_tuser_o(ireq_tuser_o),

    .iresp_tvalid_in(iresp_tvalid),
    .iresp_tready_o(iresp_tready),
    .iresp_tlast_in(iresp_tlast),
    .iresp_tdata_in(iresp_tdata),
    .iresp_tkeep_in(iresp_tkeep),
    .iresp_tuser_in(iresp_tuser)	
	);

always_comb begin
    treq_tvalid_in = ireq_tvalid_o;
    treq_tlast_in = ireq_tlast_o;
    treq_tdata_in = ireq_tdata_o;
    treq_tkeep_in = ireq_tkeep_o;
    treq_tuser_in = ireq_tuser_o;
    ireq_tready_in = treq_tready_o;

    tresp_tready_in = 1;    

    iresp_tvalid = tresp_tvalid_o;
    tresp_tready_in = iresp_tready;
    iresp_tlast = tresp_tlast_o;
    iresp_tdata = tresp_tdata_o;
    iresp_tkeep = tresp_tkeep_o;
    iresp_tuser = tresp_tuser_o;
end

 db_resp db_resp_i
(
	.log_clk(log_clk),
	.log_rst(log_rst),

	.src_id(resp_src_id),
	.des_id(resp_des_id),

	.ed_ready_in(2'b1),

	.treq_tready_o(treq_tready_o),
    .treq_tvalid_in(treq_tvalid_in),
	.treq_tlast_in(treq_tlast_in),
	.treq_tdata_in(treq_tdata_in),
	.treq_tkeep_in(treq_tkeep_in),
	.treq_tuser_in(treq_tuser_in),

	// response interface
	.tresp_tready_in(tresp_tready_in),
	.tresp_tvalid_o(tresp_tvalid_o),
	.tresp_tlast_o(tresp_tlast_o),
	.tresp_tdata_o(tresp_tdata_o),
	.tresp_tkeep_o(tresp_tkeep_o),	
	.tresp_tuser_o(tresp_tuser_o)
	);

user_logic user_logic_i (

    .log_clk(log_clk),
    .log_rst(log_rst),

    .nwr_ready_in(nwr_ready_o),
    .nwr_busy_in(nwr_busy_o),

    .user_tready_in(user_tready_o),
    .user_addr_o(user_addr),
    .user_ftype_o(),
    .user_ttype_o(),
    .user_tsize_o(user_tsize_in),

    .user_tdata_o(user_tdata_in),
    .user_tvalid_o(user_tvalid_in),
    .user_tkeep_o(user_tkeep_in),
    .user_tlast_o(user_tlast_in)

    );

endmodule // db_req_tb