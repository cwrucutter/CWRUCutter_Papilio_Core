-- All of this code is kludged together from other publicly available code. It may or may not work 
-- as intended. 


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library board;
use board.zpu_config.all;
use board.zpupkg.all;
use board.zpuinopkg.all;


entity wb_Quad_Encoder is
	port (
  	 wishbone_in : in std_logic_vector(61 downto 0);
	 wishbone_out : out std_logic_vector(33 downto 0);

		-- Counter Input
		ENC_A, ENC_B       : in  std_logic
	);
end entity wb_Quad_Encoder;


architecture rtl of wb_Quad_Encoder is

--Wishbone signals - Don't touch.
  signal  wb_clk_i:    std_logic;                     -- Wishbone clock
  signal  wb_rst_i:    std_logic;                     -- Wishbone reset (synchronous)
  signal  wb_dat_i:    std_logic_vector(31 downto 0); -- Wishbone data input  (32 bits)
  signal  wb_adr_i:    std_logic_vector(26 downto 2); -- Wishbone address input  (32 bits)
  signal  wb_we_i:     std_logic;                     -- Wishbone write enable signal
  signal  wb_cyc_i:    std_logic;                     -- Wishbone cycle signal
  signal  wb_stb_i:    std_logic;                     -- Wishbone strobe signal  

  signal  wb_dat_o:    std_logic_vector(31 downto 0); -- Wishbone data output (32 bits)
  signal  wb_ack_o:    std_logic;                      -- Wishbone acknowledge out signal
  signal  wb_inta_o:   std_logic;


		signal counter_Int : std_logic_vector(31 downto 0); --Internal counters
		signal counterInvalid_Int: std_logic; --Internal invalid counters


		signal INCR,DECR : std_logic;
	
	COMPONENT CWRUCutter_QuadDecoder
		PORT(
			CLK : IN std_logic;
			RST : IN std_logic;
			ENC_A : IN std_logic;
			ENC_B : IN std_logic;          
			INCR : OUT std_logic;
			DECR : OUT std_logic
			);
		END COMPONENT;	



begin
-- Unpack the wishbone array into signals so the modules code is not confusing.
  wb_clk_i <= wishbone_in(61);
  wb_rst_i <= wishbone_in(60);
  wb_dat_i <= wishbone_in(59 downto 28);
  wb_adr_i <= wishbone_in(27 downto 3);
  wb_we_i <= wishbone_in(2);
  wb_cyc_i <= wishbone_in(1);
  wb_stb_i <= wishbone_in(0); 
  
  wishbone_out(33 downto 2) <= wb_dat_o;
  wishbone_out(1) <= wb_ack_o;
  wishbone_out(0) <= wb_inta_o;
-- End unpacking Wishbone signals

  -- Asynchronous acknowledge

  wb_ack_o <= '1' when wb_cyc_i='1' and wb_stb_i='1' else '0';



		CWRUCutter_QuadDecoder_inst: CWRUCutter_QuadDecoder
			port map (
				CLK   => wb_clk_i,
				RST   => wb_rst_i,
				ENC_A => ENC_A,
				ENC_B => ENC_B,
				INCR => INCR,
				DECR => DECR
			);			


-- Counting process for counter_Int on clock signal

		CountProcess: process (wb_clk_i, wb_rst_i)
		begin
			if wb_rst_i = '1' then
				counter_Int <= (others => '0'); 
			elsif rising_edge(wb_clk_i)  then --Clock
				if (INCR='1')  then -- Count Up
					counter_Int <= counter_Int + '1';
				elsif (DECR='1') then -- Count Down
					counter_Int <= counter_Int - '1';
				end if;
			end if;
			
		end process;
			
		


  -- Multiplex the data output (asynchronous)

	process(counter_Int,wb_adr_i)
  begin

    -- Multiplex the read depending on the address. Use only the 2 lowest bits of addr
	 -- This allows for addition of additional registers later

    case wb_adr_i(3 downto 2) is
      when "00" =>
		wb_dat_o <= counter_Int;  -- Output encoder count
      when others =>
        wb_dat_o <= (others => 'X'); -- Return undefined for all other addresses
    end case;

  end process;


end rtl;

