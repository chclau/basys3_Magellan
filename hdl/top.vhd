----------------------------------------------------------------------------------
-- Company:  FPGA'er
-- Engineer: Claudio Avi Chami - FPGA'er Website
--           http://fpgaer.tech
-- Create Date: 08.09.2022 
-- Module Name: top.vhd
-- Description: Top level of simple design which lits four LEDs usign counter
--              LEDs speed changed by SW0
-- Dependencies: None
-- 
-- Revision: 1
-- Revision  1 - File Created
-- 
----------------------------------------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity top is
	
  port (
		reset     :  in std_logic;
		sys_clock :  in std_logic;
		
		-- inputs
		SW        :  in std_logic_vector(15 downto 0);
		
		-- outputs
		LED       : out std_logic_vector (15 downto 0);
    SSEG_CA   : out std_logic_vector (7 downto 0);
    SSEG_AN   : out std_logic_vector (3 downto 0)
	);
end top;

architecture rtl of top is
  component bd_wrapper is
    port (
      axil_regs_araddr  : out STD_LOGIC_VECTOR ( 31 downto 0 );
      axil_regs_arprot  : out STD_LOGIC_VECTOR ( 2 downto 0 );
      axil_regs_arready : in STD_LOGIC;
      axil_regs_arvalid : out STD_LOGIC;
      axil_regs_awaddr  : out STD_LOGIC_VECTOR ( 31 downto 0 );
      axil_regs_awprot  : out STD_LOGIC_VECTOR ( 2 downto 0 );
      axil_regs_awready : in STD_LOGIC;
      axil_regs_awvalid : out STD_LOGIC;
      axil_regs_bready  : out STD_LOGIC;
      axil_regs_bresp   : in STD_LOGIC_VECTOR ( 1 downto 0 );
      axil_regs_bvalid  : in STD_LOGIC;
      axil_regs_rdata   : in STD_LOGIC_VECTOR ( 31 downto 0 );
      axil_regs_rready  : out STD_LOGIC;
      axil_regs_rresp   : in STD_LOGIC_VECTOR ( 1 downto 0 );
      axil_regs_rvalid  : in STD_LOGIC;
      axil_regs_wdata   : out STD_LOGIC_VECTOR ( 31 downto 0 );
      axil_regs_wready  : in STD_LOGIC;
      axil_regs_wstrb   : out STD_LOGIC_VECTOR ( 3 downto 0 );
      axil_regs_wvalid  : out STD_LOGIC;
      clk               : out STD_LOGIC;
      reset             : in STD_LOGIC;
      rstn              : out STD_LOGIC_VECTOR ( 0 to 0 );
      sys_clock         : in STD_LOGIC
    );
  end component;

  component axil_regs_xil is
    generic (
      C_S_AXI_DATA_WIDTH	: integer	:= 16
    );
    port (
      s_axi_aclk	: in std_logic;
      s_axi_aresetn	: in std_logic;
      s_axi_awaddr	: in std_logic_vector(4 downto 0);
      s_axi_awvalid	: in std_logic;
      s_axi_awready	: out std_logic; 
      s_axi_wdata	: in std_logic_vector(c_s_axi_data_width-1 downto 0);
      s_axi_wvalid	: in std_logic;
      s_axi_wready	: out std_logic;
      s_axi_bresp	: out std_logic_vector(1 downto 0);
      s_axi_bvalid	: out std_logic;
      s_axi_bready	: in std_logic;
      s_axi_araddr	: in std_logic_vector(4 downto 0);
      s_axi_arvalid	: in std_logic;
      s_axi_arready	: out std_logic;
      s_axi_rdata	: out std_logic_vector(c_s_axi_data_width-1 downto 0);
      s_axi_rresp	: out std_logic_vector(1 downto 0);
      s_axi_rvalid	: out std_logic;
      s_axi_rready	: in std_logic;
    
      addr_mon      : in std_logic_vector(3 downto 0);
      data_mon      : out std_logic_vector(15 downto 0)
    );
  end component;

  component bin2_7seg is
     port (
        data_in:    in std_logic_vector (3 downto 0);
        data_out:   out std_logic_vector (6 downto 0)
     );
  end component;


	signal counter_reg : std_logic_vector (17 downto 0);
	signal clk         : std_logic;
	signal rstn        : std_logic;
  signal axil_regs_araddr  : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal axil_regs_arready : STD_LOGIC;
  signal axil_regs_arvalid : STD_LOGIC;
  signal axil_regs_awaddr  : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal axil_regs_awready : STD_LOGIC;
  signal axil_regs_awvalid : STD_LOGIC;
  signal axil_regs_bready  : STD_LOGIC;
  signal axil_regs_bresp   : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal axil_regs_bvalid  : STD_LOGIC;
  signal axil_regs_rdata   : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal axil_regs_rready  : STD_LOGIC;
  signal axil_regs_rresp   : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal axil_regs_rvalid  : STD_LOGIC;
  signal axil_regs_wdata   : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal axil_regs_wready  : STD_LOGIC;
  signal axil_regs_wvalid  : STD_LOGIC;
  signal rstn_slv          : STD_LOGIC_VECTOR ( 0 to 0 );

	signal disp_drv     : std_logic_vector (3 downto 0) := "1110";
	signal disp_dig     : std_logic_vector (6 downto 0);
	signal disp_data_in : std_logic_vector (3 downto 0);
	signal addr_mon     : std_logic_vector (3 downto 0);
	signal data_mon     : std_logic_vector (15 downto 0);
  signal regs_araddr  : STD_LOGIC_VECTOR ( 4 downto 0 );
  signal regs_awaddr  : STD_LOGIC_VECTOR ( 4 downto 0 );
  signal regs_rdata   : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal regs_wdata   : STD_LOGIC_VECTOR ( 15 downto 0 );

begin 
  rstn <= rstn_slv(0);
  LED  <= SW;
  SSEG_AN <= disp_drv;
  SSEG_CA(6 downto 0) <= disp_dig;
  SSEG_CA(7) <= '1';   -- Digital point always off
  addr_mon   <= SW(3 downto 0);
  regs_araddr <= axil_regs_araddr(4 downto 0);
  regs_awaddr <= axil_regs_awaddr(4 downto 0);
  axil_regs_rdata(15 downto 0) <= regs_rdata;
  axil_regs_rdata(31 downto 16) <= (others => '0');
  regs_wdata <= axil_regs_wdata(15 downto 0);
  
  counter_pr: process (clk) 
  begin 
    if (rising_edge(clk)) then
      counter_reg <= counter_reg - 1;	-- decrement counter
 
      -- change active seven-segment display
      if (counter_reg = 0) then
        if (disp_drv = "0111") then
          disp_drv <= "1110";
        else
          disp_drv <= disp_drv(2 downto 0) & '1';
        end if;
      end if;
    end if;
  end process counter_pr;

  bin2_7seg_i : bin2_7seg
  port map (
    data_in  => disp_data_in,
    data_out => disp_dig
  );
  
  disp_data_in <= data_mon(3 downto 0) when disp_drv = "1110" else
                  data_mon(7 downto 4) when disp_drv = "1101" else
                  data_mon(11 downto 8) when disp_drv = "1011" else
                  data_mon(15 downto 12);
         
  bd_wrapper_i : bd_wrapper
    port map (
      axil_regs_araddr  => axil_regs_araddr      ,
      axil_regs_arprot  => open                  ,
      axil_regs_arready => axil_regs_arready     ,
      axil_regs_arvalid => axil_regs_arvalid     ,
      axil_regs_awaddr  => axil_regs_awaddr      ,
      axil_regs_awprot  => open                  ,
      axil_regs_awready => axil_regs_awready     ,
      axil_regs_awvalid => axil_regs_awvalid     ,
      axil_regs_bready  => axil_regs_bready      ,
      axil_regs_bresp   => axil_regs_bresp       ,
      axil_regs_bvalid  => axil_regs_bvalid      ,
      axil_regs_rdata   => axil_regs_rdata       ,
      axil_regs_rready  => axil_regs_rready      ,
      axil_regs_rresp   => axil_regs_rresp       ,
      axil_regs_rvalid  => axil_regs_rvalid      ,
      axil_regs_wdata   => axil_regs_wdata       ,
      axil_regs_wready  => axil_regs_wready      ,
      axil_regs_wstrb   => open                  ,
      axil_regs_wvalid  => axil_regs_wvalid      ,
      clk               => clk                   ,
      reset             => reset                 ,
      rstn              => rstn_slv              ,
      sys_clock         => sys_clock         
    );
  
  axi_regs_i : axil_regs_xil
    port map (
      s_axi_aclk        => clk                   ,
      s_axi_aresetn     => rstn                  ,
      s_axi_awaddr      => regs_awaddr           ,
      s_axi_awvalid     => axil_regs_awvalid     ,
      s_axi_awready     => axil_regs_awready     ,
      s_axi_araddr      => regs_araddr           ,
      s_axi_arvalid     => axil_regs_arvalid     ,
      s_axi_arready     => axil_regs_arready     ,
      s_axi_wdata       => regs_wdata            ,
      s_axi_wvalid      => axil_regs_wvalid      ,
      s_axi_wready      => axil_regs_wready      ,
      s_axi_bvalid      => axil_regs_bvalid      ,
      s_axi_bresp       => axil_regs_bresp       ,
      s_axi_bready      => axil_regs_bready      ,
      s_axi_rdata       => regs_rdata            ,
      s_axi_rresp       => axil_regs_rresp       ,
      s_axi_rvalid      => axil_regs_rvalid      ,
      s_axi_rready      => axil_regs_rready      ,
      addr_mon          => addr_mon              ,  
      data_mon          => data_mon

    );

end rtl;