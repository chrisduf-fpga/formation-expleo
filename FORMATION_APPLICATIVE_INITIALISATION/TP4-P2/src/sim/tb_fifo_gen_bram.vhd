-- Testbench.
-- UUT: fifo_gen_bram

library ieee;
use ieee.std_logic_1164.all;

entity tb_fifo_gen_bram is
end entity tb_fifo_gen_bram;

architecture behavior of tb_fifo_gen_bram is

  -- Simulated clock period (100 MHz).
  constant T_clk  : time := 10 ns;

  -- 2-bit witdh FIFO.
  constant WIDTH      : positive := 2;

  -- First Word (1st write operation, standard mode).
  constant FIRST_WORD : std_logic_vector(WIDTH - 1 downto 0) := "11";

  component fifo_gen_bram is
    port(
      clk       : in std_logic;
      srst      : in std_logic;
      din       : in std_logic_vector(WIDTH - 1 downto 0);
      wr_en     : in std_logic;
      rd_en     : in std_logic;
      dout      : out std_logic_vector(WIDTH - 1 downto 0);
      full      : out std_logic;
      empty     : out std_logic );
  end component fifo_gen_bram;

  -- Initial phase 0.
  signal clk    : std_logic := '1';

  -- Synchronous reset.
  signal srst   : std_logic := '0';

  -- Write to FIFO.
  signal wr_en  : std_logic := '0';
  signal din    : std_logic_vector(WIDTH - 1 downto 0) := (others => '0');

  -- Read from FIFO.
  signal rd_en  : std_logic := '0';
  signal dout   : std_logic_vector(WIDTH - 1 downto 0);

  -- FIFO status flags.
  signal full   : std_logic;
  signal empty  : std_logic;

begin

  FIFO: fifo_gen_bram port map (
    clk     => clk,
    srst    => srst,
    din     => din,
    wr_en   => wr_en,
    rd_en   => rd_en,
    dout    => dout,
    full    => full,
    empty   => empty );

  -- Simulated clock.
  clk <= not clk after T_clk / 2;

  -- Standard mode read operations.
  -- Empty flag should be deasserted at end of 1st write period.
  --

  fifo_rw: process
  begin
    -- Initialization.
    wait for 3 * T_clk;
    assert empty = '1' report "FIF0 not empty" severity failure;
    assert full = '0'  report "FIFO full"  severity failure;

    -- 1st Write operation.
    wait until rising_edge(clk);
    wr_en <= '1';
    wr_en <= '0' after T_clk;
    din <= "11";

    -- empty deasserted almost immediately.
    wait for T_clk + 1 ns;
    assert empty = '0' report "FIF0 empty" severity failure;

    -- Standard Mode Read operation,
    -- data should be readable on first rising edge
    -- after the period rd_en is asserted.
    wait until rising_edge(clk);
    rd_en <= '1';
    rd_en <= '0' after T_clk;
    wait until rising_edge(clk);  -- 1st rising edge after rd_en.
    wait for 1 ns;
    assert dout = "11" report "FIF0 read error" severity failure;
    assert empty = '1' report "FIF0 not empty" severity failure;

    -- Write 4 FIFO words, interleave Read operations.
    wait until rising_edge(clk);
    wr_en <= '1';
    rd_en <= '1' after T_clk;
    
    din <= "01";
    wait until rising_edge(clk);

    din <= "10";
    wait until rising_edge(clk);

    din <= "11";
    wait until rising_edge(clk);

    din <= "00";
    wait until rising_edge(clk);

    wr_en <= '0';
    wait until rising_edge(clk);
    
    rd_en <= '0';
    
    wait;
  end process fifo_rw;

  -- According to PG057, no reset should be required
  -- for FIFO Common Clock BRAM implementations:
  -- but tests show that the empty signal remains unitilized
  -- until the first write operation.
  -- On the contrary, with a non asserted synchronous reset,
  -- the empty is initialized to 0 on startup.
  -- Usefulness of this SRST is questionable.
  fifo_srst: process
  begin
    wait until rising_edge(clk);
    srst <= '1';
    srst <= '0' after T_clk;

    wait;
  end process fifo_srst;

end architecture behavior;
