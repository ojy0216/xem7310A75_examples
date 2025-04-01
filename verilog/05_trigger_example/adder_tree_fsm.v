module adder_tree_fsm(
    input clk,
    input rstn,

    input start,
    input [128 - 1:0] din,

    output done,
    output [16 - 1:0] dout
);

reg [2 - 1:0] c_state, n_state;

assign state = c_state;

localparam FSM_IDLE = 2'd0;
localparam FSM_RUN  = 2'd1;
localparam FSM_DONE = 2'd2;

// FSM
always @(posedge clk, negedge rstn) begin
    if(!rstn) begin
        c_state <= FSM_IDLE;
    end
    else begin
        c_state <= n_state;
    end
end

// n_state logic
always @(*) begin
    case(c_state)
        FSM_IDLE: begin
            if(start == 1'b1) begin
                n_state = FSM_RUN;
            end
            else begin
                n_state = FSM_IDLE;
            end
        end
        FSM_RUN: begin
            if(stage3_done == 1'b1) begin
                n_state = FSM_DONE;
            end
            else begin
                n_state = FSM_RUN;
            end
        end
        FSM_DONE: begin
            n_state = FSM_IDLE;
        end
        default: begin
            n_state = FSM_IDLE;
        end
    endcase
end

assign dout = (c_state == FSM_DONE) ? stage3 : 16'b0;
assign done = (c_state == FSM_DONE) ? 1'b1 : 1'b0;

reg start_reg;

reg [16 - 1:0] stage1_0, stage1_1, stage1_2, stage1_3;
reg [16 - 1:0] stage2_0, stage2_1;
reg [16 - 1:0] stage3;

reg stage1_done, stage2_done, stage3_done;

always @(posedge clk, negedge rstn) begin
    if(!rstn) begin
        start_reg <= 1'b0;
    end
    else begin
        start_reg <= start;
    end
end

// 16b * 8 adder tree
always @(posedge clk, negedge rstn) begin
    if(!rstn) begin
        stage1_0 <= 16'b0;
        stage1_1 <= 16'b0;
        stage1_2 <= 16'b0;
        stage1_3 <= 16'b0;

        stage2_0 <= 16'b0;
        stage2_1 <= 16'b0;

        stage3 <= 16'b0;

        stage1_done <= 1'b0;
        stage2_done <= 1'b0;
        stage3_done <= 1'b0;
    end
    else if(c_state == FSM_RUN) begin
        stage1_0 <= din[15:0] + din[31:16];
        stage1_1 <= din[47:32] + din[63:48];
        stage1_2 <= din[79:64] + din[95:80];
        stage1_3 <= din[111:96] + din[127:112];
        stage1_done <= start_reg;

        stage2_0 <= stage1_0 + stage1_1;
        stage2_1 <= stage1_2 + stage1_3;
        stage2_done <= stage1_done;

        stage3 <= stage2_0 + stage2_1;
        stage3_done <= stage2_done;
    end
end

endmodule