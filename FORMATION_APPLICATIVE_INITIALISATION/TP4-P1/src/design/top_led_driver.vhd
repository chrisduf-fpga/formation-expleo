-- Module: top_led_driver
--

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

-- Interface.
--
entity top_led_driver is

 generic (
    -- Frequency divider.
    -- * T = D.T_clk, duty cycle 50%
    -- 100 MHz to 1/2 Hz:
    D : positive := 2E8 );

  port (
    -- Clock signal.
    clk     : in std_logic;
    -- Asynchronous reset, active-low.
    resetn  : in std_logic;

    -- Enable color update.
    BTN0    : in std_logic;

    -- Color selection.
    BTN1    : in std_logic;

    -- Output LEDs.
    LED0_R  : out std_logic;
    LED0_G  : out std_logic;
    LED0_B  : out std_logic );

end top_led_driver;

-- RTL architecture.
--
architecture RTL of top_led_driver is

  -- FIXME: How to avoid copy-paste these.
  constant COLOR_GREEN  : std_logic_vector(1 downto 0) := "10";
  constant COLOR_BLUE   : std_logic_vector(1 downto 0) := "11";

  -- Register to store BTN0 state and detect rising edges.
  signal r_btn0       : std_logic;

  -- Wires LED driver update signal to BTN0 rising edges.
  signal w_update       : std_logic := '0';

  -- Combinatorial logic for color code depending
  -- on BTN1 state.
  signal w_color_code   : std_logic_vector(1 downto 0);

  component led_driver is
    generic(D : positive);
    port(
      clk         : in std_logic;
      resetn      : in std_logic;
      update      : in std_logic;
      color_code  : in std_logic_vector(1 downto 0);
      led_r       : out std_logic;
      led_g       : out std_logic;
      led_b       : out std_logic );
  end component;


begin

  DRV: led_driver generic map (D => D) port map (
    clk => clk,
    resetn => resetn,
    update => w_update,
    color_code => w_color_code,
    led_r => LED0_R,
    led_g => LED0_G,
    led_b => LED0_B
  );

  rtl: process(clk, resetn)
  begin
    if (resetn = '0') then
      r_btn0 <= '0';

    elsif (rising_edge(clk)) then
      r_btn0 <= BTN0;
    end if;
  end process;

  w_update <= '1' when (BTN0 = '1' and r_btn0 = '0')
    else '0';

  w_color_code <= COLOR_GREEN when BTN1 = '1'
                  else COLOR_BLUE;

end architecture RTL;
