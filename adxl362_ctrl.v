module adxl362_ctrl (
    input  wire        clk,
    input  wire        rst,
    input  wire        sample_tick,
    output reg         sclk,
    output reg         mosi,
    input  wire        miso,
    output reg         cs_n,
    output reg  signed [15:0] accel_x,
    output reg  signed [15:0] accel_y,
    output reg  signed [15:0] accel_z,
    output reg         data_valid
);
    reg [4:0]  clk_div;
    reg        spi_en;
    always @(posedge clk or posedge rst) begin
        if (rst) begin clk_div<=0; spi_en<=0; end
        else begin
            spi_en<=0;
            if (clk_div==9) begin clk_div<=0; spi_en<=1; end
            else clk_div<=clk_div+1;
        end
    end

    localparam S_RESET_START=4'd0,S_RESET_SEND=4'd1,S_RESET_WAIT=4'd2,
               S_MEAS_START=4'd3,S_MEAS_SEND=4'd4,
               S_IDLE=4'd5,S_READ_START=4'd6,S_READ_SEND=4'd7,S_DONE=4'd8;

    reg [3:0]  state;
    reg [3:0]  bit_cnt,byte_cnt;
    reg [7:0]  shift_out,shift_in;
    reg [7:0]  rx[0:7];
    reg        initialized;
    reg [16:0] wait_cnt;
    reg [3:0]  total_bytes;
    reg [7:0]  tx_buf[0:7];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state<=S_RESET_START; cs_n<=1; sclk<=0; mosi<=0;
            initialized<=0; data_valid<=0; bit_cnt<=0; byte_cnt<=0;
            wait_cnt<=0; accel_x<=0; accel_y<=0; accel_z<=0;
        end else if (spi_en) begin
            data_valid<=0;
            case(state)
                S_RESET_START: begin
                    tx_buf[0]<=8'h0A; tx_buf[1]<=8'h1F; tx_buf[2]<=8'h52;
                    total_bytes<=3; byte_cnt<=0; bit_cnt<=0;
                    cs_n<=0; shift_out<=8'h0A; mosi<=1'b0; state<=S_RESET_SEND;
                end
                S_RESET_SEND: begin
                    sclk<=~sclk;
                    if (sclk==0) shift_in<={shift_in[6:0],miso};
                    else begin
                        if (bit_cnt==7) begin
                            bit_cnt<=0; byte_cnt<=byte_cnt+1;
                            if (byte_cnt==total_bytes-1) begin cs_n<=1; sclk<=0; state<=S_RESET_WAIT; end
                            else begin shift_out<=tx_buf[byte_cnt+1]; mosi<=tx_buf[byte_cnt+1][7]; end
                        end else begin bit_cnt<=bit_cnt+1; mosi<=shift_out[6-bit_cnt]; end
                    end
                end
                S_RESET_WAIT: begin
                    if (wait_cnt==17'd5000) begin wait_cnt<=0; state<=S_MEAS_START; end
                    else wait_cnt<=wait_cnt+1;
                end
                S_MEAS_START: begin
                    tx_buf[0]<=8'h0A; tx_buf[1]<=8'h2D; tx_buf[2]<=8'h02;
                    total_bytes<=3; byte_cnt<=0; bit_cnt<=0;
                    cs_n<=0; shift_out<=8'h0A; mosi<=1'b0; state<=S_MEAS_SEND;
                end
                S_MEAS_SEND: begin
                    sclk<=~sclk;
                    if (sclk==0) shift_in<={shift_in[6:0],miso};
                    else begin
                        if (bit_cnt==7) begin
                            bit_cnt<=0; byte_cnt<=byte_cnt+1;
                            if (byte_cnt==total_bytes-1) begin cs_n<=1; sclk<=0; initialized<=1; state<=S_IDLE; end
                            else begin shift_out<=tx_buf[byte_cnt+1]; mosi<=tx_buf[byte_cnt+1][7]; end
                        end else begin bit_cnt<=bit_cnt+1; mosi<=shift_out[6-bit_cnt]; end
                    end
                end
                S_IDLE: begin
                    cs_n<=1; sclk<=0;
                    if (initialized && sample_tick) state<=S_READ_START;
                end
                S_READ_START: begin
                    tx_buf[0]<=8'h0B; tx_buf[1]<=8'h0E;
                    tx_buf[2]<=8'h00; tx_buf[3]<=8'h00;
                    tx_buf[4]<=8'h00; tx_buf[5]<=8'h00;
                    tx_buf[6]<=8'h00; tx_buf[7]<=8'h00;
                    total_bytes<=8; byte_cnt<=0; bit_cnt<=0;
                    cs_n<=0; shift_out<=8'h0B; mosi<=1'b0; state<=S_READ_SEND;
                end
                S_READ_SEND: begin
                    sclk<=~sclk;
                    if (sclk==0) shift_in<={shift_in[6:0],miso};
                    else begin
                        if (bit_cnt==7) begin
                            if (byte_cnt>=2) rx[byte_cnt-2]<=shift_in;
                            bit_cnt<=0; byte_cnt<=byte_cnt+1;
                            if (byte_cnt==total_bytes-1) begin cs_n<=1; sclk<=0; state<=S_DONE; end
                            else begin shift_out<=tx_buf[byte_cnt+1]; mosi<=tx_buf[byte_cnt+1][7]; end
                        end else begin bit_cnt<=bit_cnt+1; mosi<=shift_out[6-bit_cnt]; end
                    end
                end
                S_DONE: begin
                    accel_x<=$signed({{4{rx[1][3]}},rx[1][3:0],rx[0]});
                    accel_y<=$signed({{4{rx[3][3]}},rx[3][3:0],rx[2]});
                    accel_z<=$signed({{4{rx[5][3]}},rx[5][3:0],rx[4]});
                    data_valid<=1; state<=S_IDLE;
                end
            endcase
        end
    end
endmodule
