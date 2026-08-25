-- Testbench.
-- UUT: led_jukebox
--
-- WARN: Comppile as VHDL 2008.

library ieee;
use ieee.std_logic_1164.all;
-- Color codes.
use work.color_codes_pkg.all;

entity tb_led_jukebox is
end tb_led_jukebox;

architecture behavior of tb_led_jukebox is

  -- Period of simulated clock (100 MHz).
  constant T_clk  : time := 10 ns;

  signal clk      : std_logic := '1';   -- No phase.
  signal resetn   : std_logic := '1';
  signal BTN0     : std_logic := '0';
  signal BTN1     : std_logic := '0';
  
  signal LED0_R   : std_logic;
  signal LED0_G   : std_logic;
  signal LED0_B   : std_logic;

  -- VHDL 2008 only.
  alias drv_end_cycle   is <<signal .tb_led_jukebox.uut.DRV.end_cycle: std_logic>>;
  alias drv_update      is <<signal .tb_led_jukebox.uut.DRV.update: std_logic>>;
  alias drv_r_color     is <<signal .tb_led_jukebox.uut.DRV.r_color: color_code_t>>;
  alias fifo_empty      is <<signal .tb_led_jukebox.uut.fifo_empty: std_logic>>;
  alias fifo_rd_en      is <<signal .tb_led_jukebox.uut.fifo_rd_en: std_logic>>;
  alias fifo_wr_en      is <<signal .tb_led_jukebox.uut.fifo_wr_en: std_logic>>;
  alias fifo_dout       is <<signal .tb_led_jukebox.uut.fifo_dout: color_code_t>>;
  alias fifo_din        is <<signal .tb_led_jukebox.uut.fifo_din: color_code_t>>;

  -- Whether to test FIFO empty output signal on startup.
  -- Should be floating ('X') but is sometimes initialized ('1').
  constant TEST_FIFO_EMPTY_INIT : boolean := false;

begin

  uut: entity work.led_jukebox
    generic map (
      -- One jukebox period is 10 clock periods,
      -- duty cycle 50%: 5 periods LED_OFF, 5 periods LED_ON.
      D => 10,
      RST_SYNC_STAGE => 1
    )
    port map (
      clk => clk,
      resetn => resetn,
      BTN0   => BTN0,
      BTN1   => BTN1,
      LED0_R => LED0_R,
      LED0_G => LED0_G,
      LED0_B => LED0_B );

  -- Simulated clock.
  clk <= not clk after T_clk / 2;

 test_colors_write: process
 begin
    -- FIFO write attempt while uninitialized.
    wait for 4 * T_clk;
    BTN1 <= '0';  -- Blue.
    BTN0 <= '1';
    wait until rising_edge(clk);  -- 50 ns.
    BTN0 <= '0';
    wait for 1 ns;
    assert fifo_wr_en = '0' report "writing to uninitialized FIFO" severity failure;

    -- Skip first enc_cycle at 90 ns to keep FIFO empty until there.
    wait until rising_edge(clk);  -- 60 ns
    wait for 90 ns;  -- 150 ns

    BTN0 <= '1';
    BTN1 <= '1';
    wait for 1 ns;
    assert fifo_wr_en = '1' report "FIFO wr_en not asserted" severity failure;
    assert fifo_din = COLOR_GREEN;
    wait until rising_edge(clk);  -- 160 ns.
    BTN0 <= '0';

    wait until rising_edge(clk);  -- 170 ns.
    BTN0 <= '1';
    BTN1 <= '0';
    wait for 1 ns;
    assert fifo_wr_en = '1' report "FIFO wr_en not asserted" severity failure;
    assert fifo_din = COLOR_BLUE;
    wait until rising_edge(clk);  -- 180 ns.
    BTN0 <= '0';

    wait until rising_edge(clk);  -- 190 ns.
    BTN0 <= '1';
    BTN1 <= '1';
    wait for 1 ns;
    assert fifo_wr_en = '1' report "FIFO wr_en not asserted" severity failure;
    assert fifo_din = COLOR_GREEN;
    wait until rising_edge(clk);  -- 200 ns.
    BTN0 <= '0';

   wait;
 end process test_colors_write;

 test_colors_read: process
 begin
   -- 1st end_cycle pulse emitted by led_driver.
   -- FIFO is empty: we should not rise FIFO rd_en.
   wait for 9 * T_clk;   -- 90 ns
   wait for 1 ns;
   assert drv_end_cycle = '1' report "no end_cycle pulse" severity failure;
   assert fifo_empty = '1' report "FIFO not empty" severity failure;
   assert fifo_rd_en = '0' report "FIFO read while empty" severity failure;

   -- 2nd end_cycle pulse emitted by led_driver.
   -- FIFO is ready: we should now start updating colors.
   wait until rising_edge(clk); -- 100 ns
   wait for 9 * T_clk;  -- 190 ns
   wait for 1 ns;
   assert fifo_empty = '0' report "FIFO empty" severity failure;
   assert fifo_rd_en = '1' report "FIFO rd_en not asserted" severity failure;
   assert drv_r_color = COLOR_RED report "expected COLOR_RED" severity failure;
   assert drv_end_cycle = '1' report "end_cycle not asserted" severity failure;
   assert drv_update = '0' report "FIFO update asserted" severity failure;

   wait until rising_edge(clk); -- 200 ns
   wait for 1 ns;
   assert fifo_empty = '0' report "FIFO empty" severity failure;
   assert fifo_rd_en = '0' report "FIFO rd_en asserted" severity failure;
   assert drv_r_color = COLOR_RED report "expected COLOR_RED" severity failure;
   assert drv_end_cycle = '0' report "end_cycle asserted" severity failure;
   assert drv_update = '1' report "update not asserted" severity failure;

   wait until rising_edge(clk); -- 210 ns
   wait for 1 ns;
   assert fifo_empty = '0' report "FIFO empty" severity failure;
   assert fifo_rd_en = '0' report "FIFO rd_en asserted" severity failure;
   assert drv_r_color = COLOR_GREEN report "expected COLOR_GREEN" severity failure;
   assert drv_end_cycle = '0' report "end_cycle asserted" severity failure;
   assert drv_update = '0' report "update asserted" severity failure;

   wait until rising_edge(clk); -- 220 ns
   wait for 7 * T_clk;   -- 290 ns
   wait for 1 ns;
   assert fifo_empty = '0' report "FIFO empty" severity failure;
   assert fifo_rd_en = '1' report "FIFO rd_en not asserted" severity failure;
   assert drv_r_color = COLOR_GREEN report "expected COLOR_GREEN" severity failure;
   assert drv_end_cycle = '1' report "end_cycle not asserted" severity failure;
   assert drv_update = '0' report "FIFO update asserted" severity failure;

   wait until rising_edge(clk); -- 300 ns
   wait for 1 ns;
   assert fifo_empty = '0' report "FIFO empty" severity failure;
   assert fifo_rd_en = '0' report "FIFO rd_en asserted" severity failure;
   assert drv_r_color = COLOR_GREEN report "expected COLOR_GREEN" severity failure;
   assert drv_end_cycle = '0' report "end_cycle asserted" severity failure;
   assert drv_update = '1' report "update not asserted" severity failure;

   wait until rising_edge(clk); -- 310 ns
   wait for 1 ns;
   assert fifo_empty = '0' report "FIFO empty" severity failure;
   assert fifo_rd_en = '0' report "FIFO rd_en asserted" severity failure;
   assert drv_r_color = COLOR_BLUE report "expected COLOR_BLUE" severity failure;
   assert drv_end_cycle = '0' report "end_cycle asserted" severity failure;
   assert drv_update = '0' report "update asserted" severity failure;

   wait until rising_edge(clk); -- 320 ns
   wait for 7 * T_clk;  -- 390 ns
   wait for 1 ns;
   assert fifo_empty = '0' report "FIFO empty" severity failure;
   assert fifo_rd_en = '1' report "FIFO rd_en not asserted" severity failure;
   assert drv_r_color = COLOR_BLUE report "expected COLOR_BLUE" severity failure;
   assert drv_end_cycle = '1' report "end_cycle not asserted" severity failure;
   assert drv_update = '0' report "FIFO update asserted" severity failure;

   wait until rising_edge(clk); -- 400 ns
   wait for 1 ns;
   assert fifo_empty = '1' report "FIFO empty" severity failure;
   assert fifo_rd_en = '0' report "FIFO rd_en asserted" severity failure;
   assert drv_r_color = COLOR_BLUE report "expected COLOR_BLUE" severity failure;
   assert drv_end_cycle = '0' report "end_cycle asserted" severity failure;
   assert drv_update = '1' report "update not asserted" severity failure;

   wait until rising_edge(clk); -- 410 ns
   wait for 1 ns;
   assert fifo_empty = '1' report "FIFO empty" severity failure;
   assert fifo_rd_en = '0' report "FIFO rd_en asserted" severity failure;
   assert drv_r_color = COLOR_GREEN report "expected COLOR_GREEN" severity failure;
   assert drv_end_cycle = '0' report "end_cycle asserted" severity failure;
   assert drv_update = '0' report "update asserted" severity failure;

   -- FIFO empty, color won't change.
   wait until rising_edge(clk); -- 420 ns
   wait for 7 * T_clk;  -- 490 ns
   wait for 1 ns;
   assert fifo_empty = '1' report "FIFO not empty" severity failure;
   assert fifo_rd_en = '0' report "FIFO rd_en not asserted" severity failure;
   assert drv_r_color = COLOR_GREEN report "expected COLOR_GREEN" severity failure;
   assert drv_end_cycle = '1' report "end_cycle not asserted" severity failure;
   assert drv_update = '0' report "FIFO update asserted" severity failure;
   wait for 2 * T_clk;  -- 510 ns
   wait for 1 ns;
   assert drv_r_color = COLOR_GREEN report "expected COLOR_GREEN" severity failure;

   wait;
 end process test_colors_read;

 test_leds: process
 begin
   wait for 5 * T_clk;
   wait for 1 ns;
   assert LED0_R = '1';
   assert LED0_G = '0';
   assert LED0_B = '0';

   wait until rising_edge(clk);  -- 60 ns
   wait for 9 * T_clk;   -- 150 ns
   wait for 1 ns;
   assert LED0_R = '1';
   assert LED0_G = '0';
   assert LED0_B = '0';

   wait until rising_edge(clk);  -- 160 ns
   wait for 9 * T_clk;   -- 250 ns
   wait for 1 ns;
   assert LED0_R = '0';
   assert LED0_G = '1';
   assert LED0_B = '0';

   wait until rising_edge(clk);  -- 260 ns
   wait for 9 * T_clk;   -- 350 ns
   wait for 1 ns;
   assert LED0_R = '0';
   assert LED0_G = '0';
   assert LED0_B = '1';

   wait until rising_edge(clk);  -- 360 ns
   wait for 9 * T_clk;   -- 450 ns
   wait for 1 ns;
   assert LED0_R = '0';
   assert LED0_G = '1';
   assert LED0_B = '0';

   wait until rising_edge(clk);  -- 460 ns
   wait for 9 * T_clk;   -- 550 ns
   wait for 1 ns;
   assert LED0_R = '0';
   assert LED0_G = '1';
   assert LED0_B = '0';

   wait;
 end process test_leds;

--  process
--  begin
--    --wait for 1005 ns; -- Async, not on clock rising edge.
--    resetn <= '0';
--    wait for 5 * T_clk;
--    resetn <= '1';
--    wait;
--  end process;

end behavior;
