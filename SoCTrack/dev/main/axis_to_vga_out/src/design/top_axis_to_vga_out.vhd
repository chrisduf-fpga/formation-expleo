-- Module: top_axis_to_vga_out
--

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

-- Interface.
--
entity top_axis_to_vga_out is
  port (
    -- ACLK (AXI4-Stream master clock).
    aclk : in std_logic;
    -- Reset synchronous to ACLK.
    aresetn : in std_logic

    s_axi4s_vid_tdata : in std_logic_vector ( 23 downto 0 );
    s_axi4s_vid_tlast : in std_logic;
    s_axi4s_vid_tready : out std_logic;
    s_axi4s_vid_tuser : in std_logic;
    s_axi4s_vid_tvalid : in std_logic;
    o_vga_locked : out std_logic;

    o_vga_rgb4_r : out std_logic_vector ( 3 downto 0 );
    o_vga_rgb4_b : out std_logic_vector ( 3 downto 0 );
    o_vga_rgb4_g : out std_logic_vector ( 3 downto 0 );
    o_vga_hsync : out std_logic;
    o_vga_vsync : out std_logic;

    -- VGA 25 MHz clock
    clk         : in std_logic;
    -- Reset synchronous to VGA clock.
    resetn      : in std_logic;

    -- AXI4-S compatible interface.
    i_tready    : in std_logic;
    o_tvalid    : out std_logic;
    o_tdata     : out std_logic_vector(23 downto 0);
    o_tuser     : out std_logic;  -- SOF
    o_tlast     : out std_logic   -- EOL
  );
end entity top_axis_to_vga_out;

architecture structure of top_axis_to_vga_out is

 attribute X_INTERFACE_INFO       : string;
 attribute X_INTERFACE_PARAMETER  : string;

 attribute X_INTERFACE_INFO of aclk : signal is
   "xilinx.com:signal:clock:1.0 aclk CLK";
 attribute X_INTERFACE_PARAMETER of aclk : signal is
   "FREQ_HZ 50000000, ASSOCIATED_BUSIF S_AXIS, ASSOCIATED_RESET aresetn";

 attribute X_INTERFACE_INFO of aresetn : signal is
   "xilinx.com:signal:reset:1.0 aresetn RST";


begin

end architecture structure;
