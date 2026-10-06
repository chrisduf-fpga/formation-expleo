-- Module: axis_mux
--
-- Select AXI4-Stream source.

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

-- Interface.
--
entity axis_mux is
  port (
    -- AXI4-Stream clock domain.
    aclk          : in std_logic;

    -- AXI4-Stream selection:
    -- 0: default
    -- 1: alternate (DMA frame buffer)
    i_axis_sel    : in std_logic;

    -- Interface S0_AXIS.
    s0_axis_tready     : out std_logic;
    s0_axis_tvalid     : in std_logic;
    s0_axis_tdata      : in std_logic_vector(23 downto 0);
    s0_axis_tuser      : in std_logic;
    s0_axis_tlast      : in std_logic;

    -- Interface S1_AXIS.
    s1_axis_tready     : out std_logic;
    s1_axis_tvalid     : in std_logic;
    s1_axis_tdata      : in std_logic_vector(23 downto 0);
    s1_axis_tuser      : in std_logic;
    s1_axis_tlast      : in std_logic;

    -- Selected AXI4-S interface.
    m_axis_tready     : in std_logic;
    m_axis_tvalid     : out std_logic;
    m_axis_tdata      : out std_logic_vector(23 downto 0);
    m_axis_tuser      : out std_logic;
    m_axis_tlast      : out std_logic
    );
end entity axis_mux;

-- RTL architecture.
--
architecture RTL of axis_mux is

  -- AXIS interfaces metadata.

  attribute X_INTERFACE_INFO      : string;
  attribute X_INTERFACE_PARAMETER : string;

  attribute X_INTERFACE_INFO of aclk : signal is
    "xilinx.com:signal:clock:1.0 aclk CLK";
  attribute X_INTERFACE_PARAMETER of aclk : signal is
    "FREQ_HZ 50000000, ASSOCIATED_BUSIF S0_AXIS:S1_AXIS:M_AXIS";

  attribute X_INTERFACE_INFO of s0_axis_tdata : signal is
    "xilinx.com:interface:axis:1.0 S0_AXIS TDATA";
  attribute X_INTERFACE_INFO of s0_axis_tvalid : signal is
    "xilinx.com:interface:axis:1.0 S0_AXIS TVALID";
  attribute X_INTERFACE_INFO of s0_axis_tready : signal is
    "xilinx.com:interface:axis:1.0 S0_AXIS TREADY";
  attribute X_INTERFACE_INFO of s0_axis_tlast : signal is
    "xilinx.com:interface:axis:1.0 S0_AXIS TLAST";
  attribute X_INTERFACE_INFO of s0_axis_tuser : signal is
    "xilinx.com:interface:axis:1.0 S0_AXIS TUSER";

  attribute X_INTERFACE_INFO of s1_axis_tdata : signal is
    "xilinx.com:interface:axis:1.0 S1_AXIS TDATA";
  attribute X_INTERFACE_INFO of s1_axis_tvalid : signal is
    "xilinx.com:interface:axis:1.0 S1_AXIS TVALID";
  attribute X_INTERFACE_INFO of s1_axis_tready : signal is
    "xilinx.com:interface:axis:1.0 S1_AXIS TREADY";
  attribute X_INTERFACE_INFO of s1_axis_tlast : signal is
    "xilinx.com:interface:axis:1.0 S1_AXIS TLAST";
  attribute X_INTERFACE_INFO of s1_axis_tuser : signal is
    "xilinx.com:interface:axis:1.0 S1_AXIS TUSER";

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

begin

  s0_axis_tready   <= m_axis_tready when (i_axis_sel = '0') else '0';
  s1_axis_tready   <= m_axis_tready when (i_axis_sel = '1') else '0';

  m_axis_tvalid    <= s0_axis_tvalid when (i_axis_sel = '0') else s1_axis_tvalid;
  m_axis_tuser     <= s0_axis_tuser when (i_axis_sel = '0') else s1_axis_tuser;
  m_axis_tlast     <= s0_axis_tlast when (i_axis_sel = '0') else s1_axis_tlast;
  m_axis_tdata     <= s0_axis_tdata when (i_axis_sel = '0') else s1_axis_tdata;

end architecture RTL;
