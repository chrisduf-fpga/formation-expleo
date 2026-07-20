-- Convert Counter_unit events period to FSM events period.
--
-- Generic constants:
-- - K:       Number of clock periods in one counter period.
--            Counter values are in the range [0, K - 1].
-- Inputs:
-- - clk:     Clock signal.
-- - resetn:  Asynchronous nReset.
-- - restart: Restart Fsm_ticks counter.
--
-- Outputs:
-- - ticks: Number of
--                True iff the current counter value equals to its maximum.
--                Updated on rising edges.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity Fsm_ticks is
  -- Counter unit configuration.
  -- T clock perdiod (e.g. 10 ns at 100 MHz)
  -- Counter perdiod Tk = KT, K=Tk/T
  -- E.g. with a 100 MHz clock:
  -- - K = 2000, Tk = 20 us
  -- - K = 200000000, Tk = 2s
  generic (K : positive := 200000000);
  port (
    clk         : in std_logic;   -- Clock signal.
    resetn      : in std_logic;   -- Asynchronous nReset.
    restart     : in std_logic;   -- Restart Fsm_ticks counter.
    tick        : in std_logic;   -- Events source, wired to Counter_unit output.
    -- Number of Fsm_ticks counter periods,
    -- once synchronize, equals to half the number
    -- of Counter_unit events.
    -- See also count internal signal.
    ticks       : out std_logic_vector(3 downto 0)
  );
end Fsm_ticks;

architecture Behavioral of Fsm_ticks is

  -- Assuming we toggle a LED on end_counter events,
  -- counting for the number of LED ON/OFF periods.
  -- Counter value, 4-bit register.
  signal count  : unsigned(3 downto 0) := (others => '0');

  -- We'll enable increment only on "LED OFF" events.
  signal ticks_ce : std_logic := '0';

begin

  ticks <= std_logic_vector(count);

  process(clk, resetn)
  begin
    if(resetn = '0') then
      count <= (others => '0');
      ticks_ce <= '0';
      
    elsif rising_edge(clk) then
      
      if (restart = '1') then
        count <= (others => '0');
        ticks_ce <= '0';
      
      elsif (tick = '1') then
        if (ticks_ce = '1') then
          count <= count + 1;
        end if;
        ticks_ce <= not ticks_ce;
      end if;
      
    end if;

  end process;

end Behavioral;
