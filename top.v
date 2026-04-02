module top (
    input  wire        clk,
    input  wire        rst_n,
    output wire        acl_sclk,
    output wire        acl_mosi,
    input  wire        acl_miso,
    output wire        acl_csn,
    output wire [15:0] led,
    output wire        uart_txd
);
    wire rst = ~rst_n;

    wire sample_tick;
    iclk_gen u_iclk (.clk(clk),.rst(rst),.sample_tick(sample_tick));

    wire signed [15:0] raw_x, raw_y, raw_z;
    wire               accel_valid;
    adxl362_ctrl u_adxl (
        .clk(clk),.rst(rst),.sample_tick(sample_tick),
        .sclk(acl_sclk),.mosi(acl_mosi),.miso(acl_miso),.cs_n(acl_csn),
        .accel_x(raw_x),.accel_y(raw_y),.accel_z(raw_z),.data_valid(accel_valid)
    );

    wire signed [15:0] avg_x, avg_y, avg_z;
    moving_average u_avg_x (.clk(clk),.rst(rst),.valid_in(accel_valid),.new_sample(raw_x),.avg_out(avg_x));
    moving_average u_avg_y (.clk(clk),.rst(rst),.valid_in(accel_valid),.new_sample(raw_y),.avg_out(avg_y));
    moving_average u_avg_z (.clk(clk),.rst(rst),.valid_in(accel_valid),.new_sample(raw_z),.avg_out(avg_z));

    wire signed [15:0] held_x, held_y, held_z;
    sample_hold u_hold_x (.clk(clk),.rst(rst),.valid_in(accel_valid),.data_in(avg_x),.data_out(held_x));
    sample_hold u_hold_y (.clk(clk),.rst(rst),.valid_in(accel_valid),.data_in(avg_y),.data_out(held_y));
    sample_hold u_hold_z (.clk(clk),.rst(rst),.valid_in(accel_valid),.data_in(avg_z),.data_out(held_z));

    wire shake_raw;
    shake_detection u_shake (
        .clk(clk),.rst(rst),.valid_in(accel_valid),
        .accel_x(raw_x),.accel_y(raw_y),.accel_z(raw_z),
        .shake_detected(shake_raw)
    );
    wire shake_s;
    sample_debouncer #(.HOLD_COUNT(1)) u_deb_shake (
        .clk(clk),.rst(rst),.sample_tick(sample_tick),
        .gesture_in(shake_raw),.gesture_out(shake_s)
    );

    wire tilt_right_raw,tilt_left_raw,tilt_up_raw,tilt_down_raw,tilt_any;
    tilt_detector u_tilt (
        .clk(clk),.rst(rst),.valid_in(accel_valid),
        .shake_active(shake_s),
        .accel_x(held_x),.accel_y(held_y),.accel_z(held_z),
        .tilt_right(tilt_right_raw),.tilt_left(tilt_left_raw),
        .tilt_up(tilt_up_raw),.tilt_down(tilt_down_raw),
        .tilt_detected(tilt_any)
    );

    wire tilt_right_s,tilt_left_s,tilt_up_s,tilt_down_s;
    sample_debouncer #(.HOLD_COUNT(8)) u_deb_right (.clk(clk),.rst(rst),.sample_tick(sample_tick),.gesture_in(tilt_right_raw),.gesture_out(tilt_right_s));
    sample_debouncer #(.HOLD_COUNT(8)) u_deb_left  (.clk(clk),.rst(rst),.sample_tick(sample_tick),.gesture_in(tilt_left_raw), .gesture_out(tilt_left_s));
    sample_debouncer #(.HOLD_COUNT(8)) u_deb_up    (.clk(clk),.rst(rst),.sample_tick(sample_tick),.gesture_in(tilt_up_raw),   .gesture_out(tilt_up_s));
    sample_debouncer #(.HOLD_COUNT(8)) u_deb_down  (.clk(clk),.rst(rst),.sample_tick(sample_tick),.gesture_in(tilt_down_raw), .gesture_out(tilt_down_s));

    wire [2:0] gesture;
    gesture_resolver u_resolver (
        .clk(clk),.rst(rst),.shake_in(shake_s),
        .tilt_right_in(tilt_right_s),.tilt_left_in(tilt_left_s),
        .tilt_up_in(tilt_up_s),.tilt_down_in(tilt_down_s),
        .tilt_right_raw(tilt_right_raw),.tilt_left_raw(tilt_left_raw),
        .tilt_up_raw(tilt_up_raw),.tilt_down_raw(tilt_down_raw),
        .gesture(gesture)
    );

    led_controller u_led (.clk(clk),.rst(rst),.gesture(gesture),.leds(led));

    wire uart_send;
    wire [7:0] uart_byte;
    wire uart_busy;
    uart_msg_sender u_msg (.clk(clk),.rst(rst),.gesture(gesture),.uart_send(uart_send),.uart_data(uart_byte),.uart_busy(uart_busy));
    uart_tx u_uart (.clk(clk),.rst(rst),.send(uart_send),.data_in(uart_byte),.tx(uart_txd),.busy(uart_busy));

endmodule
