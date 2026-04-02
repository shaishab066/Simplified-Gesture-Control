module tilt_detector (
    input  wire        clk,
    input  wire        rst,
    input  wire        valid_in,
    input  wire        shake_active,
    input  wire signed [15:0] accel_x,
    input  wire signed [15:0] accel_y,
    input  wire signed [15:0] accel_z,
    output reg         tilt_right,
    output reg         tilt_left,
    output reg         tilt_up,
    output reg         tilt_down,
    output reg         tilt_detected
);
    localparam signed [15:0] THRESH_HIGH  = 16'sd300;
    localparam signed [15:0] THRESH_LOW   = 16'sd150;
    localparam signed [15:0] SPEED_THRESH = 16'sd200;

    reg signed [15:0] abs_x, abs_y;
    reg signed [15:0] prev_x, prev_y, prev_z;
    reg signed [15:0] delta_x, delta_y, delta_z;
    reg tilt_active;
    reg is_fast;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tilt_right<=0; tilt_left<=0; tilt_up<=0;
            tilt_down<=0; tilt_detected<=0; tilt_active<=0;
            prev_x<=0; prev_y<=0; prev_z<=0;
        end else if (valid_in) begin
            abs_x   = (accel_x[15]) ? -accel_x : accel_x;
            abs_y   = (accel_y[15]) ? -accel_y : accel_y;
            delta_x = accel_x - prev_x;
            delta_y = accel_y - prev_y;
            delta_z = accel_z - prev_z;
            prev_x <= accel_x;
            prev_y <= accel_y;
            prev_z <= accel_z;

            is_fast = (delta_z > SPEED_THRESH) || (delta_z < -SPEED_THRESH);

            if (shake_active || is_fast) begin
                tilt_right<=0; tilt_left<=0;
                tilt_up<=0; tilt_down<=0;
                tilt_detected<=0; tilt_active<=0;
            end else begin
                if (!tilt_active) begin
                    if (abs_x > THRESH_HIGH || abs_y > THRESH_HIGH) begin
                        tilt_active   <= 1;
                        tilt_detected <= 1;
                        if (abs_x >= abs_y) begin
                            tilt_right <= (accel_x > 0) ? 1 : 0;
                            tilt_left  <= (accel_x > 0) ? 0 : 1;
                            tilt_up    <= 0; tilt_down <= 0;
                        end else begin
                            tilt_up    <= (accel_y > 0) ? 0 : 1;
                            tilt_down  <= (accel_y > 0) ? 1 : 0;
                            tilt_right <= 0; tilt_left <= 0;
                        end
                    end else begin
                        tilt_right<=0; tilt_left<=0;
                        tilt_up<=0; tilt_down<=0;
                        tilt_detected<=0;
                    end
                end else begin
                    if (abs_x < THRESH_LOW && abs_y < THRESH_LOW) begin
                        tilt_active<=0;
                        tilt_right<=0; tilt_left<=0;
                        tilt_up<=0; tilt_down<=0;
                        tilt_detected<=0;
                    end
                end
            end
        end
    end
endmodule
