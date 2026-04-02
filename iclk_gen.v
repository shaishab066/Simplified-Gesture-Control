module iclk_gen (
    input  wire clk,
    input  wire rst,
    output reg  sample_tick
);
    reg [16:0] counter;
    always @(posedge clk or posedge rst) begin
        if (rst) begin counter<=0; sample_tick<=0; end
        else begin
            sample_tick<=0;
            if (counter==17'd199_999) begin
                counter<=0; sample_tick<=1;
            end else counter<=counter+1;
        end
    end
endmodule
