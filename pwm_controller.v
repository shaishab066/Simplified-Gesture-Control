module pwm_controller (
    input  wire       clk,
    input  wire       rst,
    input  wire [2:0] gesture,
    output reg        pwm_out
);
    localparam IDLE=3'd0,TILT_RIGHT=3'd1,TILT_LEFT=3'd2,
               TILT_UP=3'd3,TILT_DOWN=3'd4,SHAKE=3'd5;
    localparam PERIOD=10000;
    localparam DUTY_IDLE=0,DUTY_RIGHT=2500,DUTY_LEFT=5000,
               DUTY_UP=7500,DUTY_DOWN=10000;
    localparam BLINK_HALF=10_000_000;

    reg [13:0] pwm_counter;
    reg [23:0] blink_counter;
    reg        blink_state;
    reg [13:0] duty;

    always @(*) begin
        case(gesture)
            TILT_RIGHT: duty=DUTY_RIGHT;
            TILT_LEFT:  duty=DUTY_LEFT;
            TILT_UP:    duty=DUTY_UP;
            TILT_DOWN:  duty=DUTY_DOWN;
            default:    duty=DUTY_IDLE;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin blink_counter<=0; blink_state<=0; end
        else begin
            if (blink_counter>=BLINK_HALF-1) begin
                blink_counter<=0; blink_state<=~blink_state;
            end else blink_counter<=blink_counter+1;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin pwm_counter<=0; pwm_out<=0; end
        else begin
            if (gesture==SHAKE) begin pwm_out<=blink_state; pwm_counter<=0; end
            else begin
                if (pwm_counter>=PERIOD-1) pwm_counter<=0;
                else pwm_counter<=pwm_counter+1;
                pwm_out<=(pwm_counter<duty)?1:0;
            end
        end
    end
endmodule
