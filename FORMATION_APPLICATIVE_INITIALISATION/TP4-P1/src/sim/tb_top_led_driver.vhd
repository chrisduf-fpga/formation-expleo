-- Testbench.
-- UUT: top_led_driver

library ieee;
use ieee.std_logic_1164.all;

entity tb_top_led_driver is
end tb_top_led_driver;

architecture behavior of tb_top_led_driver is

  -- Period of simulated 100 MHz clock.
  constant T_clk  : time := 10 ns;

  -- FIXME: How to avoid copy-paste these.
  constant COLOR_RED    : std_logic_vector(1 downto 0) := "01";
  constant COLOR_GREEN  : std_logic_vector(1 downto 0) := "10";
  constant COLOR_BLUE   : std_logic_vector(1 downto 0) := "11";
  constant COLOR_NONE   : std_logic_vector(1 downto 0) := "00";

  -- Entity I/O map.
  signal clk        : std_logic := '0';  -- LOW at t0, 5 ns phase.
  signal resetn     : std_logic := '1';  -- Do not assert nReset at startup.
  signal w_btn0     : std_logic := '0';  -- BTN0 LOW on startup.
  signal w_btn1     : std_logic := '0';  -- BTN1 LOW on startup.
  signal LED0_R     : std_logic;
  signal LED0_G     : std_logic;
  signal LED0_B     : std_logic;

begin

  uut: entity work.top_led_driver
    generic map (D => 10)
    port map (
      clk => clk,
      resetn => resetn,
      -- Update enabled button.
      BTN0   => w_btn0,
      -- Color selection button.
      -- COLOR_GREEN if asserted, COLOR_BLUE otherwhise.
      BTN1   => w_btn1,
      LED0_R => LED0_R,
      LED0_G => LED0_G,
      LED0_B => LED0_B );

  -- 100 MHz clock simulation.
  clk <= not clk after T_clk / 2;

  test_led_driver: process
  begin
    wait until rising_edge(clk);
    wait for 1 ns;
    -- 5 ns
    -- Initial state: LED_OFF.
    assert LED0_R = '0' report "t=5ns, LED0_R" severity failure;
    assert LED0_G = '0' report "t=5ns, LED0_G" severity failure;
    assert LED0_B = '0' report "t=5ns, LED0_B" severity failure;

    wait for 40 ns;
    -- LED_ON, COLOR_RED.
    assert LED0_R = '1' report "t=45ns, LED0_R" severity failure;
    assert LED0_G = '0' report "t=45ns, LED0_G" severity failure;
    assert LED0_B = '0' report "t=45ns, LED0_B" severity failure;

    wait for 90 ns;
    -- LED_OFF, COLOR_RED.
    assert w_btn0 = '1' report "t=135ns, BTN0" severity failure;
    assert w_btn1 = '0' report "t=135ns, BTN1" severity failure;   -- COLOR_BLUE
    assert LED0_R = '0' report "t=135ns, LED0_R" severity failure;
    assert LED0_G = '0' report "t=135ns, LED0_G" severity failure;
    assert LED0_B = '0' report "t=135ns, LED0_B" severity failure;

    -- 2 rising edges needed:
    -- * 1st to detect button rising edge
    -- * second to register new color code
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait for 1 ns;
    assert LED0_R = '0' report "t=155ns, LED0_R" severity failure;
    assert LED0_G = '0' report "t=155ns, LED0_G" severity failure;
    assert LED0_B = '1' report "t=155ns, LED0_B" severity failure;

    wait for 20 ns;
    assert w_btn0 = '1' report "t=175ns, BTN0" severity failure;
    assert w_btn1 = '1' report "t=175ns, BTN1" severity failure;   -- COLOR_GREEN
    -- Next LED_ON
    wait for 70 ns;
    assert LED0_R = '0' report "t=245ns, LED0_R" severity failure;
    assert LED0_G = '1' report "t=245ns, LED0_G" severity failure;
    assert LED0_B = '0' report "t=245ns, LED0_B" severity failure;

    wait for 70 ns;
    assert w_btn0 = '1' report "t=315ns, BTN0" severity failure;
    assert w_btn1 = '0' report "t=315ns, BTN1" severity failure;   -- COLOR_BLUE
    -- LED_ON, COLOR_BLUE
    wait for 30 ns;
    assert LED0_R = '0' report "t=345ns, LED0_R" severity failure;
    assert LED0_G = '0' report "t=345ns, LED0_G" severity failure;
    assert LED0_B = '1' report "t=345ns, LED0_B" severity failure;

    wait for 110 ns;
    assert w_btn0 = '1' report "t=455ns, BTN0" severity failure;
    assert w_btn1 = '1' report "t=455ns, BTN1" severity failure;   -- COLOR_GREEN
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait for 1 ns;
    -- LED_ON, still COLOR_BLUE, last color code update ignored.
    assert LED0_R = '0' report "t=465ns, LED0_R" severity failure;
    assert LED0_G = '0' report "t=465ns, LED0_G" severity failure;
    assert LED0_B = '1' report "t=465ns, LED0_B" severity failure;

    wait;
  end process;

 update_color_code: process
 begin
   wait for 135 ns;
   -- t=135, assert update
   w_btn1 <= '0';  -- Blue.
   w_btn0 <= '1';
   wait for 10 ns;
   w_btn0 <= '0';

   wait for 30 ns;
   -- t=175, assert update
   w_btn1 <= '1';  -- Green.
   w_btn0 <= '1';
   wait for 10 ns;
   w_btn0 <= '0';

   wait for 130 ns;
   -- t=315, assert update
   w_btn1 <= '0';  -- Blue.
   w_btn0 <= '1';
   wait for 10 ns;
   w_btn1 <= '0';

   wait for 130 ns;
   -- t=455, assert update
   w_btn1 <= '1';  -- Green, but should be ignored, BTN0 held.
   wait for 10 ns;
   w_btn0 <= '0';
   wait for 10 ns;

   wait;
 end process;

end behavior;
