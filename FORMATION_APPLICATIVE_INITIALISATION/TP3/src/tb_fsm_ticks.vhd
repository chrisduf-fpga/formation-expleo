library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity tb_fsm_ticks is
end tb_fsm_ticks;

architecture Behavorial of tb_fsm_ticks is

  -- Simulated 100 MHz clock.
  constant T  : time := 10 ns;

  -- Counter_unit configuration.
  -- Assuming 100 MHz clock, T counter is 20 us.
  constant K            : positive := 2000;

  -- Shared signals.
  signal clk         : std_logic := '0';    -- Clock LOW (falling edge) on startup.
  signal resetn      : std_logic := '0';    -- Assert nReset on startup.

  -- Counter_unit output, mapped to FSM_ticks input.
  signal end_counter : std_logic;

  -- Fsm_ticks I/0.
  signal restart     : std_logic := '0';              -- Do not restart on startup.
  signal ticks       : std_logic_vector(3 downto 0);  -- Counter of LED ON/OFF periods.

  -- LED is toggled on end_counter events, initially OFF
  signal LED         : std_logic := '1';

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
      clk           : in std_logic;
      resetn        : in std_logic;
      restart       : in std_logic;
      tick          : in std_logic;
      ticks         : out std_logic_vector(3 downto 0)
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

  uut: Fsm_ticks
    generic map (K => K)
    port map (
      clk => clk,
      resetn => resetn,
      restart => restart,
      tick => end_counter,
      ticks => ticks
    );

  -- 100 MHz clock simulation.
  process
  begin
    wait for T / 2;
    clk <= not clk;
  end process;

  -- De-assert asynchronous nReset.
  process
  begin
    wait for 1 ns;
    resetn <= '1';

    wait;
  end process;

  -- Simulate LED.
  process(clk, resetn, end_counter, restart)
  begin
    if resetn = '0' then
      LED <= '1';
    elsif rising_edge(clk) then
      if restart = '1' then
        LED <= '1';
      elsif end_counter = '1' then
        LED <= not LED;
      end if;
    end if;
  end process;

  -- Test expect values at known points in time.
  -- Note: Would like to also test the ticks_ce signal,
  --       but it's internal to Fsm_ticks.
  -- TODO: Approach to access Fsm_ticks.ticks_ce.      
  ut_ticks: process
  begin
    -- Initial state.
    wait for T/2; -- 5ns
    assert LED = '1'
      report "Initial state: LED" severity failure;
    assert end_counter = '0'
      report "Initial state: end_counter" severity failure;
--    assert ticks_ce = '0'
--      report "Initial state: ticks" severity failure;
    assert unsigned(ticks) = 0
      report "Initial state: ticks" severity failure;

    -- At about 19990 ns, check previous rising edge at t=19985ns.
    -- First end_counter event. 
    wait for 19985 ns;
    assert LED = '1'
      report "19985 ns: LED" severity failure;
    assert end_counter = '1'
      report "19985 ns: end_counter" severity failure;
--    assert ticks_ce = '0'
--      report "19985 ns: ticks" severity failure;
    assert unsigned(ticks) = 0
      report "19985 ns: ticks" severity failure;
    
    -- At about 20010 ns, check previous rising edge at t=19995.
    -- Enable ticks_ce. 
    wait for 20 ns;
    assert LED = '0'
      report "19995 ns: LED" severity failure;
    assert end_counter = '0'
      report "19995 ns: end_counter" severity failure;
--    assert ticks_ce = '1'
--      report "19995 ns: ticks" severity failure;
    assert unsigned(ticks) = 0
      report "19995 ns: ticks" severity failure;

    -- At about 40010 ns, check previous rising edge at t=39995.
    -- Increment ticks.
    wait for 20000 ns; 
    assert LED = '1'
      report "39995 ns: LED" severity failure;
    assert end_counter = '0'
      report "39995 ns: end_counter" severity failure;
--    assert ticks_ce = '0'
--      report "19995 ns: ticks" severity failure;
    assert unsigned(ticks) = 1
      report "39995 ns: ticks" severity failure;
    
    wait;
  end process;

  -- Test restart signal.  
  ut_restart: process
  begin
    -- Allow previous tests to complete before restart,
    -- and the next LED OFF state.
    wait for 110005 ns;
    -- State at restart time (note: happens at falling edge).
    assert LED = '0'
      report "Restart: LED" severity failure;
    assert end_counter = '0'
      report "Restart: end_counter" severity failure;
    assert unsigned(ticks) = 2
      report "Restart: ticks" severity failure;
        
    restart <= '1';
    wait for T;
    restart <= '0';
    
    -- About t=110010 ns.
    -- Next rising edge, ticks counter restarts from 0.
    wait for T;
    assert LED = '1'
      report "Restart + T/2: LED" severity failure;
    assert end_counter = '0'
      report "Restart + T/2: end_counter" severity failure;
    assert unsigned(ticks) = 0
      report "Restart + T/2: ticks" severity failure;

    -- About t=139985 ns.
    -- LED should be OFF, ticks counter still equals to 0.
    wait for 29970 ns;
    assert LED = '0'
      report "Restart + T/2 + 30 us: LED" severity failure;
    assert end_counter = '1'
      report "Restart + T/2 + 30 us: end_counter" severity failure;
    assert unsigned(ticks) = 0
      report "Restart + T/2 + 30 us: ticks" severity failure;

    -- At about t=139995 (next rising edge)
    -- LED OFF and ticks should equal to 1.
    wait for T;
    assert LED = '1'
      report "Restart + T/2 + 40 us: LED" severity failure;
    assert end_counter = '0'
      report "Restart + T/2 + 40 us: end_counter" severity failure;
    assert unsigned(ticks) = 1
      report "Restart + T/2 + 40 us: ticks" severity failure;
      
    wait;
  end process;
  
end Behavorial;
