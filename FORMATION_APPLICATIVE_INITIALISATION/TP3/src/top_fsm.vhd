library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity top_fsm is
  generic (K : positive := 200000000);
  port (
    clk     : in std_logic;
    BTN0    : in std_logic;
    BTN1    : in std_logic;
    LED1_R      : out std_logic;
    LED1_B      : out std_logic;
    LED1_G      : out std_logic
  );
end top_fsm;

architecture Behavorial of top_fsm is

  signal resetn   : std_logic;
  signal restart  : std_logic;

  component fsm
    generic (K : positive);
    port (
      clk         : in std_logic;
      resetn      : in std_logic;
      restart     : in std_logic;
      LED_R      : out std_logic;
      LED_B      : out std_logic;
      LED_G      : out std_logic
    );
  end component;

begin

  sate_machine: fsm
    generic map (K => K)
    port map (
      clk => clk,
      resetn => resetn,
      restart => restart,
      LED_R => LED1_R,
      LED_B => LED1_B,
      LED_G => LED1_G
    );

  resetn <= not BTN0;
  restart <= BTN1;

end Behavorial;
