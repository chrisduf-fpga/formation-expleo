-- Testbench.
-- UUT: circuit_q4, T_clk_B = 5.T_clk_A

library ieee;
use ieee.std_logic_1164.all;
-- Color codes.
use work.color_codes_pkg.all;

entity tb_circuit_q5 is
end tb_circuit_q5;

architecture behavior of tb_circuit_q5 is

  -- Frequency divider.
  -- T_end_cycle = 10.T_clk
  constant D : positive := 10;

  -- Domain A, clock 250 MHz.
  constant T_clkA   : time := 4 ns;
  -- Domain B, clock 50 MHz.
  constant T_clkB   : time := 20 ns;

  -- UUT Inputs.
  signal clk_A    : std_logic := '1';   -- No phase.
  signal clk_B    : std_logic := '1';   -- No phase.
  signal resetn   : std_logic := '1';

  -- UUT Outputs.
  signal LED0_R :  std_logic;
  signal LED0_G :  std_logic;
  signal LED0_B :  std_logic;
  signal LED1_R :  std_logic;
  signal LED1_G :  std_logic;
  signal LED1_B :  std_logic;

  -- VHDL 2008 only.
  alias cc_iter_cc_next     is <<signal .tb_circuit_q5.uut.CC_ITER.cc_next: std_logic>>;
  alias cc_iter_cc_ready    is <<signal .tb_circuit_q5.uut.CC_ITER.cc_ready: std_logic>>;
  alias cc_iter_cc_data     is <<signal .tb_circuit_q5.uut.CC_ITER.cc_data: color_code_t>>;
  alias drv_led0_end_cycle  is <<signal .tb_circuit_q5.uut.DRV_LED0.end_cycle: std_logic>>;
  alias drv_led0_update     is <<signal .tb_circuit_q5.uut.DRV_LED0.update: std_logic>>;
  alias drv_led1_update     is <<signal .tb_circuit_q5.uut.DRV_LED1.update: std_logic>>;

begin

  uut: entity work.circuit_q4
    generic map (D => D)
    port map (
      clk_A   => clk_A,
      clk_B   => clk_B,
      resetn  => resetn,
      LED0_R  => LED0_R,
      LED0_G  => LED0_G,
      LED0_B  => LED0_B,
      LED1_R  => LED1_R,
      LED1_G  => LED1_G,
      LED1_B  => LED1_B );

  -- Simulated clock.
  clk_A <= not clk_A after T_clkA / 2;
  clk_B <= not clk_B after T_clkB / 2;

  process
  begin
    -- At the tenth end_cycle.
    wait for 396 ns;

    -- Input state.
    assert cc_iter_cc_next = '0' severity failure;
    assert cc_iter_cc_data = COLOR_RED severity failure;
    assert drv_led0_end_cycle = '0' severity failure;
    assert drv_led0_update = '0' severity failure;
    assert drv_led1_update = '0' severity failure;

    wait for 1 ns;  -- Setup/Hold
    -- end_cycle registrered, cc_next emitted
    assert cc_iter_cc_next = '1' severity failure;
    assert cc_iter_cc_data = COLOR_RED severity failure;
    assert drv_led0_end_cycle = '1' severity failure;
    assert drv_led0_update = '0' severity failure;
    assert drv_led1_update = '0' severity failure;

    wait until rising_edge(clk_A);
    assert cc_iter_cc_next = '1' severity failure;
    assert drv_led0_end_cycle = '1' severity failure;
    assert drv_led0_update = '0' severity failure;
    assert drv_led1_update = '0' severity failure;

    wait for 1 ns;  -- Setup/Hold
    -- end_cycle, cc_next de-asserted
    -- cc_data registrered
    -- cc_ready, cc_update(s) emitted
    assert cc_iter_cc_next = '0' severity failure;
    assert cc_iter_cc_data = COLOR_BLUE severity failure;
    assert drv_led0_end_cycle = '0' severity failure;
    assert drv_led0_update = '1' severity failure;
    assert drv_led1_update = '1' severity failure;

    -- Wait until fastest clock rising edge.
    wait until rising_edge(clk_A);
    assert cc_iter_cc_data = COLOR_BLUE severity failure;
    assert drv_led0_update = '1' severity failure;

    -- Wait until slowest clock rising edge.
    wait until rising_edge(clk_A);
    assert cc_iter_cc_data = COLOR_BLUE severity failure;
    -- The input update signal has been de-asserted in the fastest
    -- clock domain, missed pulse.
    assert drv_led0_update = '0' severity failure;

    wait;
  end process;

end behavior;
