-- Module: led_jukebox
--

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
-- Color codes.
use work.color_codes_pkg.all;


-- Interface.
--
entity led_jukebox is

  generic (
    -- Frequency divider.
    -- * T = D.T_clk, duty cycle 50%
    -- 100 MHz to 1/2 Hz:
    D               : positive := 2E8;
    -- Asynchronous reset pulse duration in clock cycles.
    -- Advised minimum is max(3, C_SYNCHRONIZER_STAGE).
    RST_SYNC_STAGE  : integer range 0 to 3 := 3);

  port (
    -- Clock signal.
    clk         : in std_logic;
    -- Asynchronous reset, active-low.
    resetn      : in std_logic;

    -- Color update command.
    BTN0    : in std_logic;

    -- Color selection.
    BTN1    : in std_logic;

    -- Output LEDs.
    LED0_R  : out std_logic;
    LED0_G  : out std_logic;
    LED0_B  : out std_logic );

end entity led_jukebox;


-- RTL architecture.
--
architecture RTL of led_jukebox is

  -- Color codes.
  -- BTN0 rising edge detection.
  signal r_btn0 : std_logic;

  -- LED driver update input signal.
  -- Asserted when a color code read from FIFO
  -- is presented at LED driver input.
  signal r_update         : std_logic := '0';

  -- Signal emitted by LED driver on ON/OFF transitions.
  signal w_end_cycle  : std_logic;

  -- Color code from FIFO presented at LED driver input.
  signal w_color_code : color_code_t;

  -- FIFO I/O.
  -- Inputs.
  signal fifo_rst     : std_logic;
  signal fifo_wr_en   : std_logic;
  signal fifo_rd_en   : std_logic;
  -- Outputs.
  signal fifo_din     : color_code_t;
  signal fifo_dout    : color_code_t;
  signal fifo_full    : std_logic;
  signal fifo_empty   : std_logic;

  -- Reset required on startup to initialize FIFO.
  -- Clock cycle descending counter for FIF0 initialization.
  signal r_fifo_sync_stage : integer range 0 to 3 := RST_SYNC_STAGE;

  component led_driver is
    generic(D : positive);
    port(
      clk         : in std_logic;
      resetn      : in std_logic;
      update      : in std_logic;
      color_code  : in color_code_t;
      led_r       : out std_logic;
      led_g       : out std_logic;
      led_b       : out std_logic;
      end_cycle   : out std_logic );
  end component;

  component fifo_gen_shiftreg is
    port(
      clk     : in std_logic;
      rst     : in  std_logic;
      din     : in color_code_t;
      wr_en   : in std_logic;
      rd_en   : in std_logic;
      dout    : out color_code_t;
      full    : out std_logic;
      empty   : out std_logic );
  end component;


begin

  DRV: led_driver generic map (D => D)
    port map(
      clk         => clk,
      resetn      => resetn,
      update      => r_update,
      color_code  => w_color_code,
      led_r       => LED0_R,
      led_g       => LED0_G,
      led_b       => LED0_B,
      end_cycle   => w_end_cycle);

  FIFO: fifo_gen_shiftreg port map(
      clk     => clk,
      rst     => fifo_rst,
      din     => fifo_din,
      wr_en   => fifo_wr_en,
      rd_en   => fifo_rd_en,
      dout    => fifo_dout,
      full    => fifo_full,
      empty   => fifo_empty );

  -- FIFO reset.
  fifo_rst <= '1' when (resetn = '0') or (r_fifo_sync_stage /= 0)
              else '0';

  -- We initiate a read operation on end_cycle signal,
  -- if FIFO not empty.
  fifo_rd_en <= '1' when (w_end_cycle = '1') and (fifo_empty = '0')
                else '0';

  -- We initiate a write operation on rising edges of BTN0,
  -- if FIFO not full.
  fifo_wr_en <= '1' when (BTN0 = '1' and r_btn0 = '0' and fifo_full = '0')
                else '0';

  -- Color code selected through BTN1.
  fifo_din <= COLOR_GREEN when (BTN1 = '1') else COLOR_BLUE;

  -- Color code presented at LED driver is FIFO output.
  w_color_code <= fifo_dout;


  rtl: process(clk, resetn)
  begin
    if (resetn = '0') then
      r_btn0 <= '0';
      r_update <= '0';
      r_fifo_sync_stage <= RST_SYNC_STAGE;

    elsif (rising_edge(clk)) then
      if (r_fifo_sync_stage = 0) then
        -- Detect rising edges of update button.
        r_btn0 <= BTN0;
        -- FIFO read queue.
        r_update <= fifo_rd_en;

      else
        r_fifo_sync_stage <= r_fifo_sync_stage - 1;

        r_btn0 <= '0';
        r_update <= '0';
      end if;

  end if;   -- Rising edge.
end process rtl;

end architecture RTL;
