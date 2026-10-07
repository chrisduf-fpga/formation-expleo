-- Module: axis_rgb888_to_rgb8
--
-- RGB88 to RGB8 (grayscale, luminance).

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

-- Interface.
--
entity axis_rgb888_to_rgb8 is
  port (
    -- AXI4-S clock domain (ACLK).
    aclk         : in std_logic;
    -- Resest synchronous to ACLK. Active-Llow.
    aresetn      : in std_logic;

    -- AXI4-S slave interface (RGB888).
    s_axis_tvalid     : in std_logic;
    s_axis_tdata      : in std_logic_vector(23 downto 0);
    s_axis_tuser      : in std_logic;
    s_axis_tlast      : in std_logic;
    s_axis_tready     : out std_logic;

    -- AXI4-S master interface (RGB8).
    m_axis_tready     : in std_logic;
    m_axis_tvalid     : out std_logic;
    m_axis_tdata      : out std_logic_vector(7 downto 0);
    m_axis_tuser      : out std_logic;
    m_axis_tlast      : out std_logic
);
end entity axis_rgb888_to_rgb8;

-- RTL architecture.
--
architecture RTL of axis_rgb888_to_rgb8 is
  attribute X_INTERFACE_INFO      : string;
  attribute X_INTERFACE_PARAMETER : string;

  -- AXI4-S interfaces metadata.

  attribute X_INTERFACE_INFO of aclk : signal is
    "xilinx.com:signal:clock:1.0 aclk CLK";
  attribute X_INTERFACE_PARAMETER of aclk : signal is
    "FREQ_HZ 50000000, ASSOCIATED_BUSIF S_AXIS:M_AXIS, ASSOCIATED_RESET aresetn";

  attribute X_INTERFACE_INFO of aresetn : signal is
    "xilinx.com:signal:reset:1.0 aresetn RST";
  attribute X_INTERFACE_PARAMETER of aresetn : signal is
    "POLARITY ACTIVE_LOW";

  -- AXI4-S slave metadata.
  attribute X_INTERFACE_INFO of s_axis_tdata : signal is
    "xilinx.com:interface:axis:1.0 S_AXIS TDATA";
  attribute X_INTERFACE_INFO of s_axis_tvalid : signal is
    "xilinx.com:interface:axis:1.0 S_AXIS TVALID";
  attribute X_INTERFACE_INFO of s_axis_tlast : signal is
    "xilinx.com:interface:axis:1.0 S_AXIS TLAST";
  attribute X_INTERFACE_INFO of s_axis_tuser : signal is
    "xilinx.com:interface:axis:1.0 S_AXIS TUSER";
  attribute X_INTERFACE_INFO of s_axis_tready : signal is
    "xilinx.com:interface:axis:1.0 S_AXIS TREADY";

  -- AXI4-S master metadata.
  attribute X_INTERFACE_INFO of m_axis_tdata : signal is
    "xilinx.com:interface:axis:1.0 M_AXIS TDATA";
  attribute X_INTERFACE_INFO of m_axis_tvalid : signal is
    "xilinx.com:interface:axis:1.0 M_AXIS TVALID";
  attribute X_INTERFACE_INFO of m_axis_tlast : signal is
    "xilinx.com:interface:axis:1.0 M_AXIS TLAST";
  attribute X_INTERFACE_INFO of m_axis_tuser : signal is
    "xilinx.com:interface:axis:1.0 M_AXIS TUSER";
  attribute X_INTERFACE_INFO of m_axis_tready : signal is
    "xilinx.com:interface:axis:1.0 M_AXIS TREADY";

  signal r_tdata      : std_logic_vector(7 downto 0);
  signal r_tvalid     : std_logic;
  signal r_tuser      : std_logic;
  signal r_tlast      : std_logic;
  signal r_tready     : std_logic;

  signal r_tdata_buf  : std_logic_vector(7 downto 0);
  signal r_tvalid_buf : std_logic;
  signal r_tuser_buf  : std_logic;
  signal r_tlast_buf  : std_logic;

  type state_t is (S_INIT, S_STREAM);
  signal r_state        : state_t;

  signal rgb_sum  : integer range 0 to 765;
  signal rgb8_pxl : std_logic_vector(7 downto 0);
begin

    s_axis_tready <= r_tready;

    m_axis_tdata    <= r_tdata;
    m_axis_tvalid   <= r_tvalid;
    m_axis_tuser    <= r_tuser;
    m_axis_tlast    <= r_tlast;

    rgb_sum <= to_integer(unsigned(s_axis_tdata(23 downto 16))) +
               to_integer(unsigned(s_axis_tdata(15 downto  8))) +
               to_integer(unsigned(s_axis_tdata( 7 downto  0)));
    rgb8_pxl <= std_logic_vector(to_unsigned(rgb_sum / 3, 8));

    rtl: process(aclk)
    begin
      if rising_edge(aclk) then
        if (aresetn = '0') then
          r_tdata    <= (others => '0');
          r_tvalid   <= '0';
          r_tuser    <= '0';
          r_tlast    <= '0';
          r_tready   <= '0';
          r_state    <= S_INIT;
        else
          case r_state is
            when S_INIT =>
                r_tready        <= '1';
                r_tvalid_buf    <= '0';
                r_state         <= S_STREAM;

            when S_STREAM =>
              r_tdata       <= r_tdata_buf;
              r_tuser       <= r_tuser_buf;
              r_tlast       <= r_tlast_buf;
              r_tvalid      <= r_tvalid_buf;

              r_tready  <= '1';

              if (s_axis_tvalid = '1') and (r_tready = '1') then
                r_tdata_buf   <= rgb8_pxl;
                r_tuser_buf   <= s_axis_tuser;
                r_tlast_buf   <= s_axis_tlast;
                r_tvalid_buf  <= '1';

                if (m_axis_tready = '0') then
                  r_tready <= '0';
                end if;

              elsif (m_axis_tready = '1') then
                r_tvalid_buf  <= '0';
              end if;

          end case;
        end if;

      end if;
    end process rtl;

end architecture RTl;
