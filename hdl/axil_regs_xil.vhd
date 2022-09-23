library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axil_regs_xil is
	generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 16
	);
	port (
		s_axi_aclk	: in std_logic;
		s_axi_aresetn	: in std_logic;
		s_axi_awaddr	: in std_logic_vector(4 downto 0);
		s_axi_awvalid	: in std_logic;
		s_axi_awready	: out std_logic;
		s_axi_wdata	  : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		s_axi_wvalid	: in std_logic;
		s_axi_wready	: out std_logic;
		s_axi_bresp	  : out std_logic_vector(1 downto 0);
		s_axi_bvalid	: out std_logic;
		s_axi_bready	: in std_logic;
		s_axi_araddr	: in std_logic_vector(4 downto 0);
		s_axi_arvalid	: in std_logic;
		s_axi_arready	: out std_logic;
		s_axi_rdata	  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		s_axi_rresp	  : out std_logic_vector(1 downto 0);
		s_axi_rvalid	: out std_logic;
		s_axi_rready	: in std_logic;
    
    addr_mon      : in std_logic_vector(3 downto 0);
    data_mon      : out std_logic_vector(15 downto 0)
	);
end axil_regs_xil;

architecture arch_imp of axil_regs_xil is

	-- AXI4LITE signals
	signal axi_awaddr	: std_logic_vector(4 downto 0);
	signal axi_awready	: std_logic;
	signal axi_wready	: std_logic;
	signal axi_bresp	: std_logic_vector(1 downto 0);
	signal axi_bvalid	: std_logic;
	signal axi_araddr	: std_logic_vector(4 downto 0);
	signal axi_arready	: std_logic;
	signal axi_rdata	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal axi_rresp	: std_logic_vector(1 downto 0);
	signal axi_rvalid	: std_logic;

	---------------------------------------------
	---- Signals for user logic register space
	---------------------------------------------
	---- Number of Slave Registers 16
	constant VER_ADDR     : std_logic_vector(3 downto 0) := x"0";
	constant DATE_ADDR    : std_logic_vector(3 downto 0) := x"1";
	constant SCRPAD_ADDR  : std_logic_vector(3 downto 0) := x"2";
	constant PWM_FREQ_DIV_ADDR  : std_logic_vector(3 downto 0) := x"3";
	constant PWM_DUTY0_ADDR     : std_logic_vector(3 downto 0) := x"4";
	constant PWM_DUTY1_ADDR     : std_logic_vector(3 downto 0) := x"5";
	constant PWM_DUTY2_ADDR     : std_logic_vector(3 downto 0) := x"6";
	constant PWM_DUTY3_ADDR     : std_logic_vector(3 downto 0) := x"7";
	signal reg_version	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := x"0001";
	signal reg_date    	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := x"0922";
	signal reg_scratchpad	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal reg_pwm_freq_div	: std_logic_vector(7 downto 0);
	signal reg_pwm_duty0	: std_logic_vector(7 downto 0);
	signal reg_pwm_duty1	: std_logic_vector(7 downto 0);
	signal reg_pwm_duty2	: std_logic_vector(7 downto 0);
	signal reg_pwm_duty3	: std_logic_vector(7 downto 0);
	signal slv_reg_rden	: std_logic;
	signal slv_reg_wren	: std_logic;
	signal reg_data_out	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal byte_index	: integer;
	signal aw_en	: std_logic;

begin
  -- Registers monitor mux
  mon_mux : process(all)
  begin
    data_mon <= (others => '0');
    case addr_mon is
      when VER_ADDR =>
        data_mon <= reg_version;
      when DATE_ADDR =>
        data_mon <= reg_date;
      when SCRPAD_ADDR =>
        data_mon <= reg_scratchpad;
      when PWM_FREQ_DIV_ADDR =>
        data_mon(7 downto 0) <= reg_pwm_freq_div;
      when PWM_DUTY0_ADDR =>
        data_mon(7 downto 0) <= reg_pwm_duty0;
      when PWM_DUTY1_ADDR =>
        data_mon(7 downto 0) <= reg_pwm_duty1;
      when PWM_DUTY2_ADDR =>
        data_mon(7 downto 0) <= reg_pwm_duty2;
      when PWM_DUTY3_ADDR =>
        data_mon(7 downto 0) <= reg_pwm_duty3;
      when others => null;
    end case;
  end process mon_mux;
        
	-- I/O Connections assignments
	s_axi_awready	<= axi_awready;
	s_axi_wready	<= axi_wready;
	s_axi_bresp	<= axi_bresp;
	s_axi_bvalid	<= axi_bvalid;
	s_axi_arready	<= axi_arready;
	s_axi_rdata	<= axi_rdata;
	s_axi_rresp	<= axi_rresp;
	s_axi_rvalid	<= axi_rvalid;

	-- Implement axi_awready generation
	-- axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	-- de-asserted when reset is low.
	process (s_axi_aclk)
	begin
	  if rising_edge(s_axi_aclk) then 
	    if s_axi_aresetn = '0' then
	      axi_awready <= '0';
	      aw_en <= '1';
	    else
	      if (axi_awready = '0' and s_axi_awvalid = '1' and s_axi_wvalid = '1' and aw_en = '1') then
	        -- slave is ready to accept write address when
	        -- there is a valid write address and write data
	        -- on the write address and data bus. this design 
	        -- expects no outstanding transactions. 
	        axi_awready <= '1';
	      elsif (s_axi_bready = '1' and axi_bvalid = '1') then
	        aw_en <= '1';
	        axi_awready <= '0';
	      else
	        axi_awready <= '0';
	      end if;
	    end if;
	  end if;
	end process;

	-- Implement axi_awaddr latching
	-- This process is used to latch the address when both 
	-- s_axi_awvalid and s_axi_wvalid are valid. 
	process (s_axi_aclk)
	begin
	  if rising_edge(s_axi_aclk) then 
	    if s_axi_aresetn = '0' then
	      axi_awaddr <= (others => '0');
	    else
	      if (axi_awready = '0' and s_axi_awvalid = '1' and s_axi_wvalid = '1' and aw_en = '1') then
	        -- write address latching
	        axi_awaddr <= s_axi_awaddr;
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- implement axi_wready generation
	-- axi_wready is asserted for one s_axi_aclk clock cycle when both
	-- s_axi_awvalid and s_axi_wvalid are asserted. axi_wready is 
	-- de-asserted when reset is low. 
	process (s_axi_aclk)
	begin
	  if rising_edge(s_axi_aclk) then 
	    if s_axi_aresetn = '0' then
	      axi_wready <= '0';
	    else
	      if (axi_wready = '0' and s_axi_wvalid = '1' and s_axi_awvalid = '1' and aw_en = '1') then
          -- slave is ready to accept write data when 
          -- there is a valid write address and write data
          -- on the write address and data bus. this design 
          -- expects no outstanding transactions.           
          axi_wready <= '1';
	      else
	        axi_wready <= '0';
	      end if;
	    end if;
	  end if;
	end process; 

	-- implement memory mapped register select and write logic generation
	-- the write data is accepted and written to memory mapped registers when
	-- axi_awready, s_axi_wvalid, axi_wready and s_axi_wvalid are asserted. write strobes are used to
	-- select byte enables of slave registers while writing.
	-- these registers are cleared when reset (active low) is applied.
	-- slave register write enable is asserted when valid address and data are available
	-- and the slave is ready to accept the write address and write data.
	slv_reg_wren <= axi_wready and s_axi_wvalid and axi_awready and s_axi_awvalid ;

	process (s_axi_aclk)
    variable loc_addr :std_logic_vector(3 downto 0); 
	begin
	  if rising_edge(s_axi_aclk) then 
      loc_addr := axi_awaddr(4 downto 1);
      if (slv_reg_wren = '1') then
        case loc_addr is
          when SCRPAD_ADDR =>
            axi_bresp      <= "00"; 
            reg_scratchpad <= s_axi_wdata;
          when PWM_FREQ_DIV_ADDR =>
            axi_bresp  <= "00"; 
            reg_pwm_freq_div <= s_axi_wdata(7 downto 0);
          when PWM_DUTY0_ADDR =>
            axi_bresp  <= "00"; 
            reg_pwm_duty0 <= s_axi_wdata(7 downto 0);
          when PWM_DUTY1_ADDR =>
            axi_bresp  <= "00"; 
            reg_pwm_duty1 <= s_axi_wdata(7 downto 0);
          when PWM_DUTY2_ADDR =>
            axi_bresp  <= "00"; 
            reg_pwm_duty2 <= s_axi_wdata(7 downto 0);
          when PWM_DUTY3_ADDR =>
            axi_bresp  <= "00"; 
            reg_pwm_duty3 <= s_axi_wdata(7 downto 0);
         when others => 
	          axi_bresp  <= "10";   -- slave decoder error, register is read/only or does not exist
        end case;
      end if;
	  end if;                   
	end process; 

	-- Implement write response logic generation
	-- The write response and response valid signals are asserted by the slave 
	-- when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	-- This marks the acceptance of address and indicates the status of 
	-- write transaction.
	process (s_axi_aclk)
	begin
	  if rising_edge(s_axi_aclk) then 
	    if s_axi_aresetn = '0' then
	      axi_bvalid  <= '0';
	    else
	      if (axi_awready = '1' and s_axi_awvalid = '1' and axi_wready = '1' and s_axi_wvalid = '1' and axi_bvalid = '0'  ) then
	        axi_bvalid <= '1';
	      elsif (s_axi_bready = '1' and axi_bvalid = '1') then   --check if bready is asserted while bvalid is high)
	        axi_bvalid <= '0';                                 -- (there is a possibility that bready is always asserted high)
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- implement axi_arready generation
	-- axi_arready is asserted for one s_axi_aclk clock cycle when
	-- s_axi_arvalid is asserted. axi_awready is 
	-- de-asserted when reset (active low) is asserted. 
	-- the read address is also latched when s_axi_arvalid is 
	-- asserted. axi_araddr is reset to zero on reset assertion.
	process (s_axi_aclk)
	begin
	  if rising_edge(s_axi_aclk) then 
	    if s_axi_aresetn = '0' then
	      axi_arready <= '0';
	      axi_araddr  <= (others => '1');
	    else
	      if (axi_arready = '0' and s_axi_arvalid = '1') then
	        -- indicates that the slave has acceped the valid read address
	        axi_arready <= '1';
	        -- read address latching 
	        axi_araddr  <= s_axi_araddr;           
	      else
	        axi_arready <= '0';
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_arvalid generation
	-- axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	-- S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	-- data are available on the axi_rdata bus at this instance. The 
	-- assertion of axi_rvalid marks the validity of read data on the 
	-- bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	-- is deasserted on reset (active low). axi_rresp and axi_rdata are 
	-- cleared to zero on reset (active low).  
	process (s_axi_aclk)
	begin
	  if rising_edge(s_axi_aclk) then
	    if s_axi_aresetn = '0' then
	      axi_rvalid <= '0';
	    else
	      if (axi_arready = '1' and s_axi_arvalid = '1' and axi_rvalid = '0') then
	        -- valid read data is available at the read data bus
	        axi_rvalid <= '1';
	      elsif (axi_rvalid = '1' and s_axi_rready = '1') then
	        -- read data is accepted by the master
	        axi_rvalid <= '0';
	      end if;            
	    end if;
	  end if;
	end process;
 
	-- Implement memory mapped register select and read logic generation
	-- Slave register read enable is asserted when valid address is available
	-- and the slave is ready to accept the read address.
	slv_reg_rden <= axi_arready and s_axi_arvalid and (not axi_rvalid) ;

	-- Output register or memory read data
	process( s_axi_aclk ) is
    variable loc_addr : std_logic_vector(3 downto 0);
	begin
	  if (rising_edge (s_axi_aclk)) then
      if (slv_reg_rden = '1') then
        -- When there is a valid read address (s_axi_arvalid) with 
        -- acceptance of read address by the slave (axi_arready), 
        -- output the read dada 
        -- Address decoding for registers read
        loc_addr := axi_araddr(4 downto 1);
        s_axi_rresp <= "00";
        case loc_addr is
          when VER_ADDR =>
            axi_rdata <= reg_version;
          when DATE_ADDR =>
            axi_rdata <= reg_date;
          when SCRPAD_ADDR =>
            axi_rdata <= reg_scratchpad;
          when PWM_FREQ_DIV_ADDR =>
            axi_rdata(7 downto 0)  <= reg_pwm_freq_div;
            axi_rdata(15 downto 8) <= (others => '0');
          when PWM_DUTY0_ADDR =>
            axi_rdata(7 downto 0)  <= reg_pwm_duty0;
            axi_rdata(15 downto 8) <= (others => '0');
          when PWM_DUTY1_ADDR =>
            axi_rdata(7 downto 0)  <= reg_pwm_duty1;
            axi_rdata(15 downto 8) <= (others => '0');
          when PWM_DUTY2_ADDR =>
            axi_rdata(7 downto 0)  <= reg_pwm_duty2;
            axi_rdata(15 downto 8) <= (others => '0');
          when PWM_DUTY3_ADDR =>
            axi_rdata(7 downto 0)  <= reg_pwm_duty3;
            axi_rdata(15 downto 8) <= (others => '0');
          when others =>
            axi_rdata  <= (others => '0');
            s_axi_rresp <= "10";    -- slave decode error, read register does not exist
        end case;
      end if;   
	  end if;
	end process;

end arch_imp;
