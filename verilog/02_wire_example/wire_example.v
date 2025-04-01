module wire_example(
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
wire [32 - 1:0] ep00wire;  // data0
wire [32 - 1:0] ep01wire;  // data1
wire [32 - 1:0] ep02wire;  // select

wire [32 - 1:0] ep20wire;
wire [32 - 1:0] ep21wire;

// Signals
wire [32 - 1:0] data0;
wire [32 - 1:0] data1;

wire op_select;

reg [32 - 1:0] or_result;
reg [32 - 1:0] and_result;

// assignment of wires
assign data0 = ep00wire;
assign data1 = ep01wire;

assign op_select = ep02wire[0];

assign ep20wire = or_result;
assign ep21wire = and_result;

function [7:0] xem7310_led;
input [7:0] a;
integer i;
begin
    for(i = 0; i < 8; i = i + 1) begin
        xem7310_led[i] = (a[i] == 1'b1) ? 1'b0 : 1'bz;
    end
end
endfunction

// assign led = xem7310_led(ep00wire);
assign led = op_select ? xem7310_led(or_result[7:0]) : xem7310_led(and_result[7:0]);

always @(posedge okClk) begin
    or_result <= data0 | data1;
    and_result <= data0 & data1;
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

okWireOR # (.N(2)) wireOR (okEH, okEHx);

okWireIn    ep00(.okHE(okHE),                             .ep_addr(8'h00), .ep_dataout(ep00wire));
okWireIn    ep01(.okHE(okHE),                             .ep_addr(8'h01), .ep_dataout(ep01wire));
okWireIn    ep02(.okHE(okHE),                             .ep_addr(8'h02), .ep_dataout(ep02wire));
okWireOut   ep20(.okHE(okHE), .okEH(okEHx[0 * 65 +: 65]), .ep_addr(8'h20), .ep_datain(ep20wire));
okWireOut   ep21(.okHE(okHE), .okEH(okEHx[1 * 65 +: 65]), .ep_addr(8'h21), .ep_datain(ep21wire));

endmodule