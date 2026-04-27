module pwm_controller (
    input  wire       clk,
    input  wire       rst,
    input  wire [2:0] gesture,
    output reg        pwm_out
);
    localparam IDLE       = 3'd0,
               TILT_RIGHT = 3'd1,
               TILT_LEFT  = 3'd2,
               TILT_UP    = 3'd3,
               TILT_DOWN  = 3'd4;

    // 1 kHz PWM @ 100 MHz clock
    localparam PERIOD     = 100_000;   

    // Duty cycles as % of PERIOD
    localparam DUTY_IDLE  = 0;          
    localparam DUTY_RIGHT = 25_000;     
    localparam DUTY_LEFT  = 50_000;     
    localparam DUTY_UP    = 75_000;    
    localparam DUTY_DOWN  = 100_000;    

    reg [16:0] pwm_counter; 
    reg [16:0] duty;

    always @(*) begin
        case(gesture)
            TILT_RIGHT: duty = DUTY_RIGHT;
            TILT_LEFT:  duty = DUTY_LEFT;
            TILT_UP:    duty = DUTY_UP;
            TILT_DOWN:  duty = DUTY_DOWN;
            default:    duty = DUTY_IDLE;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pwm_counter <= 0;
            pwm_out     <= 0;
        end else begin
            if (pwm_counter >= PERIOD - 1)
                pwm_counter <= 0;
            else
                pwm_counter <= pwm_counter + 1;

            pwm_out <= (pwm_counter < duty) ? 1'b1 : 1'b0;
        end
    end
endmodule
