module trigger_example(
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
wire [32 - 1:0] wire00_wire;

wire [32 - 1:0] trig40_wire;
wire [32 - 1:0] trig60_wire;

wire [32 - 1:0] pipein80_wire;
wire pipein80_valid;
reg [32 - 1:0] pipeoutA0_wire;
wire pipeoutA0_read;

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
wire rstn = wire00_wire[0];
wire fsm_start = trig40_wire[0];
wire fsm_done;

reg [2 - 1:0] store_idx;
reg [2 - 1:0] read_idx;
reg [128 - 1:0] data_store;  // 16 byte = 128 bit

assign trig60_wire = {31'b0, fsm_done};

wire [16 - 1:0] dout;
reg [128 - 1:0] pipeout_data;

always @(posedge okClk) begin
    if(!rstn) begin
        data_store <= 128'b0;
        store_idx <= 2'd3;
    end
    else if(pipein80_valid) begin
        store_idx <= store_idx - 1'b1;
        data_store[32 * store_idx +: 32] <= pipein80_wire;  // [15, 14, ..., 2, 1, 0]
    end

    if(store_idx == 2'b0) begin
        store_idx <= 2'd3;
    end
end

always @(posedge okClk) begin
    if(!rstn) begin
        pipeout_data <= 128'b0;
    end
    else if(fsm_done) begin
        pipeout_data <= {112'b0, dout};
    end
end

always @(posedge okClk) begin
    if(!rstn) begin
        read_idx <= 2'd3;
        pipeoutA0_wire <= 32'b0;
    end
    else if(pipeoutA0_read) begin
        read_idx <= read_idx - 1'b1;
        pipeoutA0_wire <= pipeout_data[32 * read_idx +: 32];
    end

    if(read_idx == 2'd0) begin
        read_idx <= 2'd3;
    end
end


// Instantiate the okHost and connect endpoints
wire [65 * 3 - 1:0] okEHx;

okHost okHI(
    .okUH(okUH),
    .okHU(okHU),
    .okUHU(okUHU),
    .okAA(okAA),
    .okClk(okClk),
    .okHE(okHE),
    .okEH(okEH)
);

okWireOR #(.N(3)) wireOr (okEH, okEHx);

okWireIn     wireIn00 (.okHE(okHE),                             .ep_addr(8'h00), .ep_dataout(wire00_wire));

okTriggerIn  trigIn40 (.okHE(okHE),                             .ep_addr(8'h40), .ep_clk(okClk), .ep_trigger(trig40_wire));
okTriggerOut trigOut60(.okHE(okHE), .okEH(okEHx[0 * 65 +: 65]), .ep_addr(8'h60), .ep_clk(okClk), .ep_trigger(trig60_wire));

okPipeIn     pipeIn80 (.okHE(okHE), .okEH(okEHx[1 * 65 +: 65]), .ep_addr(8'h80), .ep_dataout(pipein80_wire), .ep_write(pipein80_valid));
okPipeOut    pipeOutA0(.okHE(okHE), .okEH(okEHx[2 * 65 +: 65]), .ep_addr(8'hA0), .ep_datain(pipeoutA0_wire), .ep_read(pipeoutA0_read));

adder_tree_fsm FSM(
    .clk(okClk),
    .rstn(rstn),
    .start(fsm_start),
    .din(data_store),
    .done(fsm_done),
    .dout(dout)
);

endmodule