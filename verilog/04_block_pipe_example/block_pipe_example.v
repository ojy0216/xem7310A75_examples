module block_pipe_example(
    input   wire [4:0]  okUH,
    output  wire [2:0]  okHU,
    inout   wire [31:0] okUHU,
    inout   wire        okAA,
    
    output  wire [7:0]  led
);

// Target interface bus
wire            okClk;
wire [112:0]    okHE;
wire [64:0]     okEH;

// Endpoint connections
wire [32 - 1:0] ep00wire;  // rstn
wire [32 - 1:0] block_pipe_in_data; 
wire block_pipe_in_valid;
wire block_pipe_out_read;
reg [32 - 1:0] block_pipe_out_data;

function [7:0] xem7310_led;
input [7:0] a;
integer i;
begin
    for(i = 0; i < 8; i = i + 1) begin
        xem7310_led[i] = (a[i] == 1'b1) ? 1'b0 : 1'bz;
    end
end
endfunction

// Signals
wire rstn = ep00wire[0];

reg [2 - 1:0] store_idx;
reg [2 - 1:0] read_idx;
reg [128 - 1:0] data_store;  // 16 byte = 128 bit

always @(posedge okClk) begin
    if(!rstn) begin
        store_idx <= 2'd3;
    end
    else if(block_pipe_in_valid) begin
        store_idx <= store_idx - 1'b1;
    end

    if(store_idx == 2'd0) begin
        store_idx <= 2'd3;
    end
end

always @(posedge okClk) begin
    if(!rstn) begin
        data_store <= 128'b0;
    end
    else if(block_pipe_in_valid) begin
        data_store[32 * store_idx +: 32] <= block_pipe_in_data;  // [15, 14, ..., 2, 1, 0]
    end
end

assign led = xem7310_led(data_store[7:0]);

always @(posedge okClk) begin
    if(!rstn) begin
        read_idx <= 2'd3;
    end
    else if(block_pipe_out_read) begin
        read_idx <= read_idx - 1'b1;
    end

    if(read_idx == 2'd0) begin
        read_idx <= 2'd3;
    end
end

always @(posedge okClk) begin
    if(!rstn) begin
        block_pipe_out_data <= 32'b0;
    end
    else if(block_pipe_out_read) begin
        block_pipe_out_data <= data_store[32 * read_idx +: 32];
    end
end

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

okWireIn     ep00     (.okHE(okHE),                               .ep_addr(8'h00), .ep_dataout(ep00wire));
okBTPipeIn   BTpipeIn80 (.okHE(okHE), .okEH(okEHx[0 * 65 +: 65]), .ep_addr(8'h80), .ep_dataout(block_pipe_in_data), .ep_write(block_pipe_in_valid), .ep_blockstrobe(), .ep_ready(1'b1));
okBTPipeOut  BTpipeOutA0(.okHE(okHE), .okEH(okEHx[1 * 65 +: 65]), .ep_addr(8'ha0), .ep_datain(block_pipe_out_data), .ep_read(block_pipe_out_read),  .ep_blockstrobe(), .ep_ready(1'b1));

endmodule