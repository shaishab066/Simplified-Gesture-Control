module led_controller (
    input  wire       clk,
    input  wire       rst,
    input  wire [2:0] gesture,
    output reg [15:0] leds
);
    localparam IDLE=3'd0,TILT_RIGHT=3'd1,TILT_LEFT=3'd2,
               TILT_UP=3'd3,TILT_DOWN=3'd4,SHAKE=3'd5;

    reg [23:0] blink_cnt;
    reg        blink;

    always @(posedge clk or posedge rst) begin
        if (rst) begin blink_cnt<=0; blink<=0; end
        else begin
            if (blink_cnt>=24'd9_999_999) begin
                blink_cnt<=0; blink<=~blink;
            end else blink_cnt<=blink_cnt+1;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) leds<=16'b0;
        else begin
            case(gesture)
                IDLE:       leds<=16'b0000_0000_0000_0000;
                TILT_RIGHT: leds<=16'b0000_0000_0000_1111;
                TILT_LEFT:  leds<=16'b1111_1111_0000_0000;
                TILT_UP:    leds<=16'b1111_1111_1111_0000;
                TILT_DOWN:  leds<=16'b1111_1111_1111_1111;
                SHAKE:      leds<=blink?16'hFFFF:16'h0000;
                default:    leds<=16'b0;
            endcase
        end
    end
endmodule
