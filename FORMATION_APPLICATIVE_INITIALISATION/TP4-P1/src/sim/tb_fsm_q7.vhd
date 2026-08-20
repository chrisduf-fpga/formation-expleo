-- Testbench.
-- UUT: fsm_q7

library ieee;
use ieee.std_logic_1164.all;

entity tb_fsm_q7 is
end tb_fsm_q7;

architecture behavior of tb_fsm_q7 is

  -- Period of simulated 100 MHz clock.
  constant T_clk  : time := 10 ns;

  -- Entity I/O map.
  signal clk        : std_logic := '0'; -- LOW at t0, 5 ns phase.
  signal resetn     : std_logic := '1'; -- Do not assert nReset at startup.
  signal i_btn0     : std_logic := '0'; -- Switch opened at startup.
  signal o_led_r    : std_logic;
  signal o_led_g    : std_logic;

begin

  uut: entity work.fsm_q7
    generic map (D => 10)
    port map (
      clk => clk,
      resetn => resetn,
      i_btn0 => i_btn0,
      o_led_r => o_led_r,
      o_led_g => o_led_g );

  -- 100 MHz clock simulation.
  clk <= not clk after T_clk / 2;

  test_fsm: process
  begin
    wait until rising_edge(clk);
    wait for 1 ns;
    -- 5 ns
    -- Initial state: LED_OFF.
    assert o_led_r = '0' report "t=5ns, o_led_r" severity failure;
    assert o_led_g = '0' report "t=5ns, o_led_g" severity failure;

    -- Red LED blinks
    --
    wait for 40 ns;
    -- Transition to LED_ON.
    assert o_led_r = '1' report "t=45ns, o_led_r" severity failure;
    assert o_led_g = '0' report "t=45ns, o_led_g" severity failure;
    wait for 50 ns;
    -- Transition to LED_OFF.
    assert o_led_r = '0' report "t=95ns, o_led_r" severity failure;
    assert o_led_g = '0' report "t=95ns, o_led_g" severity failure;
    wait for 50 ns;
    -- Transition to LED_ON.
    assert o_led_r = '1' report "t=145ns, o_led_r" severity failure;
    assert o_led_g = '0' report "t=145ns, o_led_g" severity failure;

    -- 170 ns, button pressed.
    wait until i_btn0 = '1';
    wait until rising_edge(clk);
    wait for 1 ns;

    -- LED_ON state switched to green LED.
    assert o_led_r = '0' report "t=175ns, o_led_r" severity failure;
    assert o_led_g = '1' report "t=175ns, o_led_g" severity failure;
    wait for 20 ns;
    -- Transition to LED_OFF.
    assert o_led_r = '0' report "t=195ns, o_led_r" severity failure;
    assert o_led_g = '0' report "t=195ns, o_led_g" severity failure;
    wait for 50 ns;
    -- Held down, ignore button.
    assert o_led_r = '1' report "t=245ns, o_led_r" severity failure;
    assert o_led_g = '0' report "t=245ns, o_led_g" severity failure;

    -- 300 ns, button released.
    wait until i_btn0 = '0';

    -- 335 ns, button pressed.
    wait until i_btn0 = '1';

    -- Transition to LED_ON with Green LED.
    wait for 40 ns;
    assert o_led_r = '0' report "t=375ns, o_led_r" severity failure;
    assert o_led_g = '1' report "t=375ns, o_led_g" severity failure;

    -- 385 ns, button released.
    wait until i_btn0 = '0';
    wait for 1 ns;
    assert o_led_r = '1' report "t=385ns, o_led_r" severity failure;
    assert o_led_g = '0' report "t=385ns, o_led_g" severity failure;

    wait;
  end process;

  btn0_driver: process
  begin
    -- Hold button 170 -> 300 ns.
    wait for 170 ns;
    i_btn0 <= '1';
    wait for 130 ns;
    i_btn0 <= '0';

    -- Hold button 335 -> 385 ns.
    wait for 35 ns;
    i_btn0 <= '1';
    wait for 50 ns;
    i_btn0 <= '0';

    wait;
  end process;

end behavior;
