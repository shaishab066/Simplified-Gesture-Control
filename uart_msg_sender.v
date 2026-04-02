module uart_msg_sender (
    input  wire       clk,
    input  wire       rst,
    input  wire [2:0] gesture,
    output reg        uart_send,
    output reg  [7:0] uart_data,
    input  wire       uart_busy
);
    localparam IDLE=3'd0,TILT_RIGHT=3'd1,TILT_LEFT=3'd2,
               TILT_UP=3'd3,TILT_DOWN=3'd4,SHAKE=3'd5;

    reg [7:0] msg_rom[0:55];
    reg [5:0] msg_start;
    reg [3:0] msg_len;
    reg [3:0] char_idx;
    reg [2:0] prev_gesture;

    initial begin
        msg_rom[0]="I";msg_rom[1]="D";msg_rom[2]="L";msg_rom[3]="E";msg_rom[4]=8'h0D;msg_rom[5]=8'h0A;
        msg_rom[6]="T";msg_rom[7]="I";msg_rom[8]="L";msg_rom[9]="T";msg_rom[10]=" ";
        msg_rom[11]="R";msg_rom[12]="I";msg_rom[13]="G";msg_rom[14]="H";msg_rom[15]="T";
        msg_rom[16]=8'h0D;msg_rom[17]=8'h0A;
        msg_rom[18]="T";msg_rom[19]="I";msg_rom[20]="L";msg_rom[21]="T";msg_rom[22]=" ";
        msg_rom[23]="L";msg_rom[24]="E";msg_rom[25]="F";msg_rom[26]="T";
        msg_rom[27]=8'h0D;msg_rom[28]=8'h0A;
        msg_rom[29]="T";msg_rom[30]="I";msg_rom[31]="L";msg_rom[32]="T";msg_rom[33]=" ";
        msg_rom[34]="U";msg_rom[35]="P";msg_rom[36]=8'h0D;msg_rom[37]=8'h0A;
        msg_rom[38]="T";msg_rom[39]="I";msg_rom[40]="L";msg_rom[41]="T";msg_rom[42]=" ";
        msg_rom[43]="D";msg_rom[44]="O";msg_rom[45]="W";msg_rom[46]="N";
        msg_rom[47]=8'h0D;msg_rom[48]=8'h0A;
        msg_rom[49]="S";msg_rom[50]="H";msg_rom[51]="A";msg_rom[52]="K";
        msg_rom[53]="E";msg_rom[54]=8'h0D;msg_rom[55]=8'h0A;
    end

    localparam ST_IDLE=2'd0,ST_SEND=2'd1,ST_WAIT=2'd2;
    reg [1:0] state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state<=ST_IDLE; prev_gesture<=3'd7;
            uart_send<=0; uart_data<=0; char_idx<=0;
        end else begin
            uart_send<=0;
            case(state)
                ST_IDLE: begin
                    if (gesture!=prev_gesture) begin
                        prev_gesture<=gesture; char_idx<=0;
                        case(gesture)
                            IDLE:       begin msg_start<=0;  msg_len<=6;  end
                            TILT_RIGHT: begin msg_start<=6;  msg_len<=12; end
                            TILT_LEFT:  begin msg_start<=18; msg_len<=11; end
                            TILT_UP:    begin msg_start<=29; msg_len<=9;  end
                            TILT_DOWN:  begin msg_start<=38; msg_len<=11; end
                            SHAKE:      begin msg_start<=49; msg_len<=7;  end
                            default:    begin msg_start<=0;  msg_len<=6;  end
                        endcase
                        state<=ST_SEND;
                    end
                end
                ST_SEND: begin
                    if (!uart_busy) begin
                        uart_data<=msg_rom[msg_start+char_idx];
                        uart_send<=1; state<=ST_WAIT;
                    end
                end
                ST_WAIT: begin
                    if (!uart_busy) begin
                        if (char_idx<msg_len-1) begin char_idx<=char_idx+1; state<=ST_SEND; end
                        else state<=ST_IDLE;
                    end
                end
            endcase
        end
    end
endmodule
