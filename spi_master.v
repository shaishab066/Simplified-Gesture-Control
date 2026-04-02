module spi_master (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [7:0]  tx_byte,
    input  wire [1:0]  byte_count,
    output reg         busy,
    output reg  [7:0]  rx_byte0,
    output reg  [7:0]  rx_byte1,
    output reg         done,
    output reg         sclk,
    output reg         mosi,
    input  wire        miso,
    output reg         cs_n
);
    reg [6:0] clk_div;
    reg       spi_clk_en;
    always @(posedge clk or posedge rst) begin
        if (rst) begin clk_div<=0; spi_clk_en<=0; end
        else begin
            if (clk_div==49) begin clk_div<=0; spi_clk_en<=1; end
            else begin clk_div<=clk_div+1; spi_clk_en<=0; end
        end
    end

    localparam IDLE=3'd0,CS_LOW=3'd1,SHIFT=3'd2,CS_HIGH=3'd3,DONE=3'd4;
    reg [2:0] state;
    reg [3:0] bit_cnt;
    reg [7:0] shift_reg,rx_shift;
    reg [15:0] tx_data;
    reg [4:0]  total_bits;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state<=IDLE; cs_n<=1; sclk<=0; mosi<=0; busy<=0; done<=0;
            bit_cnt<=0; rx_byte0<=0; rx_byte1<=0;
        end else begin
            done<=0;
            if (spi_clk_en) begin
                case(state)
                    IDLE: begin
                        cs_n<=1; sclk<=0; busy<=0;
                        if (start) begin
                            busy<=1; tx_data<={tx_byte,8'h00};
                            total_bits<=(byte_count==2)?16:8;
                            bit_cnt<=0; state<=CS_LOW;
                        end
                    end
                    CS_LOW: begin cs_n<=0; mosi<=tx_data[15]; state<=SHIFT; bit_cnt<=0; end
                    SHIFT: begin
                        sclk<=~sclk;
                        if (sclk==0) rx_shift<={rx_shift[6:0],miso};
                        else begin
                            bit_cnt<=bit_cnt+1;
                            if (bit_cnt==total_bits-1) begin rx_byte0<=rx_shift; state<=CS_HIGH; end
                            else mosi<=tx_data[14-bit_cnt];
                        end
                    end
                    CS_HIGH: begin cs_n<=1; sclk<=0; state<=DONE; end
                    DONE:    begin done<=1; busy<=0; state<=IDLE; end
                endcase
            end
        end
    end
endmodule
