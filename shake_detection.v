module shake_detection (
    input  wire        clk,
    input  wire        rst,
    input  wire        valid_in,
    input  wire signed [15:0] accel_x,
    input  wire signed [15:0] accel_y,
    input  wire signed [15:0] accel_z,
    output reg         shake_detected
);
    reg signed [15:0] prev_x, prev_z;
    reg signed [15:0] delta_x, delta_z;

    localparam signed [15:0] THRESH = 16'sd200;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shake_detected<=0;
            prev_x<=0; prev_z<=0;
        end else if (valid_in) begin
            shake_detected<=0;
            delta_x = accel_x - prev_x;
            delta_z = accel_z - prev_z;
            prev_x  <= accel_x;
            prev_z  <= accel_z;

            if ((delta_x >  THRESH) || (delta_x < -THRESH) ||
                (delta_z >  THRESH) || (delta_z < -THRESH))
                shake_detected <= 1;
        end
    end
endmodule
