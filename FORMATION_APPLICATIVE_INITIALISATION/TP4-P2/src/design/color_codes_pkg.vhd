-- Package color_codes.
--
-- Avoir copy-paste them.

library ieee;
use ieee.std_logic_1164.all;

package color_codes_pkg is

  -- Note: Color codes could be defined as an enum,
  -- but known fixed values may help debug/trace.
  subtype color_code_t is std_logic_vector(1 downto 0);

  constant COLOR_NONE  : color_code_t := "00";
  constant COLOR_RED   : color_code_t := "01";
  constant COLOR_GREEN : color_code_t := "10";
  constant COLOR_BLUE  : color_code_t := "11";

end package color_codes_pkg;
