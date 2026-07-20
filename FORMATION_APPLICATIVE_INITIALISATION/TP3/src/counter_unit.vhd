-- Counter_unit.
--
-- Generic constants:
-- - K:       Number of clock periods in one counter period.
--            Counter values are in the range [0, K - 1].
-- Inputs:
-- - clk:     Clock signal.
-- - resetn:  nReset signal, clear counter register.
--
-- Outputs:
-- - end_counter: Signals counter periods.
--                True iff the current counter value equals to its maximum.
--                Updated on rising edges.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


-- Entity interface.
entity Counter_unit is
  -- Counter unit configuration.
  generic (
    -- Expected maximum counter value (in number of clock rising edges).
    -- Simulations use a 100 MHz clock:
    -- - default value corresponds to a counter period of 2 seconds
    -- - a value of 2000 corresponds to a counter period of 20 us.
    K : positive := 200000000
  );
  port ( 
    clk         : in std_logic; 
    resetn      : in std_logic;
    end_counter : out std_logic
  );
end Counter_unit;

-- Entity implementation view (Behavioral).
architecture Behavioral of Counter_unit is

  -- Maximum counter value in number of clock rising edges.
  -- Once the signal is synchronized with clock rising edges
  -- at some t0, the number of periods between t0 and KT is K - 1.
  constant MAX_COUNT      : positive := K - 1;

  -- Counter value, 28-bit register (count_reg).
  signal count            : unsigned(27 downto 0) := (others => '0');

  -- Set when the counter value equals to its maximum.
  -- Wired to output port end_counter.
  signal sig_end_counter  : std_logic;

  begin

    -- Sequential process:
    -- - clear counter value of nReset
    -- - on clock rising edges, increment counter value
    --   or reset it back to zero depending on sig_end_counter.
    process(clk, resetn)
    begin
      if(resetn = '0') then
        count <= (others => '0');
      elsif rising_edge(clk) then
        if (sig_end_counter = '1') then
          count <= (others => '0');
        else
          count <= count + 1;
        end if;
      end if;
    end process;

    -- Wired to condition (combinatorial design).
    sig_end_counter <= '1' when (count = MAX_COUNT)
      else '0';
    -- Set counter output port.
    end_counter <= sig_end_counter;

end Behavioral;
