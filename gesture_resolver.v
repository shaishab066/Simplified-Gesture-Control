module gesture_resolver (
    input  wire clk,
    input  wire rst,
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
               TILT_UP=3'd3,TILT_DOWN=3'd4;

    wire [2:0] stable_tilt;
    assign stable_tilt = tilt_right_in ? TILT_RIGHT :
                         tilt_left_in  ? TILT_LEFT  :
                         tilt_up_in    ? TILT_UP    :
                         tilt_down_in  ? TILT_DOWN  : IDLE;

    always @(posedge clk or posedge rst) begin
        if (rst) gesture<=IDLE;
        else begin
            case(stable_tilt)
                TILT_RIGHT: gesture<=TILT_RIGHT;
                TILT_LEFT:  gesture<=TILT_LEFT;
                TILT_UP:    gesture<=TILT_UP;
                TILT_DOWN:  gesture<=TILT_DOWN;
                default:    gesture<=IDLE;
            endcase
        end
    end
endmodule
