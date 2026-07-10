library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


-- Counter interface.
entity counter_unit is

  -- Counter unit configuration.
  generic (
    -- Expected maximum counter value (in number of clock rising edges).
    -- Default value corresponds to a counter period of 2 seconds (Question 1).
    -- Most simulations examples set it to 2000, for a counter period of 20 us.
    K : positive := 200000000;
    
    -- Configure the status LED behavior.
    -- Question 8 (false): Lhe LED is directly driven by the end_counter signal
    --   and will turn ON once until the next clock rising edge.
    -- Question 9 (true): end_counter events will toggle the LED.
    cfg_led_flip_flop : boolean := true
  );
  port (

    -- Period 10 ns, waveform {0 5}
    clk     : in std_logic;

    -- Restart button.
    -- btn[0] PACKAGE_PIN D20 IOSTANDARD LVCMOS33: restart
    btn     : in std_logic_vector(1 downto 0);

    -- Status LED (semantics depends on simulation).
    led0_b  : out std_logic
    
  );
end counter_unit;


-- Counter implementation.
architecture behavioral of counter_unit is

  -- 28-bit counter (unsigned), zero-initialized.
  signal sig_count     : unsigned(27 downto 0) := (others => '0');

  -- Set when and only when the counter equals to its maximum value.
  signal end_counter : std_logic;

  -- Provides a signal which when asserted will reset the counter to zero.
  signal restart     : std_logic;

  -- CLR input signal.
  signal resetn      : std_logic := '1';

  -- Drive LED output port starting from Question 9.
  signal sig_led     : std_logic := '0';


begin

  -- Handler process for clock events.
  clk_handler: process(clk, resetn)
  begin
    
    -- Handle RST signal on all clock events (rising and falling edges).
    if (resetn = '0') then
      -- Forced reset.
      sig_count <= (others => '0');
      
    -- Synchronize counter management on rising edges:
    -- either increment count or reset it back to zero.
    elsif rising_edge(clk) then
     if (end_counter = '1') or (restart = '1') then
        sig_count <= (others => '0');
        -- Question 9: Toggle the LED on end_counter events:
        -- LED blinks with a period of twice the counter period,
        -- and a duty-cycle of 1/2.
        if (cfg_led_flip_flop) then
          sig_led <= not sig_led;
        end if;
     else
       sig_count <= sig_count + 1;
     end if;
    end if;
     
  end process;

  -- Whether we reached the configured maximum value K.
  end_counter <= '1' when (sig_count = K)
                 else '0';

  -- Status LED behavior depends on configuration.
  led0_b <= sig_led when cfg_led_flip_flop else end_counter;

  -- Question 11: Connect restart signal to button.,
  -- Restart counter on button1 press event.
  restart <= btn(0);

  -- Quesion 17: connect resetn input port to button2
  -- before generating the bitstream.
  resetn <= btn(1);


end behavioral;
