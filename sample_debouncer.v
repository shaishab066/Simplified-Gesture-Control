module sample_debouncer #(parameter HOLD_COUNT=8)(
    input  wire clk,
    input  wire rst,
    input  wire sample_tick,
    input  wire gesture_in,
    output reg  gesture_out
);
    reg [3:0] count;
    always @(posedge clk or posedge rst) begin
        if (rst) begin count<=0; gesture_out<=0; end
        else if (sample_tick) begin
            if (gesture_in) begin
                if (count<HOLD_COUNT) count<=count+1;
                else gesture_out<=1;
            end else begin count<=0; gesture_out<=0; end
        end
    end
endmodule
