-- Testbench.
-- UUT: circuit_q4, T_clk_B = T_clk_A

library ieee;
use ieee.std_logic_1164.all;
-- Color codes.
use work.color_codes_pkg.all;

entity tb_circuit_q4 is
end tb_circuit_q4;

architecture behavior of tb_circuit_q4 is

  -- Frequency divider.
  -- T_end_cycle = 10.T_clk
  constant D : positive := 10;

  -- Same simulated clock for both domains (100 MHz).
  constant T_clk   : time := 10 ns;

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
  clk_A <= not clk_A after T_clk / 2;
  clk_B <= not clk_B after T_clk / 2;

end behavior;
