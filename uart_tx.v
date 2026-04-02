module uart_tx (
    input  wire       clk,
    input  wire       rst,
    input  wire       send,
    input  wire [7:0] data_in,
    output reg        tx,
    output reg        busy
);
    localparam CLKS_PER_BIT=10417;
    localparam IDLE=2'd0,START=2'd1,DATA=2'd2,STOP=2'd3;
    reg [13:0] clk_count;
    reg [2:0]  bit_idx;
    reg [7:0]  shift_reg;
    reg [1:0]  state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin state<=IDLE; tx<=1; busy<=0; clk_count<=0; bit_idx<=0; end
        else begin
            case(state)
                IDLE: begin
                    tx<=1; busy<=0;
                    if (send) begin shift_reg<=data_in; busy<=1; clk_count<=0; state<=START; end
                end
                START: begin
                    tx<=0;
                    if (clk_count<CLKS_PER_BIT-1) clk_count<=clk_count+1;
                    else begin clk_count<=0; bit_idx<=0; state<=DATA; end
                end
                DATA: begin
                    tx<=shift_reg[bit_idx];
                    if (clk_count<CLKS_PER_BIT-1) clk_count<=clk_count+1;
                    else begin
                        clk_count<=0;
                        if (bit_idx<7) bit_idx<=bit_idx+1;
                        else begin bit_idx<=0; state<=STOP; end
                    end
                end
                STOP: begin
                    tx<=1;
                    if (clk_count<CLKS_PER_BIT-1) clk_count<=clk_count+1;
                    else begin clk_count<=0; busy<=0; state<=IDLE; end
                end
            endcase
        end
    end
endmodule
