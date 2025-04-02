module pipe_speedtest(
    input   wire [4:0]  okUH,
    output  wire [2:0]  okHU,
    inout   wire [31:0] okUHU,
    inout   wire        okAA,

    input   wire        sys_clk_p,
    input   wire        sys_clk_n,

    output  wire [7:0]  led
);

IBUFGDS osc_clk(.O(sys_clk), .I(sys_clk_p), .IB(sys_clk_n));

// Target interface bus
wire            okClk;
wire [112:0]    okHE;
wire [64:0]     okEH;

// Endpoint connections
wire [32 - 1:0] ep00wire;  // rstn
wire [32 - 1:0] pipe_in_data; 
wire pipe_in_valid;
wire pipe_out_read;
wire [32 - 1:0] pipe_out_data;

function [7:0] xem7310_led;
input [7:0] a;
integer i;
begin
    for(i = 0; i < 8; i = i + 1) begin
        xem7310_led[i] = (a[i] == 1'b1) ? 1'b0 : 1'bz;
    end
end
endfunction

assign led = xem7310_led(8'b0);

// Signals
wire rstn = ep00wire[0];

wire p2f_fifo_wr_en = pipe_in_valid;
wire [32 - 1:0] p2f_fifo_din = pipe_in_data;
wire p2f_fifo_empty;
reg p2f_fifo_rd_en;

always @(posedge sys_clk) begin
    if(!rstn) begin
        p2f_fifo_rd_en <= 1'b0;
    end
    else begin
        if(!p2f_fifo_empty) begin
            p2f_fifo_rd_en <= 1'b1;
        end
        else begin
            p2f_fifo_rd_en <= 1'b0;
        end
    end
end

fifo_w32_1024_r128_256 P2F_FIFO(
    .rst(rst),
    // write
    .wr_clk(okClk),
    .wr_en(p2f_fifo_wr_en),
    .din(p2f_fifo_din),
    .full(),
    // read
    .rd_clk(sys_clk),
    .rd_en(p2f_fifo_rd_en),
    .dout(),
    .empty(p2f_fifo_empty),
    .valid()
);

reg f2p_fifo_wr_en;
reg [128 - 1:0] f2p_fifo_din;
wire f2p_fifo_rd_en = pipe_out_read;
wire [32 - 1:0] f2p_fifo_dout;
wire f2p_fifo_full;

assign pipe_out_data = f2p_fifo_dout;

always @(posedge sys_clk) begin
    if(!rstn) begin
        f2p_fifo_wr_en <= 1'b0;
    end
    else begin
        if(!f2p_fifo_full) begin
            f2p_fifo_wr_en <= 1'b1;
        end
        else begin
            f2p_fifo_wr_en <= 1'b0;
        end
    end
end

always @(posedge sys_clk) begin
    if(!rstn) begin
        f2p_fifo_din <= 128'b0;
    end
    else begin
        // f2p_fifo_din <= f2p_fifo_din + 1'b1;
        if(f2p_fifo_wr_en) begin
            f2p_fifo_din <= f2p_fifo_din + 1'b1;
        end
    end
end

fifo_w128_256_r32_1024 F2P_FIFO(
    .rst(rst),
    // write
    .wr_clk(sys_clk),
    .wr_en(f2p_fifo_wr_en),
    .din(f2p_fifo_din),
    .full(f2p_fifo_full),
    // read
    .rd_clk(okClk),
    .rd_en(f2p_fifo_rd_en),
    .dout(f2p_fifo_dout),
    .empty(),
    .valid()
);

// Instantiate the okHost and connect endpoints
wire [65 * 2 - 1:0] okEHx;

okHost okHI(
	.okUH(okUH),
	.okHU(okHU),
	.okUHU(okUHU),
	.okAA(okAA),
	.okClk(okClk),
	.okHE(okHE), 
	.okEH(okEH)
);

okWireOR #(.N(2)) wireOR (okEH, okEHx);

okWireIn     ep00     (.okHE(okHE),                             .ep_addr(8'h00), .ep_dataout(ep00wire));
okPipeIn     pipeIn80 (.okHE(okHE), .okEH(okEHx[0 * 65 +: 65]), .ep_addr(8'h80), .ep_dataout(pipe_in_data), .ep_write(pipe_in_valid));
okPipeOut    pipeOutA0(.okHE(okHE), .okEH(okEHx[1 * 65 +: 65]), .ep_addr(8'ha0), .ep_datain(pipe_out_data), .ep_read(pipe_out_read));

endmodule