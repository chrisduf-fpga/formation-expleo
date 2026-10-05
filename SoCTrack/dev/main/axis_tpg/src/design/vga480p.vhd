-- Package: vga480p
--
-- Definitions and helpers for VGA 480p mode.

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

-- Interface.
--
package vga480p is

  -- Horizontal Active window.
  constant VGA_ACTIVE_H     : positive := 640;
  -- Maximum pixel horizontal coordinate value.
  constant VGA_MAX_H        : positive := VGA_ACTIVE_H - 1;
  -- No. bits (width) required to encode VGA_MAX_H.
  constant VGA_WIDTH_H      : positive := 10;

  -- Vertical Active window.
  constant VGA_ACTIVE_V     : positive := 480;
  -- Maximum pixel vertical coordinate value.
  constant VGA_MAX_V        : positive := VGA_ACTIVE_V - 1;
  -- No. bits (width) required to encode VGA_MAX_V.
  constant VGA_WIDTH_V      : positive := 9;

  -- Frame size in pixels.
  -- FIXME: should no be needed, we have vertical coordinate.
  constant VGA_FRAME_SIZE   : positive := VGA_ACTIVE_H * VGA_ACTIVE_V;

  -- 8-bit RGB channels.
  subtype rgb8_chan_t is std_logic_vector(7 downto 0);

  -- 4-bit RGB channels.
  subtype rgb4_chan_t is std_logic_vector(3 downto 0);

  -- AXI4-Stream Video data for RGB8 pixel.
  -- Binary encoding: R[7:0] B[7:0] G[7:0]
  -- Unfortunately, can't be used as I/O port type.
  subtype pxl_data_t is std_logic_vector(23 downto 0);

  -- Pixel horizontal coordinate.
  subtype vga_h_t is natural range 0 to VGA_MAX_H;

  -- Pixel vertical coordinate.
  subtype vga_v_t is natural range 0 to VGA_MAX_V;


  -- Scale x/x_max to 8-bit RGB channel.
  function rgb8_chan_scale(
    x      : natural;
    x_max  : positive
  ) return rgb8_chan_t;

  -- Scale x/x_max to 8-bit color transitions (Red channel).
  function rgb8_rainbow_r(
    x      : natural;
    x_max  : positive
  ) return rgb8_chan_t;
  -- Scale x/x_max to 8-bit color transitions (Blue channel).
  function rgb8_rainbow_b(
    x      : natural;
    x_max  : positive
  ) return rgb8_chan_t;
  -- Scale x/x_max to 8-bit color transitions (Green channel).
  function rgb8_rainbow_g(
    x      : natural;
    x_max  : positive
  ) return rgb8_chan_t;
  -- Scale x/x_max to 8-bit color transitions (RGB8 pixel data).
  function rgb8_rainbow(
    x      : natural;
    x_max  : positive
  ) return pxl_data_t;

  function rgb8_stripes(
    x   : natural;  -- Coordinate.
    d   : positive;  -- Distance between stripes (spacing).
    w   : positive;  -- Stripes width.
    bg  : rgb8_chan_t;  -- Background color.
    fg  : rgb8_chan_t   -- Stipes color.
  ) return rgb8_chan_t;

  -- Extract Red 8-bit channel from 24-bit pixel data.
  function rgb8_channel_r(pxl : pxl_data_t) return rgb8_chan_t;

  -- Extract Blue 8-bit channel from 24-bit pixel data.
  function rgb8_channel_b(pxl : pxl_data_t) return rgb8_chan_t;

  -- Extract Green 8-bit channel from 24-bit pixel data.
  function rgb8_channel_g(pxl : pxl_data_t) return rgb8_chan_t;

end package vga480p;

-- Implementation.
--
package body vga480p is

  function rgb8_chan_scale(
    x      : natural;
    x_max  : positive
  ) return rgb8_chan_t is
  begin
    --
    return std_logic_vector(to_unsigned((x * 255) / x_max, 8));
  end function rgb8_chan_scale;

  function rgb8_rainbow_r(
    x      : natural;
    x_max  : positive
  ) return rgb8_chan_t is
    variable p : integer range 0 to 1535;
  begin
    p := (x * 1535) / x_max;
    if p < 256 then
      -- Red ... yellow
      return x"ff";
    elsif p < 512 then
      -- Yellow ... green
      return std_logic_vector(to_unsigned(511 - p, 8));
    elsif p < 768 then
      -- Green ... cyan
      return x"00";
    elsif p < 1024 then
      -- Cyan ... blue
      return x"00";
    elsif p < 1280 then
      -- Blue ... magenta
      return std_logic_vector(to_unsigned(p - 1024, 8));
    else
      -- Magenta ... red
      return x"ff";
    end if;
  end function rgb8_rainbow_r;

  function rgb8_rainbow_b(
    x      : natural;
    x_max  : positive
  ) return rgb8_chan_t is
    variable p : integer range 0 to 1535;
  begin
    p := (x * 1535) / x_max;
    if p < 256 then
      -- Red ... yellow
      return x"00";
    elsif p < 512 then
      -- Yellow ... green
      return x"00";
    elsif p < 768 then
      -- Green ... cyan
      return std_logic_vector(to_unsigned(p - 512, 8));
    elsif p < 1024 then
      -- Cyan ... blue
      return x"ff";
    elsif p < 1280 then
      -- Blue ... magenta
      return x"ff";
    else
      -- Magenta ... red
      return std_logic_vector(to_unsigned(1535 - p, 8));
    end if;
  end function rgb8_rainbow_b;

  function rgb8_rainbow_g(
    x      : natural;
    x_max  : positive
  ) return rgb8_chan_t is
    variable p : integer range 0 to 1535;
  begin
    p := (x * 1535) / x_max;
    if p < 256 then
      -- Red ... yellow
      return std_logic_vector(to_unsigned(p, 8));
    elsif p < 512 then
      -- Yellow ... green
      return x"ff";
    elsif p < 768 then
      -- Green ... cyan
      return x"ff";
    elsif p < 1024 then
      -- Cyan ... blue
      return std_logic_vector(to_unsigned(1023 - p, 8));
    elsif p < 1280 then
      -- Blue ... magenta
      return x"00";
    else
      -- Magenta ... red
      return x"00";
    end if;
  end function rgb8_rainbow_g;

  function rgb8_rainbow(
    x      : natural;
    x_max  : positive
  ) return pxl_data_t is
    variable p : integer range 0 to 1535;
  begin
    p := (x * 1535) / x_max;
    if p < 256 then
      -- Red ... yellow
      return x"ff" & x"00" & std_logic_vector(to_unsigned(p, 8));
    elsif p < 512 then
      -- Yellow ... green
      return std_logic_vector(to_unsigned(511 - p, 8)) & x"00" & x"ff";
    elsif p < 768 then
      -- Green ... cyan
      return x"00" & std_logic_vector(to_unsigned(p - 512, 8)) & x"ff";
    elsif p < 1024 then
      -- Cyan ... blue
      return x"00" & x"ff" & std_logic_vector(to_unsigned(1023 - p, 8));
    elsif p < 1280 then
      -- Blue ... magenta
      return std_logic_vector(to_unsigned(p - 1024, 8)) & x"ff" & x"00";
    else
      -- Magenta ... red
      return x"ff" & std_logic_vector(to_unsigned(1535 - p, 8)) & x"00";
    end if;
  end function rgb8_rainbow;

  function rgb8_stripes(
    x   : natural;  -- Coordinate.
    d   : positive;  -- Distance between stripes (spacing).
    w   : positive;  -- Stripes width.
    bg  : rgb8_chan_t;  -- Background color.
    fg  : rgb8_chan_t   -- Stipes color.
  ) return rgb8_chan_t is
  begin
    if (x mod d < w) then
      return fg;
    else
      return bg;
    end if;
  end function rgb8_stripes;

  function rgb8_channel_r(pxl : pxl_data_t) return rgb8_chan_t is
  begin
    return pxl(23 downto 16);
  end function rgb8_channel_r;

  function rgb8_channel_b(pxl : pxl_data_t) return rgb8_chan_t is
  begin
    return pxl(15 downto 8);
  end function rgb8_channel_b;

  function rgb8_channel_g(pxl : pxl_data_t) return rgb8_chan_t is
  begin
    return pxl(7 downto 0);
  end function rgb8_channel_g;


end package body vga480p;
