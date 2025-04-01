module my_ddr_test(
	input  wire [4:0]   okUH,
	output wire [2:0]   okHU,
	inout  wire [31:0]  okUHU,
	inout  wire         okAA,

	input  wire         sys_clk_p,
	input  wire         sys_clk_n,
	
	output wire [7:0]   led,
	
	inout  wire [31:0]  ddr3_dq,
	output wire [14:0]  ddr3_addr,
	output wire [2 :0]  ddr3_ba,
	output wire [0 :0]  ddr3_ck_p,
	output wire [0 :0]  ddr3_ck_n,
	output wire [0 :0]  ddr3_cke,
	// output wire [0 :0]  ddr3_cs_n,
	output wire         ddr3_cas_n,
	output wire         ddr3_ras_n,
	output wire         ddr3_we_n,
	output wire [0 :0]  ddr3_odt,
	output wire [3 :0]  ddr3_dm,
	inout  wire [3 :0]  ddr3_dqs_p,
	inout  wire [3 :0]  ddr3_dqs_n,
	output wire         ddr3_reset_n
	);

wire          init_calib_complete;
//reg           sys_rst;

wire	[30 - 1:0]	app_addr;
wire	[3 - 1:0] 	app_cmd;
wire	         	app_en;
wire	         	app_rdy;
wire	[256 - 1:0] app_rd_data;
wire	         	app_rd_data_end;
wire	         	app_rd_data_valid;
wire	[256 - 1:0] app_wdf_data;
wire	         	app_wdf_end;
wire	[32 - 1:0]  app_wdf_mask;
wire	         	app_wdf_rdy;
wire	         	app_wdf_wren;

wire          		ui_clk;
wire          		ui_rst;

// Target interface bus:
wire         	okClk;
wire 	[112:0]	okHE;
wire 	[64:0]  okEH;

// Endpoint connections:
wire 	[32 - 1:0]  ep00wire;  // rstn

wire				rstn = ep00wire[0];
wire				rst = ~rstn;

wire	[32 - 1:0]	pipe_in_data;
wire				pipe_in_valid;
reg					pipe_in_ready;

wire				pipe_out_read;
wire	[32 - 1:0]	pipe_out_data = out_fifo_dout;
reg					pipe_out_ready;

// Signals
wire				in_fifo_full;
wire				in_fifo_wr_en = pipe_in_valid;
wire	[32 - 1:0]	in_fifo_din = pipe_in_data;
wire				in_fifo_empty;
wire				in_fifo_rd_en;
wire	[256 - 1:0]	in_fifo_dout;
wire				in_fifo_dout_valid;
wire	[10 - 1:0]	in_fifo_wr_data_count;
wire	[7 - 1:0]	in_fifo_rd_data_count;

wire				out_fifo_full;
wire				out_fifo_wr_en;
wire	[128 - 1:0]	out_fifo_din;
wire				out_fifo_empty;
wire				out_fifo_rd_en = pipe_out_read;
wire	[32 - 1:0]	out_fifo_dout;
wire				out_fifo_dout_valid;
wire	[7 - 1:0]	out_fifo_wr_data_count;
wire	[9 - 1:0]	out_fifo_rd_data_count;


function [7:0] xem7310_led;
input [7:0] a;
integer i;
begin
	for(i=0; i<8; i=i+1) begin: u
		xem7310_led[i] = (a[i]==1'b1) ? (1'b0) : (1'bz);
	end
end
endfunction

assign led = xem7310_led({4'b0, in_fifo_empty, out_fifo_empty, app_wdf_rdy, init_calib_complete});
// assign led = xem7360_led(in_fifo_dout[3:0]);

always @(posedge okClk) begin
	if(in_fifo_wr_data_count <= (10'd1000)) begin
		pipe_in_ready <= 1'b1;
	end
	else begin
		pipe_in_ready <= 1'b0;
	end
end

always @(posedge okClk) begin
	if(out_fifo_rd_data_count >= 9'd4) begin
		pipe_out_ready <= 1'b1;
	end
	else begin
		pipe_out_ready <= 1'b0;
	end
end

// MIG User Interface instantiation
// ddr3_512_32 u_ddr3_256_16 (
mig_7series_0 u_mig_7series_0 (
	// Memory interface ports
	.ddr3_addr                      (ddr3_addr),
	.ddr3_ba                        (ddr3_ba),
	.ddr3_cas_n                     (ddr3_cas_n),
	.ddr3_ck_n                      (ddr3_ck_n),
	.ddr3_ck_p                      (ddr3_ck_p),
	.ddr3_cke                       (ddr3_cke),
	.ddr3_ras_n                     (ddr3_ras_n),
	.ddr3_reset_n                   (ddr3_reset_n),
	.ddr3_we_n                      (ddr3_we_n),
	.ddr3_dq                        (ddr3_dq),
	.ddr3_dqs_n                     (ddr3_dqs_n),
	.ddr3_dqs_p                     (ddr3_dqs_p),
	.init_calib_complete            (init_calib_complete),
	
	// .ddr3_cs_n                      (ddr3_cs_n),
	.ddr3_dm                        (ddr3_dm),
	.ddr3_odt                       (ddr3_odt),
	// Application interface ports
	.app_addr                       (app_addr),
	.app_cmd                        (app_cmd),
	.app_en                         (app_en),
	.app_wdf_data                   (app_wdf_data),
	.app_wdf_end                    (app_wdf_end),
	.app_wdf_wren                   (app_wdf_wren),
	.app_rd_data                    (app_rd_data),
	.app_rd_data_end                (app_rd_data_end),
	.app_rd_data_valid              (app_rd_data_valid),
	.app_rdy                        (app_rdy),
	.app_wdf_rdy                    (app_wdf_rdy),
	.app_sr_req                     (1'b0),
	.app_sr_active                  (),
	.app_ref_req                    (1'b0),
	.app_ref_ack                    (),
	.app_zq_req                     (1'b0),
	.app_zq_ack                     (),
	.ui_clk                         (ui_clk),
	.ui_clk_sync_rst                (ui_rst),
	
	.app_wdf_mask                   (app_wdf_mask),
	
	// System Clock Ports
	.sys_clk_p                      (sys_clk_p),
	.sys_clk_n                      (sys_clk_n),
	
	.sys_rst                        (rst)
);

mig_controller u_mig_controller(
	.sys_clk(ui_clk),
	.rst(rst),
	.calib_done(init_calib_complete),
	
	.ib_re(in_fifo_rd_en),
	.ib_data(in_fifo_dout),
	.ib_count(in_fifo_rd_data_count),
	.ib_valid(in_fifo_dout_valid),
	.ib_empty(in_fifo_empty),

	.ob_we(out_fifo_wr_en),
	.ob_data(out_fifo_din),
	.ob_count(out_fifo_wr_data_count),
	.ob_full(out_fifo_full),

	.app_rdy(app_rdy),
	.app_en(app_en),
	.app_cmd(app_cmd),
	.app_addr(app_addr),

	.app_rd_data(app_rd_data),
	.app_rd_data_end(app_rd_data_end),
	.app_rd_data_valid(app_rd_data_valid),

	.app_wdf_rdy(app_wdf_rdy),
	.app_wdf_wren(app_wdf_wren),
	.app_wdf_data(app_wdf_data),
	.app_wdf_end(app_wdf_end),
	.app_wdf_mask(app_wdf_mask)
);

fifo_w32_1024_r256_128 u_fifo_w32_1024_r256_128(
    .rst(rst),
    // write
    .wr_clk(okClk),
    .full(in_fifo_full),
    .wr_en(in_fifo_wr_en),
    .din(in_fifo_din),
    // read
    .rd_clk(ui_clk),
    .empty(in_fifo_empty),
    .rd_en(in_fifo_rd_en),
    .dout(in_fifo_dout),
    .valid(in_fifo_dout_valid),
    // status
    .wr_data_count(in_fifo_wr_data_count),
    .rd_data_count(in_fifo_rd_data_count)
);

fifo_w128_128_r32_512 u_fifo_w128_128_r32_512(
    .rst(rst),
    // write
    .wr_clk(ui_clk),
    .full(out_fifo_full),
    .wr_en(out_fifo_wr_en),
    .din(out_fifo_din),
    // read
    .rd_clk(okClk),
    .empty(out_fifo_empty),
    .rd_en(out_fifo_rd_en),
    .dout(out_fifo_dout),
    .valid(out_fifo_dout_valid),
    // status
    .wr_data_count(out_fifo_wr_data_count),
    .rd_data_count(out_fifo_rd_data_count)
);

// Instantiate the okHost and connect endpoints.
wire [65 * 2 - 1:0]  okEHx;

okHost okHI(
	.okUH(okUH),
	.okHU(okHU),
	.okUHU(okUHU),
	.okAA(okAA),
	.okClk(okClk),
	.okHE(okHE),
	.okEH(okEH)
);

okWireOR # (.N(2)) wireOR (okEH, okEHx);

okWireIn    ep00        (.okHE(okHE),                               .ep_addr(8'h00), .ep_dataout(ep00wire));

okBTPipeIn  BTPipeIn80  (.okHE(okHE),   .okEH(okEHx[0 * 65 +: 65]), .ep_addr(8'h80), .ep_dataout(pipe_in_data), .ep_write(pipe_in_valid),   .ep_blockstrobe(),  .ep_ready(pipe_in_ready));
okBTPipeOut BTPipeOutA0 (.okHE(okHE),   .okEH(okEHx[1 * 65 +: 65]), .ep_addr(8'hA0), .ep_datain(pipe_out_data), .ep_read(pipe_out_read),    .ep_blockstrobe(),  .ep_ready(pipe_out_ready));

endmodule