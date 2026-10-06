-- Module: top_soctrack_pl
--

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

-- Interface.
--
entity top_soctrack_pl is
  port (
    DDR_addr          : inout std_logic_vector ( 14 downto 0 );
    DDR_ba            : inout std_logic_vector ( 2 downto 0 );
    DDR_cas_n         : inout std_logic;
    DDR_ck_n          : inout std_logic;
    DDR_ck_p          : inout std_logic;
    DDR_cke           : inout std_logic;
    DDR_cs_n          : inout std_logic;
    DDR_dm            : inout std_logic_vector ( 3 downto 0 );
    DDR_dq            : inout std_logic_vector ( 31 downto 0 );
    DDR_dqs_n         : inout std_logic_vector ( 3 downto 0 );
    DDR_dqs_p         : inout std_logic_vector ( 3 downto 0 );
    DDR_odt           : inout std_logic;
    DDR_ras_n         : inout std_logic;
    DDR_reset_n       : inout std_logic;
    DDR_we_n          : inout std_logic;
    FIXED_IO_ddr_vrn  : inout std_logic;
    FIXED_IO_ddr_vrp  : inout std_logic;
    FIXED_IO_mio      : inout std_logic_vector ( 53 downto 0 );
    FIXED_IO_ps_clk   : inout std_logic;
    FIXED_IO_ps_porb  : inout std_logic;
    FIXED_IO_ps_srstb : inout std_logic;

    -- GPIO
    BTN0        : in std_logic;
    LED0        : out std_logic_vector(2 downto 0);
    -- PL
    LED1        : out std_logic_vector(2 downto 0);
    -- PMOD VGA
    VGA_HSYNC   : out std_logic;
    VGA_VSYNC   : out std_logic;
    VGA_R       : out std_logic_vector (3 downto 0);
    VGA_B       : out std_logic_vector (3 downto 0);
    VGA_G       : out std_logic_vector (3 downto 0)
  );

end entity top_soctrack_pl;

architecture RTL of top_soctrack_pl is
  -- Block design
  component soctrack_pl_bd_wrapper is
  port (
    o_gpio_led : out STD_LOGIC_VECTOR ( 2 downto 0 );
    i_gpio_btn : in STD_LOGIC_VECTOR ( 0 to 0 );
    o_vga_hsync : out STD_LOGIC;
    o_vga_locked : out STD_LOGIC;
    o_vga_rgb4_b : out STD_LOGIC_VECTOR ( 3 downto 0 );
    o_vga_rgb4_g : out STD_LOGIC_VECTOR ( 3 downto 0 );
    o_vga_rgb4_r : out STD_LOGIC_VECTOR ( 3 downto 0 );
    o_vga_vsync : out STD_LOGIC;
    DDR_cas_n : inout STD_LOGIC;
    DDR_cke : inout STD_LOGIC;
    DDR_ck_n : inout STD_LOGIC;
    DDR_ck_p : inout STD_LOGIC;
    DDR_cs_n : inout STD_LOGIC;
    DDR_reset_n : inout STD_LOGIC;
    DDR_odt : inout STD_LOGIC;
    DDR_ras_n : inout STD_LOGIC;
    DDR_we_n : inout STD_LOGIC;
    DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
    DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
    DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ddr_vrn : inout STD_LOGIC;
    FIXED_IO_ddr_vrp : inout STD_LOGIC;
    FIXED_IO_ps_srstb : inout STD_LOGIC;
    FIXED_IO_ps_clk : inout STD_LOGIC;
    FIXED_IO_ps_porb : inout STD_LOGIC
  );
  end component soctrack_pl_bd_wrapper;

  signal w_vga_locked : std_logic;

begin

BD: component soctrack_pl_bd_wrapper
     port map (
      DDR_addr(14 downto 0) => DDR_addr(14 downto 0),
      DDR_ba(2 downto 0) => DDR_ba(2 downto 0),
      DDR_cas_n => DDR_cas_n,
      DDR_ck_n => DDR_ck_n,
      DDR_ck_p => DDR_ck_p,
      DDR_cke => DDR_cke,
      DDR_cs_n => DDR_cs_n,
      DDR_dm(3 downto 0) => DDR_dm(3 downto 0),
      DDR_dq(31 downto 0) => DDR_dq(31 downto 0),
      DDR_dqs_n(3 downto 0) => DDR_dqs_n(3 downto 0),
      DDR_dqs_p(3 downto 0) => DDR_dqs_p(3 downto 0),
      DDR_odt => DDR_odt,
      DDR_ras_n => DDR_ras_n,
      DDR_reset_n => DDR_reset_n,
      DDR_we_n => DDR_we_n,
      FIXED_IO_ddr_vrn => FIXED_IO_ddr_vrn,
      FIXED_IO_ddr_vrp => FIXED_IO_ddr_vrp,
      FIXED_IO_mio(53 downto 0) => FIXED_IO_mio(53 downto 0),
      FIXED_IO_ps_clk => FIXED_IO_ps_clk,
      FIXED_IO_ps_porb => FIXED_IO_ps_porb,
      FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,

      i_gpio_btn(0) => BTN0,
      o_gpio_led(2 downto 0) => LED0(2 downto 0),
      o_vga_rgb4_r(3 downto 0) => VGA_R(3 downto 0),
      o_vga_rgb4_g(3 downto 0) => VGA_G(3 downto 0),
      o_vga_rgb4_b(3 downto 0) => VGA_B(3 downto 0),
      o_vga_hsync => VGA_HSYNC,
      o_vga_vsync => VGA_VSYNC,
      o_vga_locked => w_vga_locked
    );

    LED1 <= b"001" when (w_vga_locked = '1') else b"000";

end architecture RTL;
