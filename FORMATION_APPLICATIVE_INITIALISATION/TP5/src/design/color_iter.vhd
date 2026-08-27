-- Module: color_iter
--
-- Color iterator.


library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
-- Color codes.
use work.color_codes_pkg.all;

-- Interface.
--
entity color_iter is

  port (
    -- Clock signal.
    clk         : in std_logic;
    -- Asynchronous reset, active-low.
    resetn      : in std_logic;

    -- Stimulus for next color code.
    cc_next     : in std_logic;
    -- Next color code ready.
    cc_ready    : out std_logic;
    -- Next color code data.
    cc_data     : out color_code_t );

end entity color_iter;


-- RTL architecture.
--
architecture RTL of color_iter is

  signal r_color_index  : color_index_t := COLOR_INDEX_START;
  signal r_cc_ready     : std_logic := '0';

begin

  -- No glitch: reader will acces this upon cc_ready,
  -- one clock cycle after the color index change.
  cc_data <= std_logic_vector(to_unsigned(r_color_index, 2));
  cc_ready <= r_cc_ready;

  -- Memory.
  rtl: process(clk, resetn)
  begin
    if (resetn = '0') then
      r_color_index <= COLOR_INDEX_START;
      r_cc_ready <= '0';

    elsif (rising_edge(clk)) then
      if (cc_next = '1') then
        r_cc_ready <= '1';

        if (r_color_index = COLOR_INDEX_LAST) then
          r_color_index <= COLOR_INDEX_START;
        else
          r_color_index <= r_color_index + 1;
        end if;

      else
        r_cc_ready <= '0';
      end if;   -- cc_next

    end if;   -- Rising edge.
  end process rtl;

end architecture RTL;
