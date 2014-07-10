-- All of this code is kludged together from other code. It may or may not work 
-- as intended. 


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library board;
use board.zpu_config.all;
use board.zpupkg.all;
use board.zpuinopkg.all;


entity wb_PWM_OUT is
	generic ( 
		COUNTER_BIT_WIDTH : integer := wordSize;
		COUNTER_INVALID_BIT_WIDTH : integer := wordSize;
		CHANNELS : integer := 1
		);
	port (
		wishbone_in : in std_logic_vector(61 downto 0);
		wishbone_out : out std_logic_vector(33 downto 0)

		-- Inputs
		--POS_PULSE_LEN : in std_logic_vector(31 downto 0) := (others => '0');
		--CYC_PULSE_LEN : in std_logic_vector(31 downto 0) := (others => '0');
	);
end entity wb_PWM_OUT;

architecture rtl of wb_PWM_OUT is

	signal POS_PULSE_LEN: std_logic_vector(31 downto 0);
	signal CYC_PULSE_LEN: std_logic_vector(31 downto 0);
	signal register2: std_logic_vector(7 downto 0);  -- Register 2 (8 bits)


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

  
  -- insert other signals here
	signal PWM_OUT : std_logic;
	
  -- end insert other signals
  
	COMPONENT CWRUCutter_PWMOutput
		PORT(
			CLK           : IN  std_logic;
			RST        : IN  std_logic;
			POS_PULSE_LEN : IN std_logic_vector(31 downto 0) := (others => '0');
			CYC_PULSE_LEN : IN std_logic_vector(31 downto 0) := (others => '0');
			PWM_OUT       : OUT  std_logic
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
  
  	channel_inst : for i in 0 to CHANNELS-1 generate
	
		CWRUCutter_PWMOutput_inst: CWRUCutter_PWMOutput
			port map (
				CLK				=> wb_clk_i,
				RST				=> wb_rst_i,
				POS_PULSE_LEN	=> POS_PULSE_LEN,
				CYC_PULSE_LEN	=> CYC_PULSE_LEN,
				PWM_OUT			=> PWM_OUT
			);
			
			
		end generate;
			
			
	process(PWM_OUT,wb_adr_i)
	begin

		-- Multiplex the read depending on the address. Use only the 2 lowest bits of addr
		-- This allows for addition of additional registers later

		case wb_adr_i(3 downto 2) is
		when "00" =>
				for i in 0 to CHANNELS-1 loop
					--if (wb_adr_i(15 downto 2) = std_logic_vector(to_unsigned(i, wb_adr_i'length)) ) then
						wb_dat_o <= (others => '0');
						wb_dat_o(0) <= PWM_OUT;  -- Output encoder count
					--end if;
				end loop;	
		when others =>
			wb_dat_o <= (others => 'X'); -- Return undefined for all other addresses
		end case;

	end process;



-- get values from ZPUino for POS_PULSE_LEN and CYC_PULSE_LEN
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
              POS_PULSE_LEN <= wb_dat_i;  -- Set register0
            when "10" =>
              CYC_PULSE_LEN <= wb_dat_i;  -- Set register1
            when "11" =>
              register2 <= wb_dat_i(7 downto 0); -- Only lower 8 bits for register2
            when others =>
              null; -- Nothing to do for other addresses
          end case;

        end if;

      end if;

  end process;
  
end rtl;