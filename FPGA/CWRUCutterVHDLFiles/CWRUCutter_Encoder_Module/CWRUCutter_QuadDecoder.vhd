------------------------------------------------------------
-- CWRUCutter_QuadDecoder.vhd
-- 
-- 
-- Given a quadrature encoder A/B channels, counts the encoder ticks in 4 phases
-- 
-- Inputs:
--   ENC_A: Encoder A channel
--   ENC_B: Encoder B channel
--   ENC_RESET: Reset the count
-- 
-- Outputs:
--   Up: Indicates if the number of ticks is rising
--	 Down: Indicates if the number of ticks is falling
-- Notes: 
--
-- History
-- 7/7/14: mak237- Created
------------------------------------------------------------

Library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CWRUCutter_QuadDecoder is
    port (
        CLK				: in  std_logic;
        RST				: in  std_logic;
        ENC_A			: in  std_logic;
        ENC_B			: in  std_logic;
        INCR			: out std_logic;
		  DECR			: out std_logic
      );
end CWRUCutter_QuadDecoder ;

architecture Behavioral of CWRUCutter_QuadDecoder  is
    signal enc_a_old, enc_b_old: std_logic;
	signal INCR_int, DECR_int : std_logic;
	signal count_enable : std_logic;
	signal count_direction : std_logic;
	signal count_invalid		: std_logic;
begin
	INCR <= INCR_int;
	DECR <= DECR_int;
    
	count_enable <= ENC_A XOR enc_a_old XOR ENC_B XOR enc_b_old;
	count_direction <= ENC_A XOR enc_b_old;
	count_invalid <= (ENC_A XOR enc_a_old) AND (ENC_B XOR enc_b_old);
	
    process(RST, CLK) 
    begin
      if(RST = '1') then
        enc_a_old    	<= '0';
        enc_b_old		<= '0';
		INCR_int		<= '0';
		DECR_int		<= '0';
      elsif rising_edge(clk) then
        enc_a_old <= ENC_A;
        enc_b_old <= ENC_B;
      	INCR_int		<= '0';
		DECR_int		<= '0';

		if (count_invalid = '1') then
			
		elsif (count_enable='1') then
			if (count_direction='1') then
				INCR_int <= '1';
			else
				DECR_int <= '1';
			end if;
		end if;
	end if;
	end process;
end Behavioral;