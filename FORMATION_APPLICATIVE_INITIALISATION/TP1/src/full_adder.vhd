library ieee;
use ieee.std_logic_1164.all;


entity full_adder is

	Port ( 
		-- Input bits A and B
		A 		: in std_logic;
		B 		: in std_logic;
		-- Carry in
		Cin 	: in std_logic;

		-- Sum bit
		S 		: out std_logic;
		-- Carry out
		Cout	: out std_logic
	);

end full_adder;

architecture behavior of full_adder is

begin

	S <= A xor B xor Cin;
	Cout <= (A and B) or (A and Cin) or (B and Cin);

end behavior;

-- Alternative implementation, based on the non simplified form of Cout, 
-- and using a VHDL signal to avoid (A xor B) duplication.
-- 
--architecture behavior of full_adder is
--	signal A_xor_B: std_logic;

--begin
--	A_xor_B <= A xor B;

--	S <= A_xor_B xor Cin;
--	Cout <= (A_xor_B and Cin) or (A and B);

--end behavior;

