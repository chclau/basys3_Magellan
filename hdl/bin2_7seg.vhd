------------------------------------------------------------------
-- Name        : bin2_7seg.vhd
-- Description : Binary to seven segment converter
-- Designed by : Claudio Avi Chami - FPGA'er website
--               http://fpgaer.tech
-- Date        : 04/August/2016
------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bin2_7seg is
   port (
      data_in:    in std_logic_vector (3 downto 0);
      data_out:   out std_logic_vector (6 downto 0)
   );
end bin2_7seg;

architecture rtl of bin2_7seg is

begin 
   with data_in select data_out <=
         "1000000" when x"0", 
         "1111001" when x"1", 
         "0100100" when x"2",    --  
         "0110000" when x"3",    --  ---0---
         "0011001" when x"4",    --  |     |
         "0010010" when x"5",    --  5     1
         "0000010" when x"6",    --  |     |
         "1111000" when x"7",    --  ---6---
         "0000000" when x"8",    --  |     |
         "0011000" when x"9",    --  4     2
         "0001000" when x"a",    --  |     |
         "0000011" when x"b",    --  ---3---
         "1000110" when x"c",    --
         "0100001" when x"d",
         "0000110" when x"e",
         "0001110" when x"f",
         "1111111" when others;
end rtl;
