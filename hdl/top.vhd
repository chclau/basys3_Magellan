----------------------------------------------------------------------------------
-- Company:  FPGA'er
-- Engineer: Claudio Avi Chami - FPGA'er Website
--           http://fpgaer.tech
-- Create Date: 09.09.2022 
-- Module Name: top.vhd
-- Description: Top level of seven segment driver
--              Value to be shown is chosen by sw0 to sw15
--              Drives the four seven-segment devices in sequence
-- Dependencies: bin2_7seg
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
		CLK         : in  std_logic;
                  
		-- inputs     
		SW          : in  std_logic_vector(15 downto 0);
		
		-- outputs
		LED         : out std_logic_vector (15 downto 0);
    SSEG_CA 		: out std_logic_vector (7 downto 0);
    SSEG_AN 		: out std_logic_vector (3 downto 0)
	);
end top;


architecture rtl of top is
  component bin2_7seg is
     port (
        data_in:    in std_logic_vector (3 downto 0);
        data_out:   out std_logic_vector (6 downto 0)
     );
  end component;
	
  signal counter_reg  : std_logic_vector (17 downto 0);
	signal disp_drv     : std_logic_vector (3 downto 0) := "1110";
	signal disp_dig     : std_logic_vector (6 downto 0);
	signal disp_data_in : std_logic_vector (3 downto 0);

begin 
  LED <= SW;
  SSEG_AN <= disp_drv;
  SSEG_CA(6 downto 0) <= disp_dig;
  SSEG_CA(7) <= '1';   -- Digital point always off
  
  counter_pr: process (CLK) 
  begin 
    if (rising_edge(CLK)) then
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
  
  disp_data_in <= SW(3 downto 0) when disp_drv = "1110" else
                  SW(7 downto 4) when disp_drv = "1101" else
                  SW(11 downto 8) when disp_drv = "1011" else
                  SW(15 downto 12);
  
end rtl;