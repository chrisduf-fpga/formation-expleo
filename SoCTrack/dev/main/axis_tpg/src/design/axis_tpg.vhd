-- Module: axis_tpg
--
-- Test Pattern Generator with AXI4-Stream master interface.
-- VGA 640x480; RGB888

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

use work.vga480p.all;


-- Interface.
--
entity axis_tpg is
  port (
    -- AXI4-S clock domain (ACLK).
    aclk         : in std_logic;
    -- Resest synchronous to ACLK. Active-Llow.
    aresetn      : in std_logic;

    -- AXI4-S interface.
    m_axis_tready   : in std_logic;
    m_axis_tvalid   : out std_logic;
    -- Pixel data.
    m_axis_tdata     : out std_logic_vector(23 downto 0);
    -- SOF
    m_axis_tuser     : out std_logic;
    -- EOL
    m_axis_tlast     : out std_logic
  );
end entity axis_tpg;

-- RTL architecture.
--
architecture RTL of axis_tpg is

    -- AXI4-S interface metadata.
    attribute X_INTERFACE_INFO      : string;
    attribute X_INTERFACE_PARAMETER : string;
    attribute X_INTERFACE_INFO of aclk : signal is
        "xilinx.com:signal:clock:1.0 aclk CLK";
    attribute X_INTERFACE_PARAMETER of aclk : signal is
        "FREQ_HZ 50000000, ASSOCIATED_BUSIF M_AXIS, ASSOCIATED_RESET aresetn";
    attribute X_INTERFACE_INFO of aresetn : signal is
        "xilinx.com:signal:reset:1.0 aresetn RST";
    attribute X_INTERFACE_PARAMETER of aresetn : signal is
        "POLARITY ACTIVE_LOW";
    attribute X_INTERFACE_INFO of m_axis_tdata : signal is
        "xilinx.com:interface:axis:1.0 M_AXIS TDATA";
    attribute X_INTERFACE_INFO of m_axis_tvalid : signal is
        "xilinx.com:interface:axis:1.0 M_AXIS TVALID";
    attribute X_INTERFACE_INFO of m_axis_tready : signal is
        "xilinx.com:interface:axis:1.0 M_AXIS TREADY";
    attribute X_INTERFACE_INFO of m_axis_tlast : signal is
        "xilinx.com:interface:axis:1.0 M_AXIS TLAST";
    attribute X_INTERFACE_INFO of m_axis_tuser : signal is
        "xilinx.com:interface:axis:1.0 M_AXIS TUSER";


  type state_t is (S_INIT, S_STREAM);
  signal r_state        : state_t;

  signal r_tvalid   : std_logic;
  signal r_tuser    : std_logic;
  signal r_tlast    : std_logic;
  signal r_tdata    : std_logic_vector(23 downto 0);

  -- Coordinates of the current pixel,
  -- that is the current prepared for the next edge.
  signal r_pxl_h    : vga_h_t;
  signal r_pxl_v    : vga_v_t;

  signal rgb8_chan_r : rgb8_chan_t;
  signal rgb8_chan_b : rgb8_chan_t;
  signal rgb8_chan_g : rgb8_chan_t;


  signal r_pong_h    : vga_h_t;
  signal r_pong_v    : vga_v_t;

  signal r_pong_hdir        : std_logic;
  signal r_pong_vdir        : std_logic;
  signal w_pong_ovr_pxl     : std_logic;

  constant MARK_V   : positive := 240;
  constant MARK_H1  : positive := 200;
  constant MARK_H2  : positive := 420;

  constant PONG_WIDTH   : natural := 8;
  constant PONG_MAX_H   : natural := (VGA_MAX_H - PONG_WIDTH);
  constant PONG_MAX_V   : natural := (VGA_MAX_V - PONG_WIDTH);
  constant PONG_MIN_H   : natural := 0;
  constant PONG_MIN_V   : natural := 0;

  begin

  m_axis_tdata    <= r_tdata;
  m_axis_tvalid   <= r_tvalid;
  m_axis_tuser    <= r_tuser;
  m_axis_tlast    <= r_tlast;

  w_pong_ovr_pxl <= '1' when (r_pxl_h >= r_pong_h) and (r_pxl_h < (r_pong_h + PONG_WIDTH)) and
                            (r_pxl_v >= r_pong_v) and (r_pxl_v < (r_pong_v + PONG_WIDTH)) else
                    '0';

  rtl: process(aclk)
  begin
    if rising_edge(aclk) then
      if (aresetn = '0') then
        r_tvalid  <= '0';
        r_tuser   <= '0';
        r_tlast   <= '0';
        r_tdata   <= (others => '0');

        r_pxl_h       <= 0;
        r_pxl_v       <= 0;
        r_pong_h      <= 0;
        r_pong_v      <= 0;
        r_pong_hdir   <= '0';
        r_pong_vdir   <= '0';
        r_state       <= S_INIT;
      else
        case r_state is
          when S_INIT =>
            -- First pixel of first frame.
            r_tdata   <= rgb8_chan_r & rgb8_chan_b & rgb8_chan_g;
            r_tuser   <= '1';
            r_tvalid  <= '1';
            -- Advance to next pixel.
            r_pxl_h   <= 1;
            -- initial pong impulsion.
            r_pong_hdir <= '1';
            r_pong_vdir <= '1';
            r_state   <= S_STREAM;

          when S_STREAM =>
            if (r_tvalid = '1') and (m_axis_tready = '1') then

              r_tdata <= rgb8_chan_r & rgb8_chan_b & rgb8_chan_g;

              if (r_pxl_h = VGA_MAX_H) then
                r_tuser <= '0';
                r_tlast <= '1';
              elsif (r_pxl_h = 0) and (r_pxl_v = 0) then
                r_tuser <= '1';
                r_tlast <= '0';
              else
                r_tuser <= '0';
                r_tlast <= '0';
              end if;

              if (r_pxl_h = VGA_MAX_H) then
                r_pxl_h <= 0;
                if (r_pxl_v = VGA_MAX_V) then
                  r_pxl_v <= 0;
                else
                  r_pxl_v <= r_pxl_v + 1;
                end if;
              else
                r_pxl_h <= r_pxl_h + 1;
                r_pxl_v <= r_pxl_v;
              end if;

              -- Update pong, once per frame.
              if (r_pxl_h = 0) and (r_pxl_v = 0) then
                -- Update pong coordinates.
                if (r_pong_hdir = '1') then
                  r_pong_h <= r_pong_h + 1;
                else
                  r_pong_h <= r_pong_h - 1;
                end if;
                if (r_pong_vdir = '1') then
                  r_pong_v <= r_pong_v + 1;
                else
                  r_pong_v <= r_pong_v - 1;
                end if;

                -- Update direction.
                if (r_pong_hdir = '1' and (r_pong_h = PONG_MAX_H - 1)) or (r_pong_hdir = '0' and (r_pong_h = PONG_MIN_H + 1)) then
                  r_pong_hdir <= not r_pong_hdir;
                end if;
                if (r_pong_vdir = '1' and (r_pong_v = PONG_MAX_V - 1)) or (r_pong_vdir = '0' and (r_pong_v = PONG_MIN_V + 1)) then
                  r_pong_vdir <= not r_pong_vdir;
                end if;
              end if;

            end if;   -- TVALID & TDATA

        end case;
      end if;   -- resetn
    end if;   -- rising_edge
  end process rtl;


  rgb8: process(r_pxl_h, r_pxl_v, w_pong_ovr_pxl)
  begin
    if (w_pong_ovr_pxl = '1') then
        rgb8_chan_r <= x"00";
        rgb8_chan_b <= x"00";
        rgb8_chan_g <= x"00";
    else
      if (r_pxl_v < MARK_V) then
        -- Top half-screen.
        if (r_pxl_h < MARK_H1) then
          -- Region A: Color palette mosaic.
          rgb8_chan_r <= rgb8_chan_scale(r_pxl_h, MARK_H1 - 1);
          rgb8_chan_b <= x"80";
          rgb8_chan_g <= rgb8_chan_scale(r_pxl_v, MARK_V - 1);
        elsif (r_pxl_h < MARK_H2) then
          -- Region B. Vertical stripes.
          rgb8_chan_r <= rgb8_stripes(r_pxl_h, 8, 2, x"ff", x"00");
          rgb8_chan_b <= rgb8_stripes(r_pxl_h, 8, 2, x"ff", x"00");
          rgb8_chan_g <= rgb8_stripes(r_pxl_h, 8, 2, x"ff", x"00");
        else
          -- Region C. Horizontal stripes.
          rgb8_chan_r <= rgb8_stripes(r_pxl_v, 4, 2, x"ff", x"00");
          rgb8_chan_b <= rgb8_stripes(r_pxl_v, 4, 2, x"ff", x"00");
          rgb8_chan_g <= rgb8_stripes(r_pxl_v, 4, 2, x"ff", x"00");
        end if;
      elsif (r_pxl_h < MARK_H1) then
        -- Bottom half-screen.
        -- Region D. Empty.
        rgb8_chan_r <= x"ff";
        rgb8_chan_b <= x"ff";
        rgb8_chan_g <= x"ff";
      else
        -- Region E. Vertical grayscale.
        rgb8_chan_r <= rgb8_chan_scale(r_pxl_v, VGA_MAX_V);
        rgb8_chan_b <= rgb8_chan_scale(r_pxl_v, VGA_MAX_V);
        rgb8_chan_g <= rgb8_chan_scale(r_pxl_v, VGA_MAX_V);
      end if;
    end if;
  end process rgb8;

end architecture RTL;
