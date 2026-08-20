-- Module: led_driver
--

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

-- Interface.
--
entity led_driver is

 generic (
    -- Frequency divider.
    -- * T = D.T_clk, duty cycle 50%
    -- 100 MHz to 1/2 Hz:
    D : positive := 2E8 );

  port (
    -- Clock signal.
    clk         : in std_logic;
    -- Asynchronous reset, active-low.
    resetn      : in std_logic;

    -- Enable color code update.
    update      : in std_logic;

    -- Requested color code.
    color_code  : in std_logic_vector(1 downto 0);

    -- Output LEDs.
    led_r   : out std_logic;
    led_g   : out std_logic;
    led_b   : out std_logic );
  
end entity led_driver;

-- RTL architecture.
--
architecture RTL of led_driver is

  -- Default color.
  constant COLOR_RED    : std_logic_vector(1 downto 0) := "01";
  -- Color updated.
  constant COLOR_GREEN  : std_logic_vector(1 downto 0) := "10";
  constant COLOR_BLUE   : std_logic_vector(1 downto 0) := "11";
  -- LEDs OFF (unreachable ?).
  constant COLOR_NONE   : std_logic_vector(1 downto 0) := "00";

  -- 2-state FSM.
  type state_t is (LED_OFF, LED_ON);

  -- Register to store current state (1-bit if binary encoded,
  -- 2-bit if one-hot encoding).
  -- FIXME: initial state should rely on Power-on Reset signal.
  signal r_state    : state_t := LED_OFF;
  
  -- Combinatorial signal representing the new state
  -- to store in the state register. 
  signal next_state : state_t;

  -- Wires end_counter signal from CU as FSM CE (state transitions).
  signal w_fsm_tick : std_logic;

  -- Registered color code.
  -- FIXME: initial state should rely on Power-on Reset signal.
  signal r_color    : std_logic_vector(1 downto 0) := COLOR_RED;

  component counter_unit is
    generic(K : positive);
    port(
      clk         : in std_logic;
      resetn      : in std_logic;
      end_counter : out std_logic );
  end component;

begin

  CU: counter_unit generic map (K => D / 2) port map (
    clk => clk,
    resetn => resetn,
    end_counter => w_fsm_tick );
  
  -- Memory.
  rtl: process(clk, resetn)
  begin
    if (resetn = '0') then
      r_state <= LED_OFF;
      r_color <= COLOR_RED;

    elsif (rising_edge(clk)) then
      r_state <= next_state;

      if (update = '1') then
        r_color <= color_code;
      else
        r_color <= r_color;
      end if;

    end if;
  end process rtl;

  -- Next state logic.
  next_state_logic: process(r_state, w_fsm_tick)
  begin
    case r_state is
      when LED_OFF =>
        if (w_fsm_tick = '1') then
          next_state <= LED_ON;
        else
          next_state <= LED_OFF;
        end if;
      when LED_ON =>
        if (w_fsm_tick = '1') then
          next_state <= LED_OFF;
        else
          next_state <= LED_ON;
        end if;
      when others =>
        next_state <= LED_OFF;
    end case;
  end process next_state_logic;

-- Mealy output logic.
  mealy_output_logic: process(r_state, r_color)
  begin
    case r_state is
      when LED_OFF =>
        led_r <= '0';
        led_g <= '0';
        led_b <= '0';
      when LED_ON =>
        if (r_color = COLOR_RED) then
          led_r <= '1';
          led_g <= '0';
          led_b <= '0';
        elsif (r_color = COLOR_GREEN) then
          led_r <= '0';
          led_g <= '1';
          led_b <= '0';
        elsif (r_color = COLOR_BLUE) then
          led_r <= '0';
          led_g <= '0';
          led_b <= '1';
        elsif (r_color = COLOR_NONE) then
          led_r <= '0';
          led_g <= '0';
          led_b <= '0';
        else
          led_r <= '0';
          led_g <= '0';
          led_b <= '0';
        end if;
      when others =>
        led_r <= '0';
        led_g <= '0';
        led_b <= '0';
    end case;
  end process mealy_output_logic;

end architecture RTL;
