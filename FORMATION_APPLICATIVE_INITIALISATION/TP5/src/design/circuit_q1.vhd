-- Module: circuit_q1
--

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
-- Color codes.
use work.color_codes_pkg.all;

-- Interface.
--
entity circuit_q1 is
 generic (
    -- Frequency divider.
    -- 100 MHz to 1/2 Hz (1 second ON, 1 second OFF):
    D : positive := 2E8 );

  port (
    -- Clock signal.
    clk         : in std_logic;
    -- Asynchronous reset, active-low.
    resetn      : in std_logic;

    -- Output LEDs.
    LED0_R      : out std_logic;
    LED0_G      : out std_logic;
    LED0_B      : out std_logic;
    LED1_R      : out std_logic;
    LED1_G      : out std_logic;
    LED1_B      : out std_logic );

end entity circuit_q1;


-- RTL architecture.
--
architecture RTL of circuit_q1 is

  component led_driver is
    generic(D : positive);
    port(
      clk         : in std_logic;
      resetn      : in std_logic;
      update      : in std_logic;
      color_code  : in color_code_t;
      led_r       : out std_logic;
      led_g       : out std_logic;
      led_b       : out std_logic;
      end_cycle   : out std_logic );
  end component;

  component color_iter is
    port(
      clk         : in std_logic;
      resetn      : in std_logic;
      cc_next     : in std_logic;
      cc_ready    : out std_logic;
      cc_data     : out color_code_t );
  end component;

  -- Distributes color iterator outputs to both LED drivers.
  signal w_cc_ready    : std_logic;
  signal w_cc_next     : std_logic;
  signal w_color_code  : color_code_t;

  -- Changes are driven by a single end_cycle signal.
  signal w_end_cycle_led0 : std_logic;
  -- Counter modulo 10 for end_cycle pulses.
  signal r_cycle_cnt   : integer range 0 to 9 := 0;
  -- Intermediate signal, avoid duplicating comparison logic.
  signal w_cc_cycle    : std_logic;

begin

  DRV_LED0: led_driver generic map (D => D)
    port map(
      clk         => clk,
      resetn      => resetn,
      update      => w_cc_ready,
      color_code  => w_color_code,
      led_r       => LED0_R,
      led_g       => LED0_G,
      led_b       => LED0_B,
      end_cycle   => w_end_cycle_led0);

  DRV_LED1: led_driver generic map (D => D)
    port map(
      clk         => clk,
      resetn      => resetn,
      update      => w_cc_ready,
      color_code  => w_color_code,
      led_r       => LED1_R,
      led_g       => LED1_G,
      led_b       => LED1_B,
      end_cycle   => open );

  CC_ITER: color_iter
    port map(
      clk         => clk,
      resetn      => resetn,
      cc_next     => w_cc_next,
      cc_ready    => w_cc_ready,
      cc_data     => w_color_code );

  w_cc_cycle <= '1' when (r_cycle_cnt = 9) else '0';

  w_cc_next <= '1' when (w_end_cycle_led0 = '1') and (w_cc_cycle = '1') else '0';

  rtl: process(clk, resetn)
  begin
  if (resetn = '0') then
    r_cycle_cnt <= 0;

  elsif rising_edge(clk) then
    if (w_end_cycle_led0 = '1') then
      if (w_cc_cycle = '1') then
        r_cycle_cnt <= 0;
      else
        r_cycle_cnt <= r_cycle_cnt + 1;
      end if;
    end if;
    
  end if;  -- Rising edge.
end process rtl;

end architecture RTL;
