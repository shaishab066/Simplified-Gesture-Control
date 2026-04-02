module gesture_resolver (
    input  wire clk,
    input  wire rst,
    input  wire shake_in,
    input  wire tilt_right_in,
    input  wire tilt_left_in,
    input  wire tilt_up_in,
    input  wire tilt_down_in,
    input  wire tilt_right_raw,
    input  wire tilt_left_raw,
    input  wire tilt_up_raw,
    input  wire tilt_down_raw,
    output reg  [2:0] gesture
);
    localparam IDLE=3'd0,TILT_RIGHT=3'd1,TILT_LEFT=3'd2,
               TILT_UP=3'd3,TILT_DOWN=3'd4,SHAKE=3'd5;

    reg [2:0] prev_raw_tilt;
    reg [3:0] change_count;
    reg [7:0] window_count;
    reg [7:0] shake_hold;

    wire [2:0] raw_tilt;
    assign raw_tilt = tilt_right_raw ? TILT_RIGHT :
                      tilt_left_raw  ? TILT_LEFT  :
                      tilt_up_raw    ? TILT_UP    :
                      tilt_down_raw  ? TILT_DOWN  : IDLE;

    wire [2:0] stable_tilt;
    assign stable_tilt = tilt_right_in ? TILT_RIGHT :
                         tilt_left_in  ? TILT_LEFT  :
                         tilt_up_in    ? TILT_UP    :
                         tilt_down_in  ? TILT_DOWN  : IDLE;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            gesture<=IDLE; prev_raw_tilt<=IDLE;
            change_count<=0; window_count<=0; shake_hold<=0;
        end else begin
            window_count<=window_count+1;

            if (raw_tilt!=IDLE) begin
                if (raw_tilt!=prev_raw_tilt && prev_raw_tilt!=IDLE)
                    change_count<=change_count+1;
                prev_raw_tilt<=raw_tilt;
            end

            if (window_count>=80) begin
                change_count<=0; window_count<=0; prev_raw_tilt<=IDLE;
            end

            if (change_count>=4 || shake_in) begin
                shake_hold<=200; change_count<=0; window_count<=0;
            end

            if (shake_hold>0) begin
                gesture<=SHAKE; shake_hold<=shake_hold-1;
            end else begin
                case(stable_tilt)
                    TILT_RIGHT: gesture<=TILT_RIGHT;
                    TILT_LEFT:  gesture<=TILT_LEFT;
                    TILT_UP:    gesture<=TILT_UP;
                    TILT_DOWN:  gesture<=TILT_DOWN;
                    default:    gesture<=IDLE;
                endcase
            end
        end
    end
endmodule
