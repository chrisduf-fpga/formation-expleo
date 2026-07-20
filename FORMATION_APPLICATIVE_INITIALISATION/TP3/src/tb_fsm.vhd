library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity tb_fsm is
end tb_fsm;

architecture Behavorial of tb_fsm is

  -- Simulated 100 MHz clock.
  constant T  : time := 10 ns;

  -- Counter_unit configuration.
  -- Assuming 100 MHz clock, T counter is 20 us.
  constant K            : positive := 2000;

  -- Map fsm I/O ports.
  signal clk         : std_logic := '0';    -- Clock LOW (falling edge) on startup.
  signal resetn      : std_logic := '0';    -- Assert nReset on startup.
  signal restart     : std_logic := '0';    -- Do not restart on startup.
  signal sig_led_r   : std_logic;
  signal sig_led_b   : std_logic;
  signal sig_led_g   : std_logic;

  component fsm
    generic (K : positive);
    port (
      clk         : in std_logic;   -- Clock signal.
      resetn      : in std_logic;   -- Asynchronous nReset.
      restart     : in std_logic;   -- Restart Fsm_ticks counter.
      LED_R      : out std_logic;  -- S0 or S1
      LED_B      : out std_logic;  -- S0 or S2
      LED_G      : out std_logic   -- S0 or S3
    );
  end component;


begin

  uut: fsm
    generic map (K => K)
    port map (
      clk => clk,
      resetn => resetn,
      restart => restart,
      LED_R => sig_led_r,
      LED_B => sig_led_b,
      LED_G => sig_led_g
    );

  -- 100 MHz clock simulation.
  process
  begin
    wait for T / 2;
    clk <= not clk;
  end process;

  -- De-assert asynchronous nReset.
  process
  begin
    wait for 1 ns;
    resetn <= '1';

    wait;
  end process;

  ut_restart: process
  begin
    -- Allow previous tests to complete before restart,
    -- and the next LED OFF state.
    wait for 2000 us;

    restart <= '1';
    wait for T;
    restart <= '0';

    wait for T;
    assert sig_led_r = '1'
      report "Restart: LED_R" severity failure;
    assert sig_led_b = '1'
      report "Restart: LED_B" severity failure;
    assert sig_led_g = '1'
      report "Restart: LED_G" severity failure;

    wait;
  end process;

end Behavorial;
