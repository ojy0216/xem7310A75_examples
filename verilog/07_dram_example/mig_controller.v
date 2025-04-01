module mig_controller(
    input                   sys_clk,
    input                   rst,
    input                   calib_done,

    output reg              ib_re,
    input       [256 - 1:0] ib_data,
    input       [7 - 1:0]   ib_count,
    input                   ib_valid,
    input                   ib_empty,

    output reg              ob_we,
    output reg  [128 - 1:0] ob_data,
    output      [7 - 1:0]   ob_count,
    output                  ob_full,
    
    input                   app_rdy,
    output reg              app_en,
    output reg  [3 - 1:0]   app_cmd,
    output reg  [30 - 1:0]  app_addr,

    input       [256 - 1:0] app_rd_data,
    input                   app_rd_data_end,
    input                   app_rd_data_valid,

    input                   app_wdf_rdy,
    output reg              app_wdf_wren,
    output reg  [256 - 1:0] app_wdf_data,
    output reg              app_wdf_end,
    output reg  [32 - 1:0]  app_wdf_mask
);

localparam  OUT_FIFO_SIZE   = 128;

localparam  DRAM_READ       = 3'b001,
            DRAM_WRITE      = 3'b000;

localparam  s_idle          = 2'b00,
            s_read          = 2'b01,
            s_decode        = 2'b11,
            s_cmd           = 2'b10;

reg     [2 - 1:0]   state;

reg     [256 - 1:0] ib_data_buf;

wire                is_dram;
wire                is_read;
wire    [26 - 1:0]  dram_addr;
wire    [128 - 1:0] dram_wr_data;

reg                 prev_valid; 
reg     [26 - 1:0]  prev_dram_rd_addr;
reg     [256 - 1:0] prev_dram_rd_data;

wire                skip_read;

assign skip_read = (state == s_decode) && (is_dram == 1'b1) && (is_read == 1'b1) && (prev_valid == 1'b1) && (dram_addr[26 - 1:1] == prev_dram_rd_addr[26 - 1:1]);

always @(posedge sys_clk) begin
    if(rst) begin
        ib_data_buf <= 256'b0;
    end
    else if(ib_valid) begin
        ib_data_buf <= ib_data;
    end
end

// 1bit, 1bit, 26bit, 128bit -> 156bit
assign {is_dram, is_read, dram_addr, dram_wr_data} = ib_data_buf[156 - 1:0];

always @(posedge sys_clk) begin
    if(rst) begin
        state <= s_idle;

        ib_re <= 1'b0;

        app_en <= 1'b0;
        app_cmd <= 3'b0;
        app_addr <= 30'b0;
        app_wdf_wren <= 1'b0;
        app_wdf_data <= 256'b0;
        app_wdf_end <= 1'b0;
        app_wdf_mask <= 32'b0;
    end
    else begin
        case(state)
            s_idle: begin
                if((calib_done == 1'b1) && (!ib_empty)) begin
                    state <= s_read;

                    ib_re <= 1'b1;
                end
                else begin
                    ib_re <= 1'b0;
                end

                app_en <= 1'b0;
                app_cmd <= 3'b0;
                app_addr <= 30'b0;
                app_wdf_wren <= 1'b0;
                app_wdf_data <= 256'b0;
                app_wdf_end <= 1'b0;
                app_wdf_mask <= 32'b0;
            end
            s_read: begin
                ib_re <= 1'b0;

                if(ib_valid == 1'b1) begin
                    state <= s_decode;
                end

                app_en <= 1'b0;
                app_cmd <= 3'b0;
                app_addr <= 30'b0;
                app_wdf_wren <= 1'b0;
                app_wdf_data <= 256'b0;
                app_wdf_end <= 1'b0;
                app_wdf_mask <= 32'b0;
            end
            s_decode: begin
                ib_re <= 1'b0;

                if(is_dram == 1'b1) begin
                    if(is_read == 1'b1) begin
                        // DRAM READ
                        app_cmd <= DRAM_READ;
                        app_addr <= {1'b0, dram_addr[26 - 1:1], 3'b0};  // 1 - 25 - 3
                        app_wdf_wren <= 1'b0;
                        app_wdf_data <= 256'b0;
                        app_wdf_end <= 1'b0;
                        app_wdf_mask <= 32'b0;
                        if(ob_count < (OUT_FIFO_SIZE - 2)) begin
                            if((prev_valid == 1'b1) && (dram_addr[26 - 1:1] == prev_dram_rd_addr[26 - 1:1])) begin
                                state <= s_idle;

                                app_en <= 1'b0;
                            end
                            else begin
                                state <= s_cmd;

                                app_en <= 1'b1;
                            end
                        end
                        else begin
                            app_en <= 1'b0;
                        end
                    end
                    else begin
                        // DRAM WRITE
                        app_cmd <= DRAM_WRITE;
                        app_addr <= {1'b0, dram_addr[26 - 1:1], 3'b0};  // 1 - 25 - 3
                        app_wdf_wren <= 1'b1;
                        app_wdf_data <= (dram_addr[0] == 1'b1) ? {dram_wr_data, 128'b0} : {128'b0, dram_wr_data};
                        app_wdf_end <= 1'b1;
                        app_wdf_mask <= (dram_addr[0] == 1'b1) ? {{16{1'b0}}, {16{1'b1}}} : {{16{1'b1}}, {16{1'b0}}};

                        if(app_wdf_rdy == 1'b1) begin
                            state <= s_cmd;

                            app_en <= 1'b1;
                        end
                        else begin
                            app_en <= 1'b0;
                        end
                    end
                end
                else begin
                    // Not a DRAM request
                    state <= s_idle;

                    ib_re <= 1'b0;

                    app_en <= 1'b0;
                    app_cmd <= 3'b0;
                    app_addr <= 30'b0;
                    app_wdf_wren <= 1'b0;
                    app_wdf_data <= 256'b0;
                    app_wdf_end <= 1'b0;
                    app_wdf_mask <= 32'b0;
                end
            end
            s_cmd: begin
                ib_re <= 1'b0;

                if(is_read == 1'b1) begin
                    // READ
                    app_wdf_wren <= 1'b0;
                    app_wdf_data <= 256'b0;
                    app_wdf_end <= 1'b0;
                    app_wdf_mask <= 32'b0;

                    if(app_rdy == 1'b1) begin
                        state <= s_idle;

                        app_en <= 1'b0;
                        app_cmd <= 3'b0;
                        app_addr <= 30'b0;
                    end
                    else begin
                        app_en <= 1'b1;
                        app_cmd <= app_cmd;
                        app_addr <= app_addr;
                    end
                end
                else begin
                    // WRITE
                    app_wdf_wren <= 1'b0;
                    app_wdf_end <= 1'b0;

                    if(app_rdy == 1'b1) begin
                        state <= s_idle;

                        app_en <= 1'b0;
                        app_cmd <= 3'b0;
                        app_addr <= 30'b0;

                        app_wdf_data <= 256'b0;
                        app_wdf_mask <= 32'b0;
                    end
                    else begin
                        app_en <= 1'b1;
                        app_cmd <= app_cmd;
                        app_addr <= app_addr;

                        app_wdf_data <= app_wdf_data;
                        app_wdf_mask <= app_wdf_mask;
                    end
                end
            end
        endcase
    end
end

always @(posedge sys_clk) begin
    if(rst) begin
        prev_valid <= 1'b0;
        prev_dram_rd_addr <= 26'b0;
        prev_dram_rd_data <= 256'b0;
    end
    else if(app_rd_data_valid) begin
        prev_valid <= 1'b1;
        prev_dram_rd_addr <= dram_addr;
        prev_dram_rd_data <= app_rd_data;
    end
end

always @(posedge sys_clk) begin
    if(rst) begin
        ob_we <= 1'b0;
        ob_data <= 128'b0;
    end
    else begin
        if(app_rd_data_valid == 1'b1) begin
            ob_we <= 1'b1;
            ob_data <= (dram_addr[0] == 1'b1) ? app_rd_data[256 - 1 -: 128] : app_rd_data[128 - 1:0];
        end
        else if(skip_read) begin
            ob_we <= 1'b1;
            ob_data <= (dram_addr[0] == 1'b1) ? prev_dram_rd_data[256 - 1 -: 128] : prev_dram_rd_data[128 - 1:0];
        end
        else if(ob_we == 1'b1) begin
            ob_we <= 1'b0;
            ob_data <= 128'b0;
        end
        else begin
            ob_we <= 1'b0;
            ob_data <= 128'b0;
        end
    end
end

endmodule