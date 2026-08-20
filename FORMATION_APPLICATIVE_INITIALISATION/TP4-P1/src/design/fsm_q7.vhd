-- Module fsm_q7
-- 2-state FSM, 2 Mealy output LEDs.
-- Synchronous transitions only: end_counter signal is CE.
-- An Held-down flag limits the green LED to at most one period.

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

-- Interface.
--
entity fsm_q7 is
 generic (
    -- Frequency divider.
    -- * T = D.T_clk, duty cycle 50%
   -- 100 MHz to 1/2 Hz (OFF 1 second, ON one second):
    D : positive := 2E8 );

  port (
    -- Clock signal.
    clk     : in std_logic;
    -- Asynchronous reset, active-low.
    resetn  : in std_logic;

    -- Control button, Mealy variable.
    i_btn0  : in std_logic;

    -- Output LEDs (Mealy logic).
    o_led_r : out std_logic;
    o_led_g : out std_logic );

end entity fsm_q7;

-- RTL architecture.
--
architecture RTL of fsm_q7 is

  -- 2-state FSM.
  type state_t is (LED_OFF, LED_ON);

  -- Register to store current state (1-bit binary encoded,
  -- 2-bit one-hot encoding).
  -- FIXME: initial state should rely on Power-on Reset signal.
  signal r_state    : state_t := LED_OFF;

  -- Combinatorial signal representing the new state
  -- to store in the state register.
  signal next_state : state_t;

  -- Wires end_counter signal from CU as FSM CE (state transitions).
  signal w_fsm_tick : std_logic;

  -- Whether the control button was held down since
  -- the last transition from LED_ON to LED_OFF.
  signal r_held_down  : std_logic := '0';

  -- Provides FSM heartbeat (synchronous transitions) as end_counter output.
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

    elsif (rising_edge(clk)) then
      r_state <= next_state;

      if (r_state = LED_ON) then
        if (next_state = LED_OFF) then
          -- During LED_ON to LED_OFF transition:
          -- * button held down: LED is GREEN, increase held count.
          -- * button is not pressed: reset held count.
          r_held_down <= i_btn0;
        else
          -- If button is released while in ON state, reset held count.
          if (i_btn0 = '0') then
            r_held_down <= '0';
          else
            r_held_down <= r_held_down;
          end if;
        end if;
      else
        -- If button is released while in LED_OFF state, reset held count.
        if (i_btn0 = '0') then
          r_held_down <= '0';
        else
          r_held_down <= r_held_down;
        end if;
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
  mealy_output_logic: process(r_state, i_btn0, r_held_down)
  begin
    case r_state is
      when LED_OFF =>
        o_led_r <= '0';
        o_led_g <= '0';
      when LED_ON =>
        if (i_btn0 = '1' and  r_held_down = '0') then
          o_led_r <= '0';
          o_led_g <= '1';
        else
          o_led_r <= '1';
          o_led_g <= '0';
        end if;
      when others =>
        o_led_r <= '0';
        o_led_g <= '0';
    end case;
  end process mealy_output_logic;

end architecture RTL;
