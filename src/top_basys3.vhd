library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


-- Lab 4
entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(15 downto 0);
        btnU    :   in std_logic; -- master_reset
        btnL    :   in std_logic; -- clk_reset
        btnR    :   in std_logic; -- fsm_reset
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is
    -- signal declarations
    signal rst_master : std_logic;
    signal rst_clk : std_logic;
    signal rst_fsm : std_logic;
    signal clk_slow : std_logic;
    signal floor_A : std_logic_vector(3 downto 0);
    signal floor_B : std_logic_vector(3 downto 0);
    signal minifloor_A: std_logic_vector(3 downto 0);
    signal mux_data : std_logic_vector(3 downto 0);
    signal mux_sel_n : std_logic_vector(3 downto 0);
    signal clk_tdm : std_logic;
  
	-- component declarations
    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
    
    component elevator_controller_fsm is
		Port (
            i_clk        : in  STD_LOGIC;
            i_reset      : in  STD_LOGIC;
            is_stopped   : in  STD_LOGIC;
            go_up_down   : in  STD_LOGIC;
            o_floor : out STD_LOGIC_VECTOR (3 downto 0)		   
		 );
	end component elevator_controller_fsm;
	
	component TDM4 is
		generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	   );
    end component TDM4;
     
	component clock_divider is
        generic ( constant k_DIV : natural := 50000000); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
    end component clock_divider;
    
    
	
begin
	-- PORT MAPS ----------------------------------------
    u_clkdiv_fsm : clock_divider
    	generic map (k_DIV => 50000000) --0.5s
    	port map (
    	   i_clk => clk,
    	   i_reset => rst_clk,
    	   o_clk => clk_slow
    	);
    	
    u_clkdiv_tdm : clock_divider
    	generic map (k_DIV => 1000) --0.5s
    	port map (
    	   i_clk => clk,
    	   i_reset => rst_clk,
    	   o_clk => clk_tdm
    	);
    	
    	
    elev_A : elevator_controller_fsm
        port map(
            i_clk => clk_slow,  
            i_reset => rst_fsm,
            is_stopped => sw(1),
            go_up_down => sw(0),
            o_floor => floor_A
        );
        
     elev_B : elevator_controller_fsm
            port map(
                i_clk => clk_slow,
                i_reset => rst_fsm,
                is_stopped=> sw(14),
                go_up_down => sw(15),
                o_floor => floor_B
         );
         
        --mux
        mux1: TDM4
            generic map (k_WIDTH => 4)
            port map(
                i_clk => clk_tdm,
                i_reset => rst_master,
                i_D3 => x"F",
                i_D2 => floor_B,
                i_D1 => x"F",
                i_D0 => minifloor_A,
                o_data => mux_data,
                o_sel => mux_sel_n
       );
       
       segdec : sevenseg_Decoder
            port map(
                i_Hex => mux_data,
                o_seg_n => seg
            );
      
	
	-- reset signals
	rst_master <= btnU;
	rst_clk <= btnL or rst_master;
	rst_fsm <= btnR;
	
        minifloor_A <= x"6" when minifloor_A > x"9" else floor_A;
		
	an <= mux_sel_n;

	led(15) <= clk_slow;
	led(14 downto 0) <= (others =>'0');
	
end top_basys3_arch;