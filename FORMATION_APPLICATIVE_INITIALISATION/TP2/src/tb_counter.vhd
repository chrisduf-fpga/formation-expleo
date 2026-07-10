library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- Testbench entity.
entity tb_counter is
end tb_counter;

-- Testbench implementation.
architecture behavioral of tb_counter is

  -- K default value from Question 1:
  -- constant K : positive := 2e8;
  -- Simulation configuration, default to a counter period of 20 us.
  constant K : positive := 2000;
  
  -- Configure LED behavior.
  -- False for Question 8, True starting from Question 9.
  constant cfg_led_flip_flop : boolean := false;
  
  -- Question 9.
  -- To test the restart signal, we typically want to trigger it
  -- a little after the second counter period starts.
  -- For K = 2000, 45 us is fine.
  -- constant t_restart: time := 45 us;
  -- Set to zero to disable restart test.
  constant t_restart : time := 0 ns;
  
  -- Simulated 100 MHz clock.
  constant hp : time := 5 ns;
  constant period : time := 2*hp;

  -- Signals that mirror required counter_unit I/O ports,
  -- with their initial simulation state.
  signal clk      : std_logic := '0';
  signal btn      : std_logic_vector(1 downto 0) := "00";

  -- Instantiate counter under test.
  component counter_unit
  generic (
      K : positive;
      cfg_led_flip_flop : boolean
    );
    port (
      clk     : in std_logic;
      btn     : in std_logic_vector(1 downto 0)
    );
  end component;

begin
  uut: counter_unit
    generic map(
      K => K,
      cfg_led_flip_flop => cfg_led_flip_flop
    )
    -- Map counter_unit I/O ports to tb_counter signals.
    port map (
      clk => clk,
      btn => btn
    );

  -- 100 MHz clock simulation.
  tb_clk: process
  begin
    wait for hp;
    clk <= not clk;
  end process;

  -- This process simulates a button press event
  -- during the third counter period: this should
  -- reset the counter to zero before the next rising edge.
  tb_btn_restart: process
  begin
    if (t_restart > 0 ns) then
      wait for t_restart;
      btn(0) <= '1';
      wait for period;
      btn(0) <= '0';
    end if;

    wait;
  end process;

end behavioral;
