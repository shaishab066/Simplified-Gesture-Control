module sample_hold (
    input  wire        clk,
    input  wire        rst,
    input  wire        valid_in,
    input  wire signed [15:0] data_in,
    output reg  signed [15:0] data_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) data_out<=0;
        else if (valid_in) data_out<=data_in;
    end
endmodule
