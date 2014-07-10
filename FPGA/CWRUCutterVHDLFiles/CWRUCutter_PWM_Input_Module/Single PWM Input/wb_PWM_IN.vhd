
-- Insert information here
-----------------------------------------------------------------




library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity wb_PWM_IN is
  port (
  	 wishbone_in : in std_logic_vector(61 downto 0);
	 wishbone_out : out std_logic_vector(33 downto 0);
	 
	 
	 --other signals in/out
	 PWM_IN        : in  std_logic
     --POS_PULSE_LEN : out std_logic_vector(31 downto 0) := (others => '0');
     --CYC_PULSE_LEN : out std_logic_vector(31 downto 0) := (others => '0')

  );
  end entity wb_PWM_IN;
  
  architecture rtl of wb_PWM_IN is
  
  
		-- signals to be output
		signal POS_PULSE_LEN: std_logic_vector(31 downto 0);
		signal CYC_PULSE_LEN: std_logic_vector(31 downto 0);
  
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
  
  
  COMPONENT CWRUCutter_PWMInput
		PORT (
			CLK				: IN  std_logic;
			RST				: IN  std_logic;
			PWM_IN	      : IN  std_logic;
			POS_PULSE_LEN	: OUT std_logic_vector(31 downto 0) := (others => '0');
			CYC_PULSE_LEN	: OUT std_logic_vector(31 downto 0) := (others => '0')
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
  
  
		CWRUCutter_PWMInput_inst: CWRUCutter_PWMInput
			port map (
				CLK				=> wb_clk_i,
				RST       		=> wb_rst_i,
				PWM_IN    		=> PWM_IN,
				POS_PULSE_LEN 	=> POS_PULSE_LEN,
				CYC_PULSE_LEN 	=> CYC_PULSE_LEN
				);
				
				
	process(POS_PULSE_LEN, CYC_PULSE_LEN, wb_adr_i)
	begin
	
	
		case wb_adr_i(3 downto 2) is
		when "00" =>
			wb_dat_o <= POS_PULSE_LEN;
		when "01" =>
			wb_dat_o <= CYC_PULSE_LEN;
		when others =>
			wb_dat_o <= (others => 'X'); -- Return undefined for all other addresses
		end case;
	end process;
	
	
	process(wb_clk_i)
	begin
	
	if rising_edge(wb_clk_i) then  -- Synchronous to the rising edge of the clock



        -- Check if someone is writing
        if wb_cyc_i='1' and wb_stb_i='1' and wb_we_i='1' then
          -- Yes, it's a write. See for which register based on address
			case wb_adr_i(3 downto 2) is
				when "00" =>
					null;
				when "01" =>
					null;
				when "10" =>
					null;
				when others =>
					null;
			end case;
			
		end if;
	end if;
	
	end process;
	
end rtl;
			