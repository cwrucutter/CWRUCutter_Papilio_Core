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


entity wb_Dual_Quad_Encoder is
	port (
  	 wishbone_in : in std_logic_vector(61 downto 0);
	 wishbone_out : out std_logic_vector(33 downto 0);

		-- Counter Input
		ENC_ONE_A, ENC_ONE_B		: in  std_logic;
		ENC_TWO_A, ENC_TWO_B		: in std_logic
	);
end entity wb_Dual_Quad_Encoder;


architecture rtl of wb_Dual_Quad_Encoder is

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


		signal counter_Int_ONE : std_logic_vector(31 downto 0); --Internal counters
		signal counterInvalid_Int_ONE: std_logic; --Internal invalid counters
		signal counter_Int_TWO : std_logic_vector(31 downto 0); --Internal counters
		signal counterInvalid_Int_TWO: std_logic; --Internal invalid counters
		
		signal INCR_ONE,DECR_ONE : std_logic;
		signal INCR_TWO,DECR_TWO : std_logic;
		
	COMPONENT CWRUCutter_QuadDecoder_One
		PORT(
			CLK : IN std_logic;
			RST : IN std_logic;
			ENC_ONE_A : IN std_logic;
			ENC_ONE_B : IN std_logic;          
			INCR_ONE : OUT std_logic;
			DECR_ONE : OUT std_logic
			);
		END COMPONENT;	

		COMPONENT CWRUCutter_QuadDecoder_Two
		PORT(
			CLK : IN std_logic;
			RST : IN std_logic;
			ENC_TWO_A : IN std_logic;
			ENC_TWO_B : IN std_logic;          
			INCR_TWO : OUT std_logic;
			DECR_TWO : OUT std_logic
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



		CWRUCutter_QuadDecoder_One_inst: CWRUCutter_QuadDecoder_One
			port map (
				CLK   => wb_clk_i,
				RST   => wb_rst_i,
				ENC_ONE_A => ENC_ONE_A,
				ENC_ONE_B => ENC_ONE_B,
				INCR_ONE => INCR_ONE,
				DECR_ONE => DECR_ONE
			);			

		CWRUCutter_QuadDecoder_Two_inst: CWRUCutter_QuadDecoder_Two
			port map (
				CLK   => wb_clk_i,
				RST   => wb_rst_i,
				ENC_TWO_A => ENC_TWO_A,
				ENC_TWO_B => ENC_TWO_B,
				INCR_TWO => INCR_TWO,
				DECR_TWO => DECR_TWO
			);			
			
			

-- Counting process for counter_Int on clock signal

		CountProcess: process (wb_clk_i, wb_rst_i)
		begin
			if wb_rst_i = '1' then
				counter_Int_ONE <= (others => '0'); 
				counter_Int_TWO <= (others => '0'); 
			elsif rising_edge(wb_clk_i)  then --Clock
				-- count for encoder 1
				if (INCR_ONE='1')  then -- Count Up
					counter_Int_ONE <= counter_Int_ONE + '1';
				elsif (DECR_ONE='1') then -- Count Down
					counter_Int_ONE <= counter_Int_ONE - '1';
				end if;
				-- count for encoder 2
				if (INCR_TWO='1')  then -- Count Up
					counter_Int_TWO <= counter_Int_TWO + '1';
				elsif (DECR_TWO='1') then -- Count Down
					counter_Int_TWO <= counter_Int_TWO - '1';
				end if;
			end if;
			
		end process;
			
		


  -- Multiplex the data output (asynchronous)

	process(counter_Int_ONE,counter_Int_TWO,wb_adr_i)
  begin

    -- Multiplex the read depending on the address. Use only the 2 lowest bits of addr
	 -- This allows for addition of additional registers later

    case wb_adr_i(3 downto 2) is
      when "00" =>
		wb_dat_o <= counter_Int_ONE;  -- Output encoder ONE count
		when "01" =>
		wb_dat_o <= counter_Int_TWO;  -- Output encoder TWO count
      when others =>
        wb_dat_o <= (others => 'X'); -- Return undefined for all other addresses
    end case;

  end process;


end rtl;

