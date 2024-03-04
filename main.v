`timescale 1ns / 1ps
module lab10(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    output [3:0] usr_led,
    
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
    );
//---------------------------------------state machine-------------------------------------------------------------
    reg [3:0] P, P_next;//state for the FSM
    localparam [3:0]  S_MAIN_IDLE = 0, S_MAIN_PLAY = 1, S_MAIN_WAIT= 2, 
                    S_MAIN_WIN = 3, S_MAIN_LOSE =4,S_MAIN_BOMB = 5;

    always@(posedge clk) begin//state machine logic
        if(~reset_n)
            P <= S_MAIN_IDLE;
        else 
            P <= P_next;
    end

    always @(*) begin
        case(P)
            S_MAIN_IDLE:
                if(btn0_pressed) P_next = S_MAIN_WAIT;
                else P_next = P;
            S_MAIN_WAIT:
            if(bomb_happen) P_next = S_MAIN_BOMB;
                else if(btn0_pressed)begin
                    P_next = S_MAIN_PLAY;
                end
                else P_next = P;
            S_MAIN_PLAY:
            if(bomb_happen) P_next = S_MAIN_BOMB;
                
                else if (ball_touch_floor)P_next = S_MAIN_WAIT;
                else P_next <= P;
            S_MAIN_BOMB:
            if(bomb_done)begin
                if(player_score == 6)P_next = S_MAIN_WIN;
                else if(ai_score == 6)P_next = S_MAIN_LOSE;
            end
            else P_next = P;
            S_MAIN_WIN:
                if(btn0_pressed)
                    P_next = S_MAIN_IDLE;
                else P_next = P;
            S_MAIN_LOSE:
                if(btn0_pressed)
                    P_next = S_MAIN_IDLE;
                else P_next = P;
        endcase
    end
//---------------------------------------state machine-------------------------------------------------

//----------------------------------Declare system variables-----------------------------------------------------

    //p1
    reg  [31:0] p1_clock,pika_x_clock,pika_y_clock; 
    wire [9:0]  p_x,p_y;
    wire        p1_region;
    //p2
    reg  [31:0] p2_clock,pika2_x_clock,pika2_y_clock;
    wire [9:0]  p2_x,p2_y;
    wire        p2_region;
    reg [2:0] p2_dir;
    //player collision
    wire p_collide;
    //ball
    reg  [31:0] ball_clock,ball_x_clock,ball_y_clock;
    wire [9:0] ball_x,ball_y;
    wire        ball_region;
    reg [10:0] vx, vy;
    reg vx_dir, vy_dir;
    reg [10:0] ax, ay;
    reg ax_dir, ay_dir;
    //score_right
    wire [9:0]  score_x,score_y;
    assign score_x = 570;
    assign score_y = 10;
    wire        score_region;
    //score_left
    wire [9:0] score2_x,score2_y;
    assign score2_x = 150;
    assign score2_y = 10;
    wire        score2_region;
    //background
    reg [31:0] bg_x_clock,bg_y_clock;
    wire [9:0] bg_x,bg_y;

    //interface (start win lose try ready skin)
    wire [ 9:0] start_x,start_y,win_x,win_y,lose_x,lose_y,try_x,try_y,ready_x,ready_y;
    assign start_x = 320 + START_W;
    assign start_y = 60;
    assign win_x = 320 + WIN_W;
    assign win_y = 80;
    assign lose_x = 320 + LOSE_W;
    assign lose_y = 80;
    assign try_x = 320 + TRY_W;
    assign try_y = 110;
    assign ready_x = 320 + READY_W;
    assign ready_y = 80;
    wire        start_region,win_region,lose_region,try_region,ready_region;
    //skin
    wire [9:0] skin_x,skin_y;
    assign skin_x = 320 + SKIN_W;
    assign skin_y = 110;
    wire skin_region;
    // bomb 
    wire [9:0] bomb_x,bomb_y;
    assign bomb_x = (player_score < 6 && ai_score < 6) ? ball_x : ((player_score == 6) ? p2_x : p_x);
    assign bomb_y =  (player_score == 6 || ai_score == 6) ? 165 : 180;
    //assign bomb_y = 300;
    wire bomb_region;
    //collider
    reg [5:0] collider = 5;
//----------------------------------Declare system variables-----------------------------------------------------
//---------------------------------------sram initial---------------------------------------------------------------

    // declare SRAM control signals
    wire [16:0] sram_addr;
    wire [11:0] data_in;
    wire [11:0] data_out;
    wire        sram_we, sram_en;

    // declare SRAM control signals
    wire [16:0] sramp1_addr;
    wire [11:0] datap1_out;

    // declare SRAM control signals
    wire [16:0] sramball_addr;
    wire [11:0] databall_out;
    // declare SRAM control signals
    wire [16:0] sramscore_addr;
    wire [11:0] datascore_out;
    // declare SRAM control signals
    wire [16:0] sramstart_addr;
    wire [11:0] datastart_out;
    // declare SRAM control signals
    wire [16:0] sramwin_addr;
    wire [11:0] datawin_out;
    // declare SRAM control signals
    wire [16:0] sramlose_addr;
    wire [11:0] datalose_out;
    // declare SRAM control signals
    wire [16:0] sramtry_addr;
    wire [11:0] datatry_out;
    // declare SRAM control signals
    wire [16:0] sramready_addr;
    wire [11:0] dataready_out;
    // declare SRAM control signals
    wire [16:0] srambomb_addr;
    wire [11:0] databomb_out;
    // declare SRAM control signals
    wire [16:0] sramskin_addr;
    wire [11:0] dataskin_out;
//---------------------------------------sram initial---------------------------------------------------------------

//------------------------------------General VGA control signals---------------------------------
    wire vga_clk;         // 50MHz clock for VGA control
    wire video_on;        // when video_on is 0, the VGA controller is sending
                        // synchronization signals to the display device.
    
    wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                        // based for the new coordinate (pixel_x, pixel_y)
    
    wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 639) 
    wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 479)
    
    reg  [11:0] rgb_reg;  // RGB value for the current pixel
    reg  [11:0] rgb_next; // RGB value for the next pixel
    
    // Application-specific VGA signals
    reg  [17:0] pixel_addr;
    reg  [17:0] pixel_p1_addr;
    reg  [17:0] pixel_ball_addr;
    reg  [17:0] pixel_score_addr;
    reg  [17:0] pixel_start_addr;
    reg  [17:0] pixel_win_addr;
    reg  [17:0] pixel_lose_addr;
    reg  [17:0] pixel_try_addr;
    reg  [17:0] pixel_ready_addr;
    reg  [17:0] pixel_bomb_addr;
    reg  [17:0] pixel_skin_addr;
//------------------------------------General VGA control signals---------------------------------

//----------------------------------------------------------------width,height-----------------------------------------------------------------------
    // Declare the video buffer size
    localparam VBUF_W = 320; // video buffer width
    localparam VBUF_H = 240; // video buffer height

    // Set parameters for the fish images

    //pika1
    localparam P1_W      = 64; // Width of the fish.
    localparam P1_H      = 64; // Height of the fish.
    reg [17:0] P1_addr[0:7];   // Address array for up to 8 fish images.
    //ball
    localparam ball_W      = 40; // Width of the fish.
    localparam ball_H      = 40; // Height of the fish.
    reg [17:0] ball_addr[0:3];   // Address array for up to 8 fish images.

    //score
    localparam SCORE_W      = 51; // Width of the fish.
    localparam SCORE_H      = 51; // Height of the fish.
    reg [17:0] score_addr[0:6];   // Address array for up to 8 fish images.

    //start
    localparam START_W      = 178; // Width of the start.
    localparam START_H      = 25; // Height of the start.
    reg [17:0] start_addr;   // Address array for up to start images.

    //win
    localparam WIN_W      = 129; // Width of the win.
    localparam WIN_H      = 25; // Height of the win.
    reg [17:0] win_addr;   // Address array for up to win images.

    //lose
    localparam LOSE_W      = 142; // Width of the lose.
    localparam LOSE_H      = 25; // Height of the lose.
    reg [17:0] lose_addr;   // Address array for up to lose images.

    //try
    localparam TRY_W      = 146; // Width of the again.
    localparam TRY_H      = 23; // Height of the try again.
    reg [17:0] try_addr;   // Address array for up to try again images.

    //ready
    localparam READY_W      = 92; // Width of the ready.
    localparam READY_H      = 25; // Height of the ready.
    reg [17:0] ready_addr;   // Address array for up to ready images.

    //bomb
    localparam BOMB_W      = 64; // Width of the ready.
    localparam BOMB_H      = 64; // Height of the ready.
    reg [17:0] bomb_addr [0:2];   // Address array for up to ready images.

    //skin
    localparam  SKIN_W      = 117; // Width of the ready.
    localparam SKIN_H      = 30; // Height of the ready.
    reg [17:0] skin_addr [0:1];   // Address array for up to ready images.

    // Initializes the fish images starting addresses.
    // Note: System Verilog has an easier way to initialize an array,
    //       but we are using Verilog 2001 :(
    initial begin
    P1_addr[0] = 18'd0;         /* Addr for pika image #1 */
    P1_addr[1] = P1_W*P1_H*1; /* Addr for pika image #2 */
    P1_addr[2] = P1_W*P1_H*2; /* Addr for pika image #3 */
    P1_addr[3] = P1_W*P1_H*3; /* Addr for pika image #4 */
    P1_addr[4] = P1_W*P1_H*3; /* Addr for pika image #2 */
    P1_addr[5] = P1_W*P1_H*2; /* Addr for pika image #3 */
    P1_addr[6] = P1_W*P1_H*1; /* Addr for pika image #4 */
    P1_addr[7] = 0; /* Addr for pika image #4 */
    end

    initial begin
        score_addr[0] = 0;                
        score_addr[1] = SCORE_W*SCORE_H  ; 
        score_addr[2] = SCORE_W*SCORE_H*2; 
        score_addr[3] = SCORE_W*SCORE_H*3; 
        score_addr[4] = SCORE_W*SCORE_H*4; 
        score_addr[5] = SCORE_W*SCORE_H*5; 

        ball_addr[0] <= 18'd0;         
        ball_addr[1] <= ball_W*ball_H; 
        ball_addr[2] <= ball_W*ball_H*2; 
        ball_addr[3] <= ball_W*ball_H*3;

        bomb_addr[0] <= 18'd0;         
        bomb_addr[1] <= BOMB_W*BOMB_H; 
        bomb_addr[2] <= BOMB_W*BOMB_H*2; 

        skin_addr[1] <= 18'd0;         
        skin_addr[0] <= SKIN_W*SKIN_H; 

    end
//----------------------------------------------------------------width,height-----------------------------------------------------------------------


//----------------------------------------------------------------debounce------------------------------------------------------------------------
  wire btn_level, btn2_pressed, btn0_pressed,btn1_pressed,btn3_pressed;

  debounce btn_db0(
    .clk(clk),
    .noisy(usr_btn[0]),
    .debounced(btn0_pressed)
  );

  debounce btn_db1(
    .clk(clk),
    .noisy(usr_btn[1]),
    .debounced(btn1_pressed)
  );
  debounce btn_db2(
    .clk(clk),
    .noisy(usr_btn[2]),
    .debounced(btn2_pressed)
  );
  debounce btn_db3(
    .clk(clk),
    .noisy(usr_btn[3]),
    .debounced(btn3_pressed)
  );
//----------------------------------------------------------------debounce------------------------------------------------------------------------


//----------------------------------------------------------------vga------------------------------------------------------------------------
  // Instiantiate the VGA sync signal generator
  vga_sync vs0(
    .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
    .visible(video_on), .p_tick(pixel_tick),
    .pixel_x(pixel_x), .pixel_y(pixel_y)
  );

  clk_divider#(2) clk_divider0(
    .clk(clk),
    .reset(~reset_n),
    .clk_out(vga_clk)
  );

  // VGA color pixel generator
  assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;
//----------------------------------------------------------------vga------------------------------------------------------------------------

//----------------------------------------------------------------sram------------------------------------------------------------------------
  // ------------------------------------------------------------------------
  // The following code describes an initialized SRAM memory block that
  // stores a 320x240 12-bit seabed image, plus two 64x32 fish images.
  sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(VBUF_W*VBUF_H))
    ram0 (.clk(clk), .we(sram_we), .en(sram_en),
            .addr(sram_addr), .data_i(data_in), .data_o(data_out));

  assign sram_we = &usr_btn; // In this demo, we do not write the SRAM. However, if
                              // you set 'sram_we' to 0, Vivado fails to synthesize
                              // ram0 as a BRAM -- this is a bug in Vivado.
  assign sram_en = 1;          // Here, we always enable the SRAM block.
  assign sram_addr = pixel_addr;
  assign data_in = 12'h000; // SRAM is read-only so we tie inputs to zeros.

  // ------------------------------------------------------------------------
  //p1
  sramp1 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(P1_W*P1_H*4))
    ram1 (.clk(clk), .we(sram_We), .en(sram_en),
            .addr(sramp1_addr), .data_i(data_in), .data_o(datap1_out));

  assign sramp1_addr = pixel_p1_addr;

  // End of the SRAM memory block.
  // ------------------------------------------------------------------------
  // ------------------------------------------------------------------------
  // The following code describes an initialized SRAM memory block that
  // stores a 320x240 12-bit seabed image, plus two 64x32 fish images.
  sramball #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(ball_W*ball_H*4))
    ram2 (.clk(clk), .we(sram_we), .en(sram_en),
            .addr(sramball_addr), .data_i(data_in), .data_o(databall_out));

  assign sramball_addr = pixel_ball_addr;
  // End of the SRAM memory block.
  // ------------------------------------------------------------------------
  // ------------------------------------------------------------------------
  // The following code describes an initialized SRAM memory block that
  // stores a 320x240 12-bit seabed image, plus two 64x32 fish images.
  sramscore #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(SCORE_W*SCORE_H*6))
    ram3 (.clk(clk), .we(sram_we), .en(sram_en),
            .addr(sramscore_addr), .data_i(data_in), .data_o(datascore_out));

  assign sramscore_addr = pixel_score_addr;

  sramstart #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(START_W*START_H))
    ram4 (.clk(clk), .we(sram_we), .en(sram_en),
            .addr(sramstart_addr), .data_i(data_in), .data_o(datastart_out));

  assign sramstart_addr = pixel_start_addr;

  sramwin #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(WIN_W*WIN_H))
    ram5 (.clk(clk), .we(sram_we), .en(sram_en),
            .addr(sramwin_addr), .data_i(data_in), .data_o(datawin_out));

  assign sramwin_addr = pixel_win_addr;

    sramlose #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(LOSE_W*LOSE_H))
    ram6 (.clk(clk), .we(sram_we), .en(sram_en),
            .addr(sramlose_addr), .data_i(data_in), .data_o(datalose_out));

  assign sramlose_addr = pixel_lose_addr;

  sramtry #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(TRY_W*TRY_H))
    ram7 (.clk(clk), .we(sram_we), .en(sram_en),
            .addr(sramtry_addr), .data_i(data_in), .data_o(datatry_out));

  assign sramtry_addr = pixel_try_addr;

  sramready #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(READY_W*READY_H))
    ram8 (.clk(clk), .we(sram_we), .en(sram_en),
            .addr(sramready_addr), .data_i(data_in), .data_o(dataready_out));

  assign sramready_addr = pixel_ready_addr;

  srambomb #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(BOMB_W*BOMB_H * 3))
    ram9 (.clk(clk), .we(sram_we), .en(sram_en),
            .addr(srambomb_addr), .data_i(data_in), .data_o(databomb_out));

  assign srambomb_addr = pixel_bomb_addr;

  sramskin #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(SKIN_W*SKIN_H * 2))
    ram10 (.clk(clk), .we(sram_we), .en(sram_en),
            .addr(sramskin_addr), .data_i(data_in), .data_o(dataskin_out));

  assign sramskin_addr = pixel_skin_addr;
//----------------------------------------------------------------sram------------------------------------------------------------------------

//----------------------------------------------------------bomb animation------------------------------------------------------------------------
    reg [31:0] bomb_clock;
    wire bomb_happen;
    assign bomb_happen = (ai_score == 6|| player_score == 6);
    reg bomb_done;

    always @(posedge clk ) begin
    if(~reset_n || P == S_MAIN_WAIT || P == S_MAIN_PLAY)begin
        bomb_done <= 0;
    end
    else if(bomb_done == 0 && bomb_timer >= 100_000_000 && P == S_MAIN_BOMB)bomb_done <= 1;
    end


    reg [ 3:0] bombstate;
    reg [40:0] bomb_timer;
    always @(posedge clk) begin
        if(~reset_n || bomb_timer >= 100_000_000) bombstate <= 0;
        else if(bomb_timer >= 00_000_000 && bomb_timer < 33_333_333) bombstate <= 1;
        else if(bomb_timer >= 33_333_333 && bomb_timer < 66_666_666) bombstate <= 2;
        else if(bomb_timer >= 66_666_666 && bomb_timer < 99_999_999) bombstate <= 3;
    end
    always @(posedge clk) begin
        if(~reset_n || bombstate == 0 || P == S_MAIN_WAIT || P == S_MAIN_PLAY) begin
            bomb_timer <= 0;
        end
        else if((bombstate == 1 || bombstate == 2 || bombstate == 3) && P == S_MAIN_BOMB)begin
            bomb_timer <= bomb_timer + 1;
        end
    end

    wire bomb_state;
    assign bomb_state = (bombstate > 0) ? bombstate - 1 : 0;
//----------------------------------------------------------bomb animation------------------------------------------------------------------------


//----------------------------------------------------------animation_clock---------------------------------------------------------------------
  always @(posedge clk) begin
    if (~reset_n || p1_clock[31:21] > VBUF_W + P1_W)
      p1_clock <= 0;
    else 
      p1_clock <= p1_clock + 1;
  end

  always @(posedge clk) begin
    if (~reset_n || p2_clock[31:21] > VBUF_W + P1_W)
      p2_clock <= 0;
    else 
      p2_clock <= p2_clock + 1;
  end
  always @(posedge clk) begin
    if (~reset_n)
      ball_clock <= 0;
    else 
      ball_clock <= ball_clock +1;
  end   
//----------------------------------------------------------animation_clock---------------------------------------------------------------------

//----------------------------------------------------------score_update---------------------------------------------------------------------
  wire ball_touch_floor = (ball_y == 430);
  wire touch_player_ground = ball_touch_floor &&  ball_x > 320; 
  wire touch_ai_ground = ball_touch_floor &&  ball_x < 320;
  reg[20:0] player_score,ai_score;

  reg[2:0] pre_ai;

  always @(posedge clk) begin
    if (~reset_n || P_next == S_MAIN_IDLE)begin
      player_score <= 0;
      ai_score <= 0;
      pre_ai <= 0;
    end
    else if(touch_ai_ground && P == S_MAIN_PLAY) begin
        player_score <= player_score + 1;
        pre_ai <= 0;
    end
    else if( touch_player_ground && P == S_MAIN_PLAY)begin
        ai_score <= ai_score + 1;
        pre_ai <= 1;

    end
  end

  reg[5:0] rank;
  always @(posedge clk ) begin
    if(~reset_n)begin
        rank <= 0;
    end
    else if(player_score == 6 && (P_next == S_MAIN_WIN && P == S_MAIN_BOMB))begin
        if(rank != 2)rank <= rank + 1;
        //rank <= (rank + 1 < 3) ? rank + 1 : 2;
    end
  end
//----------------------------------------------------------score_update---------------------------------------------------------------------

//----------------------------------------------------------ball_movement---------------------------------------------------------------------
   wire [9:0] ball_cx, ball_cy, p_cx, p_cy , p2_cx, p2_cy, u_x, u_y, u2_x, u2_y;

  assign ball_cx = ball_x-ball_W;
  assign ball_cy = ball_y-ball_H;
  assign p_cx = p_x-P1_W;
  assign p_cy = p_y-P1_H;
  assign p2_cx = p2_x - P1_W;
  assign p2_cy = p2_y - P1_H;
  assign ball_x = ball_x_clock[31:20];
  assign ball_y = ball_y_clock[31:20];

  assign u_x = (p_cx>ball_cx)?(p_cx-ball_cx):(ball_cx-p_cx);
  assign u_y = (p_cy>ball_cy)?(p_cy-ball_cy):(ball_cy-p_cy);
  assign u2_x = (p2_cx>ball_cx)?(p2_cx-ball_cx):(ball_cx-p2_cx);
  assign u2_y = (p2_cy>ball_cy)?(p2_cy-ball_cy):(ball_cy-p2_cy);

  reg [30:0] time_variable;
  reg [30:0] smash_timer;
  reg smash;

  reg check_player_v;
  reg check_p2_v;

  reg [31:0] player_v_timer;
  reg [31:0] p2_v_timer;

  reg player_v_valid = 1;
  reg p2_v_valid = 1;

  always @(posedge clk) begin
      if(~reset_n || smash_timer==120_000_000 || P == S_MAIN_WAIT) begin
          smash_timer <= 0;
      end
      else if(smash && P == S_MAIN_PLAY)begin
          smash_timer <= smash_timer + 1;
      end
  end

  always @(posedge clk) begin
    if(~reset_n || smash_timer==120_000_000|| P == S_MAIN_WAIT) begin
        smash<=0;
    end
    else if((btn3_pressed && ball_x >= p_x-P1_W*2 - 15 && ball_x - ball_W * 2 < p_x + 15 && ball_y >= p_y - P1_H * 2 - 15 && ball_y - ball_H * 2 < p_y + 15 )&& P == S_MAIN_PLAY) begin
        smash<=1;
    end
  end
  

  always @(posedge clk) begin
      if(~reset_n || player_v_timer==1_000_000_000|| P == S_MAIN_WAIT) begin
          player_v_timer <= 0;
      end
      else if(~player_v_valid && P == S_MAIN_PLAY)begin
          player_v_timer <= player_v_timer + 1;
      end
  end

  always @(posedge clk) begin
    if(~reset_n || player_v_timer==1_000_000_000|| P == S_MAIN_WAIT) begin
        player_v_valid<=1;
    end
    else if(check_player_v&& P == S_MAIN_PLAY) begin
        player_v_valid<=0;
    end
  end

  always @(posedge clk) begin
      if(~reset_n || p2_v_timer==1_000_000_000|| P == S_MAIN_WAIT) begin
          p2_v_timer <= 0;
      end
      else if(~p2_v_valid&& P == S_MAIN_PLAY)begin
          p2_v_timer <= p2_v_timer + 1;
      end
  end

  always @(posedge clk) begin
    if(~reset_n || p2_v_timer==1_000_000_000|| P == S_MAIN_WAIT) begin
        p2_v_valid<=1;
    end
    else if(check_p2_v&& P == S_MAIN_PLAY) begin
        p2_v_valid<=0;
    end
  end

  always @(posedge clk) begin
      if(~reset_n || time_variable == 10_000_000|| P == S_MAIN_WAIT) begin
          time_variable <= 0;
      end
      else if(P == S_MAIN_PLAY)begin
          time_variable <= time_variable + 1;
      end
  end
  always @(posedge clk) begin
      if(~reset_n|| P == S_MAIN_WAIT) begin
          vx<=3;
          vy<=0;
      end
      else if(P == S_MAIN_PLAY)begin
      
        if(ball_y  >= 480 - ball_H*2)  begin
            vy <= 7;
        end
        else if(vx>15) vx<=15;
        else if(vy>15) vy<=15;
        else if(time_variable == 10_000_000) begin
            if(vy_dir==0) vy <= vy - 1;
            else if(vy_dir==1) vy  <= vy + 1;
            if(smash) begin 
              vx <= vx - 1;
              vy <= vy - 1;
            end
            else if(vx>3) vx <= vx - 1;
        end 
        else if((btn3_pressed && ball_x >= p_x-P1_W*2 - 15 && ball_x - ball_W * 2 < p_x + 15 && ball_y >= p_y - P1_H * 2 - 15 && ball_y - ball_H * 2 < p_y + 15 )) begin
            vy <= 15; 
            vx <= 15;
        end
        else if(check_player_v&&player_v_valid) begin
            if(vx_dir&&usr_btn[0]) vx<=vx+6;
            else if(vx_dir&&usr_btn[2]) vx<=vx-6;//(vx>=6)?(vx-6):(1);
            else if(~vx_dir&&usr_btn[0]) vx<=vx-6;
            else if(~vx_dir&&usr_btn[2]) vx<=vx+6;
        end
        else if(check_p2_v&&p2_v_valid) begin
            if(vx_dir&&p2_dir==1) vx<=vx+6;
            else if(vx_dir&&p2_dir==0) vx<=vx-6;
            else if(~vx_dir&&p2_dir==1) vx<=vx-6;
            else if(~vx_dir&&p2_dir==0) vx<=vx+6;
        end
      end
  end

  reg [5:0] collide_cnt;
  always @(posedge clk) begin
    if (~reset_n|| P == S_MAIN_WAIT) begin
      ball_y_clock[31:20] <= 80;
      vx_dir<=1;
      vy_dir<=1;
      if(~pre_ai)ball_x_clock[31:20] <= 500;
      else if(pre_ai)ball_x_clock[31:20] <= 200;
      
      check_player_v <= 0;
      check_p2_v <= 0;
      collide_cnt<=0;
    end
    else if(P == S_MAIN_PLAY)begin
    //----------------------------------------------higest point--------------------------------------------------
      if(vy_dir==0&&vy==0) 
          vy_dir <= 1;
    //----------------------------------------------higest point--------------------------------------------------
    //----------------------------------------------netCollision--------------------------------------------------
      else if(vx_dir&&ball_x>=320-5-5 && ball_x-ball_W*2 < 320-5 && ball_y>=290 && ball_y-ball_H<480) begin
        vx_dir<=0;
        ball_x_clock[31:20] <= 320-5-5-2;
      end
      else if(~vx_dir&&ball_x>=320+5 && ball_x-ball_W*2 < 320+5+5 && ball_y>=290 && ball_y-ball_H<480) begin
        vx_dir<=1;
        ball_x_clock[31:20] <= 320+5+5+2+ball_W*2;
      end
      else if(ball_x>=320-5 && ball_x-ball_W*2 < 320+5 && ball_y>=290-5 && ball_y-ball_H<290+5) begin
        vy_dir<=0;
        ball_y_clock[31:20] <= 290-5-2;
      end
    //----------------------------------------------netCollision--------------------------------------------------
    //----------------------------------------------playerCollision--------------------------------------------
      else if(ball_region&&p1_region&&datap1_out!=12'h0f0&&databall_out!=12'h0f0) begin // collide using big square;
        if(u_x>u_y) begin
          if(vx_dir) begin
            vx_dir <= 0;
            ball_x_clock[31:20] <= ball_x - vx -1;
          end
          else if(~vx_dir) begin
            vx_dir <= 1;
            ball_x_clock[31:20] <= ball_x + vx +1; 
          end 
        end
        else begin
          if(vy_dir) begin
            vy_dir <= 0;
            ball_y_clock[31:20] <= ball_y - vy -1;
          end
          else if(~vy_dir) begin
            vy_dir <= 1;
            ball_y_clock[31:20] <= ball_y + vy +1;
          end
        end
        check_player_v <= 1;
        collide_cnt<=collide_cnt+1;
      end
    //----------------------------------------------playerCollision--------------------------------------------
    //----------------------------------------------computerCollision--------------------------------------------
     else if(ball_region&&p2_region&&datap1_out!=12'h0f0&&databall_out!=12'h0f0) begin // collide using big square;
        if(u2_x>u2_y) begin
          if(vx_dir) begin
            vx_dir <= 0;
            ball_x_clock[31:20] <= ball_x - vx -1;
          end
          else if(~vx_dir) begin
            vx_dir <= 1;
            ball_x_clock[31:20] <= ball_x + vx +1; 
          end 
        end
        else begin
          if(vy_dir) begin
            vy_dir <= 0;
            ball_y_clock[31:20] <= ball_y - vy -1;
          end
          else if(~vy_dir) begin
            vy_dir <= 1;
            ball_y_clock[31:20] <= ball_y + vy +1;
          end
        end
        check_p2_v<=1;
      end
    //----------------------------------------------computerCollision--------------------------------------------
    //----------------------------------------------boundCollision--------------------------------------------
      else if(vx_dir&&ball_x >= 640) begin
          ball_x_clock[31:20] <= 638;
          vx_dir<=0;
      end
      else if(~vx_dir&&ball_x<=0 + ball_W*2) begin
          ball_x_clock[31:20] <= 2 + ball_W*2;
          vx_dir<=1;
      end
      else if(vy_dir&&ball_y >= 430) begin
          ball_y_clock[31:20] <= 430-2;
          vy_dir<=0;
      end
      else if(~vy_dir&&ball_y-ball_H*2<=0) begin
          ball_y_clock[31:20] <= ball_H*2+2;
          vy_dir<=1;
      end
    //----------------------------------------------boundCollision--------------------------------------------
    //----------------------------------------------move--------------------------------------------
      else begin
          if(vx_dir) ball_x_clock <= ball_x_clock + vx;
          else if (~vx_dir) ball_x_clock <= ball_x_clock - vx;
          if(vy_dir) ball_y_clock <= ball_y_clock + vy;
          else if(~vy_dir) ball_y_clock <= ball_y_clock - vy;
          check_player_v <= 0;
          check_p2_v <= 0;
      end
    //----------------------------------------------move--------------------------------------------
    end
  end
//----------------------------------------------------------ball_movement---------------------------------------------------------------------

//----------------------------------------------------------random_generator---------------------------------------------------------------------
  reg [31:0] seed;
  wire [31:0] random;
  assign random = seed;
  // assign usr_led = random[31:28];
  always @(posedge clk) begin
    if (~reset_n) begin
      seed <= 32'h12345678;
    end 
    else begin
      seed <= seed ^ (seed << 13);
    end
  end
//----------------------------------------------------------random_generator---------------------------------------------------------------------

//----------------------------------------------------------player_movement---------------------------------------------------------------------
  assign p_x = pika_x_clock[31:20];                    
  assign p_y = pika_y_clock[31:20]; 
  
  reg speedup;
  reg [40:0] speedup_timer;
  reg movementConstraint;
  always @(posedge clk) begin
      if(~reset_n || speedup_timer > 10_000_000) speedup <= 0;
      else if(btn3_pressed && p_y == 430) speedup <= 1;
  end
  always @(posedge clk) begin
      if(~reset_n || speedup ==0) begin
          speedup_timer <= 0;
      end
      else if(speedup ==1)begin
          speedup_timer <= speedup_timer + 1;
      end
  end

  // always @(posedge clk) begin
  //   if(~reset_n) begin
  //     movementConstraint <= 1;
  //   end
  //   else if(usr_btn[3]) movementConstraint <= 0;
  // end

  always @(posedge clk) begin
      if (~reset_n|| P == S_MAIN_WAIT) begin
          pika_x_clock[31:20] <= 560;
      end
      else if(P == S_MAIN_PLAY) begin
          if(speedup == 1 && usr_btn[0] && p_x < 640 && ~p_collide)
            pika_x_clock <= pika_x_clock + 6;
          else if(speedup == 1 && usr_btn[2] && p_x >=  320+P1_W*2)
            pika_x_clock <= pika_x_clock - 6;
          else if(usr_btn[0] && p_x < 640 && ~p_collide)
            pika_x_clock <= pika_x_clock + 3;
          else if(usr_btn[2] && p_x >=  320+P1_W*2)begin
            pika_x_clock <= pika_x_clock - 3;
          end
          else begin
            pika_x_clock <= pika_x_clock;
          end
        // if(~p_collide) begin
        //   if(speedup == 1 && usr_btn[0] && p_x < 640 && ~p_collide)
        //     pika_x_clock <= pika_x_clock + 6;
        //   else if(speedup == 1 && usr_btn[2] && ((movementConstraint && p_x >=  320+P1_W*2) || (~movementConstraint && ~p_collide)))
        //     pika_x_clock <= pika_x_clock - 6;
        //   else if(usr_btn[0] && p_x < 640 && ~p_collide)
        //     pika_x_clock <= pika_x_clock + 3;
        //   else if(usr_btn[2] && ((movementConstraint && p_x >=  320+P1_W*2) || (~movementConstraint && ~p_collide)))begin
        //     pika_x_clock <= pika_x_clock - 3;
        //   end
        //   else begin
        //     pika_x_clock <= pika_x_clock;
        //   end
        // end
        // else begin
        //   // if(usr_btn[0]&&~speedup) pika_x_clock[31:20] <= pika_x_clock[31:20] - 2;//teleport bug
        //   // else if(usr_btn[0]&&speedup) pika_x_clock[31:20] <= pika_x_clock[31:20] - 2; //teleport bug
        //   // else if(usr_btn[2]&&~speedup) pika_x_clock[31:20] <= pika_x_clock[31:20] + 2;//teleport bug
        //   // else if(usr_btn[2]&&speedup) pika_x_clock[31:20] <= pika_x_clock[31:20] + 2;//teleport bug
        // end
      end
  end

  reg [2:0] jump;
  reg [40:0] timer;
  always @(posedge clk) begin
      if(~reset_n || timer > 100_000_000 || P == S_MAIN_WAIT) jump <= 0;
      else if(btn1_pressed && P == S_MAIN_PLAY) jump <= 1;
  end
  always @(posedge clk) begin
      if(~reset_n || jump ==0 || P == S_MAIN_WAIT) begin
          timer <= 0;
      end
      else if(jump ==1)begin
          timer <= timer + 1;
      end
  end

  always @(posedge clk) begin
      if(~reset_n || jump == 0 || P == S_MAIN_WAIT)
          pika_y_clock[31:20] <=430;
      else if(jump && timer < 50_000_000&& P == S_MAIN_PLAY) begin
          pika_y_clock <= pika_y_clock - 4;
      end
      else if(jump && timer < 100_000_000 && timer > 50_000_000&& P == S_MAIN_PLAY) begin
          pika_y_clock <= pika_y_clock + 4;
      end
  end
//----------------------------------------------------------player_movement---------------------------------------------------------------------


//----------------------------------------------------------hit_pikachu---------------------------------------------------------------------
  // reg hit;
  // reg [10:0] hitRange;
  // reg [30:0] hit_timer;
  // reg [10:0] hit_vx;
  // reg [30:0] hit_delta_timer;

  // always @(posedge clk) begin
  //   if(~reset_n || hit_timer==120_000_000|| P == S_MAIN_WAIT) begin
  //       hit<=0;
  //   end
  //   else if(p_x-P1_W*2-hitRange < p2_x && usr_btn[3] && P == S_MAIN_PLAY) begin
  //       hit<=1;
  //   end
  // end

  // always @(posedge clk) begin
  //   if(~reset_n || hit_delta_timer==1_000_000 || P == S_MAIN_WAIT) begin
  //       hit_delta_timer <= 0;
  //   end
  //   else if(P == S_MAIN_PLAY)begin
  //       hit_delta_timer <= hit_delta_timer + 1;
  //   end
  // end

  // always @(posedge clk) begin
  //   if(~reset_n || hit_timer==120_000_000 || P == S_MAIN_WAIT) begin
  //       hit_timer <= 0;
  //   end
  //   else if(hit && P == S_MAIN_PLAY)begin
  //       hit_timer <= hit_timer + 1;
  //   end
  // end

  // always @(posedge clk) begin
  //   if(!reset_n || P == S_MAIN_IDLE|| P == S_MAIN_WAIT) begin
  //     hit_vx <= 0;
  //     hitRange <= 10;
  //   end
  //   else if(P==S_MAIN_PLAY) begin
  //     if(p_x-P1_W*2-hitRange < p2_x && usr_btn[3] && P == S_MAIN_PLAY) hit_vx<=15;
  //     else if(hit && hit_delta_timer==1_000_000 && hit_vx>=0) hit_vx <= (hit_vx>=1)?(hit_vx-1):(0);
  //   end
  // end
//----------------------------------------------------------hit_pikachu---------------------------------------------------------------------

//----------------------------------------------------------computer_movement---------------------------------------------------------------------
  // reg [10:0] cpu_vx;
  // reg cpu_vx_dir;200
  reg [30:0] decision_timer;
  reg [2:0] random_value;
  assign usr_led = random_value;
  // assign p_collide = p_x-P1_W*2 <= p2_x && p_x >= p2_x-P1_W*2 && p_y-P1_H*2 <= p2_y && p_y >= p2_y-P1_H*2;
  assign p2_x = pika2_x_clock[31:20];  
  // assign p2_y = pika2_y_clock[31:20]; 
  // assign p2_x = 0 + P1_W*2+2;                    
  assign p2_y = 430; 



  always @(posedge clk) begin
    if(~reset_n || decision_timer==50_000_000 || P == S_MAIN_WAIT) begin
        decision_timer <= 0;
    end
    else if(P == S_MAIN_PLAY)begin
        decision_timer <= decision_timer + 1;
    end
  end

  always @(posedge clk) begin
      if (~reset_n|| P == S_MAIN_WAIT) begin
          pika2_x_clock[31:20] <= 200;
          p2_dir <= 2;
          random_value<=0;
      end
      else if(P == S_MAIN_PLAY) begin
        // if(~p_collide) begin
          // if(~hit) begin
            if(ball_x > 0 + P1_W && ball_x < 320 && p2_x >= 0+P1_W*2 && p2_x < 320) begin
              if(ball_x > p2_x) begin
                pika2_x_clock <= pika2_x_clock+3;
                p2_dir <= 1;
              end
              else if(ball_x-ball_W*2 < p2_x-P1_W*2) begin
                pika2_x_clock <= pika2_x_clock-3;
                p2_dir <= 0;
              end
              else begin
                p2_dir <= 2;
              end
            end
            // else begin //not moving
            //   if(decision_timer==100_000_000) begin
            //     random_value <= random%3;
            //   end
            //   if(random_value==1 && p2_x >= 0+P1_W*2 && p2_x < 320) begin
            //     pika2_x_clock <= pika2_x_clock+3;
            //     p2_dir <= 1;
            //   end
            //   else if(random_value==0 && p2_x >= 0+P1_W*2 && p2_x < 320) begin
            //     pika2_x_clock <= pika2_x_clock-3;
            //     p2_dir <= 0;
            //   end
            //   else if(random_value==2 && p2_x >= 0+P1_W*2 && p2_x < 320) begin
            //     pika2_x_clock <= pika2_x_clock;
            //     p2_dir <= 2;
            //   end
            // end
          // end
          // else if(hit) begin
          //   if(p2_x > 0+P1_W*2)
          //     pika2_x_clock <= pika2_x_clock-hit_vx;
          // end
          // else begin
          //   pika2_x_clock <= pika2_x_clock;
          // end
        // end
        // else begin
        //   if(p2_dir==1) begin
        //     p2_dir <= 0;
        //     pika2_x_clock[31:20] <= pika2_x_clock[31:20] - 2;
        //   end
        //   else if(p2_dir==0) begin
        //     p2_dir <= 1;
        //     pika2_x_clock[31:20] <= pika2_x_clock[31:20] + 2;
        //   end
        // end
      end
  end
//----------------------------------------------------------computer_movement---------------------------------------------------------------------

//----------------------------------------------------------background_shake---------------------------------------------------------------------
  reg [40:0] shake_x_timer;
  reg [40:0] shake_delta_timer;
  reg [5:0] test;
  assign bg_x = bg_x_clock[31:20];
  assign bg_y = bg_y_clock[31:20];

  always @(posedge clk) begin
      if(~reset_n || shake_x_timer==120_000_000 || P == S_MAIN_WAIT) begin
          shake_x_timer <= 0;
      end
      else if(P == S_MAIN_PLAY)begin
          shake_x_timer <= shake_x_timer + 1;
      end
  end

  always @(posedge clk) begin
    if(~reset_n || shake_delta_timer==3_000_000 || P == S_MAIN_WAIT) begin
      shake_delta_timer <= 0;
    end
    else if(P == S_MAIN_PLAY && smash_timer<=25_000_000)begin
      shake_delta_timer <= shake_delta_timer+1;
    end
  end

  always @(posedge clk) begin
      if (~reset_n|| P == S_MAIN_WAIT) begin
          bg_x_clock[31:20] <= 640;
          bg_y_clock[31:20] <= 480;
          test <= 1;
      end
      else if(P == S_MAIN_PLAY) begin
        if((smash && smash_timer<=25_000_000) && shake_delta_timer==3_000_000) begin
          bg_x_clock[31:20] <= bg_x_clock[31:20]+(shake_x_timer[21:20]*(shake_x_timer[21:20]-2)*(shake_x_timer[21:20]-4));
          bg_y_clock[31:20] <= bg_y_clock[31:20]+(shake_x_timer[21:20]*(shake_x_timer[21:20]-2)*(shake_x_timer[21:20]-4));
        end
        else if(~(smash && smash_timer<=25_000_000)) begin
          bg_x_clock[31:20] <= 640;
          bg_y_clock[31:20] <= 480;
        end
        if(usr_btn[3]) test<=test+1;
        else if(usr_btn[1]) test<=test-1;
      end
  end
//----------------------------------------------------------background_shake---------------------------------------------------------------------

//----------------------------------------------------------render---------------------------------------------------------------------
  //----------------------------------------------------------region---------------------------------------------------------------------
    assign p1_region = 
                ((pixel_y + 64*2-1) >= p_y && pixel_y < p_y + 1)&&
                ((pixel_x + 64*2-1) >= p_x && pixel_x < p_x + 1);

    assign p2_region = 
                ((pixel_y + P1_H*2-1) >= p2_y && pixel_y < p2_y + 1) &&
                ((pixel_x + P1_W*2-1) >= p2_x && pixel_x < p2_x + 1);

    assign ball_region =
              ((pixel_y + ball_H*2-1) >= ball_y && pixel_y < ball_y + 1)&&
              ((pixel_x + ball_W*2-1) >= ball_x && pixel_x < ball_x + 1);

    assign score_region =
              (pixel_y >= (score_y<<1) && pixel_y < (score_y+SCORE_H)<<1 &&
              (pixel_x + 101) >= score_x && pixel_x <  score_x + 1 ) || 
              (pixel_y >= (score2_y<<1) && pixel_y < (score2_y+SCORE_H)<<1 &&
              (pixel_x + 101) >= score2_x && pixel_x <  score2_x + 1 );

    assign start_region =
              pixel_y >= (start_y<<1) && pixel_y < (start_y+START_H)<<1 &&
              (pixel_x + (START_W * 2 - 1)) >= start_x && pixel_x < start_x + 1;

    assign win_region =
              pixel_y >= (win_y<<1) && pixel_y < (win_y+WIN_H)<<1 &&
              (pixel_x + (WIN_W * 2 - 1)) >= win_x && pixel_x < win_x + 1;

    assign lose_region =
              pixel_y >= (lose_y<<1) && pixel_y < (lose_y+LOSE_H)<<1 &&
              (pixel_x + (LOSE_W * 2 - 1)) >= lose_x && pixel_x < lose_x + 1;
    assign try_region =
              pixel_y >= (try_y<<1) && pixel_y < (try_y+TRY_H)<<1 &&
              (pixel_x + (TRY_W * 2 - 1)) >= try_x && pixel_x < try_x + 1;
    assign ready_region =
              pixel_y >= (ready_y<<1) && pixel_y < (ready_y+READY_H)<<1 &&
              (pixel_x + (READY_W * 2 - 1)) >= ready_x && pixel_x < ready_x + 1;
    
    assign bomb_region =
              pixel_y >= (bomb_y<<1) && pixel_y < (bomb_y+BOMB_H)<<1 &&
              (pixel_x + (BOMB_W * 2 - 1)) >= bomb_x && pixel_x < bomb_x + 1;

    assign skin_region =
              pixel_y >= (skin_y<<1) && pixel_y < (skin_y+SKIN_H)<<1 &&
              (pixel_x + (SKIN_W * 2 - 1)) >= skin_x && pixel_x < skin_x + 1;
  //----------------------------------------------------------region---------------------------------------------------------------------

  //----------------------------------------------------------background_output---------------------------------------------------------------------
    always @ (posedge clk) begin
      if (~reset_n)
        pixel_addr <= 0;
      else
        pixel_addr <= ((pixel_y +(VBUF_H*2-1)-bg_y)>>1)*VBUF_W +
                      ((pixel_x +(VBUF_W*2-1)-bg_x)>>1);
        //pixel_addr <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
    end
  //----------------------------------------------------------background_output---------------------------------------------------------------------

  //----------------------------------------------------------score_output---------------------------------------------------------------------
    always@ (posedge clk)begin
      if(~reset_n)pixel_score_addr<= 0;
      else if(score_region && pixel_x > 320) 
          pixel_score_addr <= score_addr[(player_score < 6) ? player_score : 5] +
                      ((pixel_y>>1)-score_y)*SCORE_W +
                      ((pixel_x +(SCORE_W*2-1)-score_x)>>1);
        else if(score_region  && pixel_x < 320)
        pixel_score_addr <= score_addr[(ai_score < 6) ? ai_score : 5] +
                      ((pixel_y>>1)-score2_y)*SCORE_W +
                      ((pixel_x +(SCORE_W*2-1)-score2_x)>>1);
      else pixel_score_addr <= 0;
    end
  //----------------------------------------------------------score_output---------------------------------------------------------------------

  //----------------------------------------------------------player_output---------------------------------------------------------------------
    always @ (posedge clk) begin
        if (~reset_n)
            pixel_p1_addr <= 0;
        else if(p1_region)
          pixel_p1_addr <= P1_addr[p1_clock[25:23]] +
                ((pixel_y +(P1_H*2-1)-p_y)>>1)*P1_W +
                ((pixel_x +(P1_W*2-1)-p_x)>>1);
        else if(p2_region)
          pixel_p1_addr <= P1_addr[p2_clock[25:23]] +
                ((pixel_y +(P1_H*2-1)-p2_y)>>1)*P1_W +
                P1_W*2 - ((pixel_x +(P1_W*2-1)-p2_x)>>1);
        else pixel_p1_addr  <= 0;
    end
  //----------------------------------------------------------player_output---------------------------------------------------------------------

  //----------------------------------------------------------ball_output---------------------------------------------------------------------
    always @ (posedge clk) begin
      if (~reset_n)
        pixel_ball_addr <= 0;
      else if (ball_region)
        pixel_ball_addr <= ball_addr[ball_clock[25:23]] +//c
                          ((pixel_y +(ball_H*2-1)-ball_y)>>1)*ball_W +
                          ((pixel_x +(ball_W*2-1)-ball_x)>>1);
      else
        // Scale up a 320x240 image for the 640x480 display.
        // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
        pixel_ball_addr <= 0;
    end
  //----------------------------------------------------------ball_output---------------------------------------------------------------------
  //---------------------------------------------------------start win end try ready output---------------------------------------------------------------
    always @ (posedge clk) begin
        if (~reset_n)
            pixel_start_addr <= 0;
        else if (start_region)
            pixel_start_addr <= start_addr +
                        ((pixel_y>>1)-start_y)*START_W +
                        ((pixel_x +(START_W*2-1)-start_x)>>1);
        else
            // Scale up a 320x240 image for the 640x480 display.
            // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
            pixel_start_addr <= 0;
        end

    always @ (posedge clk) begin
        if (~reset_n)
            pixel_win_addr <= 0;
        else if (win_region)
            pixel_win_addr <= win_addr +
                        ((pixel_y>>1)-win_y)*WIN_W +
                        ((pixel_x +(WIN_W*2-1)-win_x)>>1);
        else
            // Scale up a 320x240 image for the 640x480 display.
            // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
            pixel_win_addr <= 0;
        end

    always @ (posedge clk) begin
        if (~reset_n)
            pixel_lose_addr <= 0;
        else if (lose_region)
            pixel_lose_addr <= lose_addr +
                        ((pixel_y>>1)-lose_y)*LOSE_W +
                        ((pixel_x +(LOSE_W*2-1)-lose_x)>>1);
        else
            // Scale up a 320x240 image for the 640x480 display.
            // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
            pixel_lose_addr <= 0;
        end
    always @ (posedge clk) begin
        if (~reset_n)
            pixel_try_addr <= 0;
        else if (try_region)
            pixel_try_addr <= try_addr +
                        ((pixel_y>>1)-try_y)*TRY_W +
                        ((pixel_x +(TRY_W*2-1)-try_x)>>1);
        else
            // Scale up a 320x240 image for the 640x480 display.
            // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
            pixel_try_addr <= 0;
        end

    always @ (posedge clk) begin
        if (~reset_n)
            pixel_ready_addr <= 0;
        else if (ready_region)
            pixel_ready_addr <= ready_addr +
                        ((pixel_y>>1)-ready_y)*READY_W +
                        ((pixel_x +(READY_W*2-1)-ready_x)>>1);
        else
            // Scale up a 320x240 image for the 640x480 display.
            // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
            pixel_ready_addr <= 0;
        end

    always @ (posedge clk) begin
        if (~reset_n)
            pixel_bomb_addr <= 0;
        else if (bomb_region)
            pixel_bomb_addr <= bomb_addr[bomb_state] +
                        ((pixel_y>>1)-bomb_y)*BOMB_W +
                        ((pixel_x +(BOMB_W*2-1)-bomb_x)>>1);
        else
            // Scale up a 320x240 image for the 640x480 display.
            // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
            pixel_bomb_addr <= 0;
        end

    always @ (posedge clk) begin
        if (~reset_n)
            pixel_skin_addr <= 0;
        else if (skin_region)
            pixel_skin_addr <= skin_addr[black] +
                        ((pixel_y>>1)-skin_y)*SKIN_W +
                        ((pixel_x +(SKIN_W*2-1)-skin_x)>>1);
        else
            // Scale up a 320x240 image for the 640x480 display.
            // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
            pixel_skin_addr <= 0;
        end
  //---------------------------------------------------------start win end try ready output---------------------------------------------------------------
  
  //----------------------------------------------------------output_render----------------------------------------------------------------------
    always @(posedge clk) begin
      if (pixel_tick) rgb_reg <= rgb_next;
    end

    ///////black yellow switch/////////////
        reg[2:0] black;
        always @(posedge clk ) begin
            if(~reset_n || P == S_MAIN_IDLE)begin
            if(black == 0 && btn1_pressed)black <= 1;
            else if(black == 1 && btn1_pressed) black <= 0;
            end

        end
    
    always @(posedge clk) begin
        if (~video_on)
            rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.

        else if((P == S_MAIN_IDLE) && start_region && datastart_out != 12'h0f0)begin
                rgb_next = datastart_out;
        end

        else if((P == S_MAIN_IDLE) && skin_region && dataskin_out != 12'h0f0)begin
                rgb_next = dataskin_out;
        end

         else if((P == S_MAIN_BOMB || ball_touch_floor) &&bomb_region&&databomb_out != 12'h0f0)begin
                rgb_next = databomb_out;
        end

        else if(P == S_MAIN_WAIT && ready_region &&dataready_out != 12'h0f0 )
            rgb_next = dataready_out;

        else if((P == S_MAIN_IDLE || P == S_MAIN_PLAY || P == S_MAIN_WAIT || P == S_MAIN_BOMB) && (p1_region || p2_region) &&datap1_out != 12'h0f0 )begin
            if(black == 1)rgb_next = (datap1_out != 12'hff0 ) ?  datap1_out : 12'h888;
            else if(black == 0)rgb_next = datap1_out;
        end
        else if((P == S_MAIN_PLAY || P == S_MAIN_WAIT) &&ball_region && databall_out!= 12'h0f0)begin
            if(rank == 0)rgb_next = databall_out;
            else if(rank == 1) rgb_next = (databall_out != 12'he12) ? databall_out : 12'hafe;
            else if(rank == 2) rgb_next = (databall_out != 12'he12) ? databall_out : 12'h808;

        end
        else if((P == S_MAIN_PLAY || P == S_MAIN_WAIT|| P == S_MAIN_BOMB) && score_region && datascore_out != 12'h0f0)
            rgb_next = datascore_out;
        
        else if(P == S_MAIN_WIN && win_region && datawin_out != 12'h0f0)
            rgb_next = datawin_out;
        else if(P == S_MAIN_LOSE && lose_region && datalose_out != 12'h0f0)
            rgb_next = datalose_out;
        else if((P == S_MAIN_LOSE || P == S_MAIN_WIN) && try_region && datatry_out != 12'h0f0)
            rgb_next = datatry_out;
        else 
            rgb_next = data_out;
    end
  //----------------------------------------------------------output_render----------------------------------------------------------------------

//----------------------------------------------------------render---------------------------------------------------------------------
endmodule

//----------------------------------------------------------------debounce_module------------------------------------------------------------------------
  module debounce (clk,noisy,debounced);
      input wire clk, noisy;
      output wire debounced;
      reg  [31:0] cnt;

      always @ (posedge clk) begin
          if (noisy) cnt <= cnt + 1;
          else cnt <= 0;
      end
      assign debounced = (cnt == 1_000_000) ? 1 : 0;
  endmodule
//----------------------------------------------------------------debounce_module------------------------------------------------------------------------

