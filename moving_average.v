module moving_average (
    input  wire        clk,
    input  wire        rst,
    input  wire        valid_in,
    input  wire signed [15:0] new_sample,
    output reg  signed [15:0] avg_out
);
    reg signed [15:0] samples[0:15];
    reg signed [19:0] sum;
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sum<=0; avg_out<=0;
            for (i=0;i<16;i=i+1) samples[i]<=0;
        end else if (valid_in) begin
            sum<=sum-samples[15]+new_sample;
            for (i=15;i>0;i=i-1) samples[i]<=samples[i-1];
            samples[0]<=new_sample;
            avg_out<=(sum-samples[15]+new_sample)>>>4;
        end
    end
endmodule
