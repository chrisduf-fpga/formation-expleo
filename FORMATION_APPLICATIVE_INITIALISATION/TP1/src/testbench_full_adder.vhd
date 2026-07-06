library ieee;
use ieee.std_logic_1164.all;
 
entity testbench_full_adder is
end testbench_full_adder;
 
architecture behavior of testbench_full_adder is
	
	-- component declaration for the unit under test (uut)
	
	component full_adder
		port(
			A 	: in std_logic;
			B 	: in std_logic;
			Cin : in std_logic;
			S 	: out std_logic;
			Cout: out std_logic
		);
	end component;
	
	--Inputs
	signal A 	: std_logic := '0';
	signal B 	: std_logic := '0';
	signal Cin 	: std_logic := '0';
	
	--Outputs
	signal S 	: std_logic;
	signal Cout : std_logic;
	
begin
	
	-- Instantiate the Unit Under Test (UUT)
	uut: full_adder 
		port map (
			A => A,
			B => B,
			Cin => Cin,
			S => S,
			Cout => Cout
		);
	
-- Expected LUT
--	A  B  Cin  S  Cout
--	0  0   0   0   0
--	0  1   0   1   0
--	1  0   0   1   0
--	1  1   0   0   1
--	0  0   1   1   0
--	0  1   1   0   1
--	1  0   1   0   1
--	1  1   1   1   1
--
	process
	begin
	-- hold reset state for 100 ns.
	wait for 100 ns;
	
	--Valeurs des sorties attendues :
	--	A = B = Cin = 0
	--	Cout = 0
	--	S = 0
	assert (Cout = '0') and (S = '0')
	   report "Not expected LUT" severity failure;
	
	A <= '1';
	B <= '0';
	Cin <= '0';
	wait for 10 ns;	
	
	--Valeurs des sorties attendues :
	--	Cout = 0
	--	S = 1
	assert (Cout = '0') and (S = '1')
	   report "Not expected LUT" severity failure;
	
	
	A <= '0';
	B <= '1';
	Cin <= '0';
	wait for 10 ns;
	
	--Valeurs des sorties attendues :
	--	Cout = 0
	--	S = 1
	assert (Cout = '0') and (S = '1')
	   report "Not expected LUT" severity failure;

	
	
	A <= '1';
	B <= '1';
	Cin <= '0';
	wait for 10 ns;
	
	--Valeurs des sorties attendues :
	--	Cout = 1
	--	S = 0
	assert (Cout = '1') and (S = '0')
	   report "Not expected LUT" severity failure;

	
	
	A <= '0';
	B <= '0';
	Cin <= '1';
	wait for 10 ns;
	
	--Valeurs des sorties attendues :
	--	Cout = 0
	--	S = 1
	assert (Cout = '0') and (S = '1')
	   report "Not expected LUT" severity failure;
	
	
	
	A <= '1';
	B <= '0';
	Cin <= '1';
	wait for 10 ns;
	
	--Valeurs des sorties attendues :
	--	Cout = 1
	--	S = 0
	assert (Cout = '1') and (S = '0')
	   report "Not expected LUT" severity failure;
	
	
	
	A <= '0';
	B <= '1';
	Cin <= '1';
	wait for 10 ns;
	
	--Valeurs des sorties attendues :
	--	Cout = 1
	--	S = 0
	assert (Cout = '1') and (S = '0')
	   report "Not expected LUT" severity failure;
	
	
	
	A <= '1';
	B <= '1';
	Cin <= '1';
	wait for 10 ns;
	
	--Valeurs des sorties attendues :
	--	Cout = 1
	--	S = 1
	assert (Cout = '1') and (S = '1')
	   report "Not expected LUT" severity failure;
	
	
	A <= '0';
	B <= '0';
	Cin <= '0';
	
	-- Do not loop on process without stimuli.
	wait;
	
	end process;
	
end;
