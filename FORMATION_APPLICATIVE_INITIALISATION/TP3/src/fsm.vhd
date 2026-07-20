library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity fsm is
  -- Counter unit configuration.
  generic (K : positive := 200000000);
  port (
    clk         : in std_logic;   -- Clock signal.
    resetn      : in std_logic;   -- Asynchronous nReset.
    restart     : in std_logic;   -- Restart Fsm_ticks counter.
    LED_R      : out std_logic;  -- S0 or S1
    LED_B      : out std_logic;  -- S0 or S2
    LED_G      : out std_logic   -- S0 or S3
  );
end fsm;

architecture Behavioral of fsm is

    -- Mapped to Counter_unit output, wired to FSM_ticks input.
    signal end_counter : std_logic;

    -- Mapped to FSM_ticks output.
    signal ticks       : std_logic_vector(3 downto 0);

    -- Allows to restart Fsm_ticks counter from FSM.
    signal restart_fsm_ticks : std_logic := '0';

    -- FSM.
    type state_t is (S0, S1, S2, S3);
    signal curr_state : state_t := S0;
    signal next_state : state_t := S0;

    -- LED drivers.
    signal sig_led_r   : std_logic := '0';
    signal sig_led_b   : std_logic := '0';
    signal sig_led_g   : std_logic := '0';

  component Counter_unit
    generic (K : positive);
    port (
      clk          : in std_logic;
      resetn       : in std_logic;
      end_counter  : out std_logic
     );
  end component;

  component Fsm_ticks
    generic (K : positive);
    port (
      clk         : in std_logic;
      resetn      : in std_logic;
      restart     : in std_logic;
      tick        : in std_logic;
      ticks       : out std_logic_vector(3 downto 0)
     );
  end component;

begin

  cu: Counter_unit
    generic map (K => K)
    port map (
      clk => clk,
      resetn => resetn,
      end_counter => end_counter
    );

  tck: Fsm_ticks
    generic map (K => K)
    port map (
      clk => clk,
      resetn => resetn,
      restart => restart_fsm_ticks,
      tick => end_counter,
      ticks => ticks
    );

  -- Whether to restart Fsm_ticks counter.
  restart_fsm_ticks <= '1' when (restart = '1') or (unsigned(ticks) = 6) else '0';

  -- LED drivers.
  LED_R <= sig_led_r when restart_fsm_ticks = '0' else '0';
  LED_B <= sig_led_b when restart_fsm_ticks = '0' else '0';
  LED_G <= sig_led_g when restart_fsm_ticks = '0' else '0';

  
  process(clk, resetn)
  begin
    if(resetn = '0') then
      curr_state <= S0;

    elsif rising_edge(clk) then
      if restart = '1' then
        curr_state <= S0;

      elsif restart_fsm_ticks = '1' then
        curr_state <= next_state;
      end if;

    end if;
  end process;

  process(curr_state, ticks)
  begin
    next_state <= curr_state;

    case curr_state is
      when S0 =>
        next_state <= S1;
        if (unsigned(ticks) mod 2 = 0) then
          sig_led_r <= '1';
          sig_led_b <= '1';
          sig_led_g <= '1';
        else
          sig_led_r <= '0';
          sig_led_b <= '0';
          sig_led_g <= '0';        
        end if;
        
      when S1 =>
        next_state <= S2;
        if (unsigned(ticks) mod 2 = 0) then
          sig_led_r <= '1';
        else
          sig_led_r <= '0';
        end if;
        sig_led_b <= '0';
        sig_led_g <= '0';

      when S2 =>
        next_state <= S3;
        if (unsigned(ticks) mod 2 = 0) then
          sig_led_b <= '1';
        else
          sig_led_b <= '0';
        end if;
        sig_led_r <= '0';
        sig_led_g <= '0';

      when S3 =>
        next_state <= S1;
        if (unsigned(ticks) mod 2 = 0) then
          sig_led_g <= '1';
        else
          sig_led_g <= '0';
        end if;
        sig_led_r <= '0';
        sig_led_b <= '0';

      when others =>
        next_state <= S0;  -- Combinational default.
    end case;

  end process;

end Behavioral;
