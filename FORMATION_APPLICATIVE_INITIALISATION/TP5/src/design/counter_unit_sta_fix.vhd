-- Module Counter_unit.
--
-- Up counter modulo K.
-- * Q(t+1) = Q(t) + 1 mod K
-- * T_modK = K.T_clk
-- * f_modk = f_clk / K, duty cycle 1/K (1 clock period out of K)

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
-- Used to compute register width.
use IEEE.math_real."ceil";
use IEEE.math_real."log2";


-- Interface
--
entity counter_unit is
  generic (
    -- Counter modulo.
    -- * T_modK = K.T_clk
    -- * f_modK = f_clk/K

    -- Example for 100 MHz clock and f_modK = 1 Hz:
    -- * T_modK = 1s, K = 1E8
    K : positive := 1E8 );
  
  port (
    -- Clock signal.
    clk           : in std_logic;
    -- Asynchronous reset, active-low.
    resetn        : in std_logic;

    -- Counter modulo K signal, frequency f_clk/K and duty cycle 1/K.
    end_counter   : out std_logic );

end entity counter_unit;


-- RTL architecture.
--
architecture RTL of counter_unit is
  -- Required register width for a counter modulo K.
  constant N      : positive := integer(ceil(log2(real(K))));

  -- N-bit register to store the counter value modulo K.
  -- FIXME: initial state should rely on Power-on Reset signal.
  signal r_count  : unsigned(N-1 downto 0) := (others => '0');

  -- Pre-compute and register condition (r_count + 1 = K - 1)
  -- to avoid some delay on end_counter output logic.
  signal r_modK   : std_logic := '0';

  begin

    -- Pre-computed, no output logic.
    end_counter <= r_modK;

    rtl: process(clk, resetn)
    begin

      if (resetn = '0') then
        r_count <= (others => '0');
        r_modK <= '0';

      elsif rising_edge(clk) then
        -- r_count + 1 = K - 1, avoiding overflows.
        if (r_count = K - 2) then
          r_modK <= '1';
        else
          r_modK <= '0';
        end if;

        if (r_modK = '1') then
          r_count <= (others => '0');
        else
          r_count <= r_count + 1;
        end if;

      end if;

    end process rtl;
  
end architecture RTL;
