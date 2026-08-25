-- Testbench.
-- UUT: led_jukebox

library ieee;
use ieee.std_logic_1164.all;

entity tb_led_jukebox_full is
end tb_led_jukebox_full;

architecture behavior of tb_led_jukebox_full is

  -- Period of simulated clock (100 MHz).
  constant T_clk  : time := 10 ns;

  -- Inputs.
  signal clk      : std_logic := '1';
  signal resetn   : std_logic := '1';
  signal BTN0     : std_logic := '0';
  signal BTN1     : std_logic := '0';

  -- Outputs.
  signal LED0_R   : std_logic;
  signal LED0_G   : std_logic;
  signal LED0_B   : std_logic;

begin

  uut: entity work.led_jukebox
    generic map (D => 10, RST_SYNC_STAGE => 1)
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

  fifo_wr_loop: process
  begin
    
    wait until rising_edge(clk); -- 25 ns
    BTN0 <= '1';
    BTN1 <= not BTN1;
    
    wait until rising_edge(clk);
    BTN0 <= '0';
  
  end process fifo_wr_loop;

end behavior;
