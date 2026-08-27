-- Package color_codes_pkg.
--
-- The idea is to be able to iterate on indexed colors,
-- while using known binary color codes for I/O data.

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

package color_codes_pkg is

  -- Color code data is 2-bit width.
  -- Color codes are ordred to match the required
  -- LED sequence (red, blue, green).
  subtype color_code_t is std_logic_vector(1 downto 0);
  constant COLOR_NONE  : color_code_t := "00";  -- Reserved/unused.
  constant COLOR_RED   : color_code_t := "01";
  constant COLOR_BLUE  : color_code_t := "10";
  constant COLOR_GREEN : color_code_t := "11";

  -- Color are also somewhat 1-indexed,
  -- so that we can simplty increment the index
  -- to produce the required LED sequence.
  subtype color_index_t is integer range 0 to 3;
  constant COLOR_INDEX_START  : color_index_t := 1;
  constant COLOR_INDEX_LAST   : color_index_t := 3;

end package color_codes_pkg;
