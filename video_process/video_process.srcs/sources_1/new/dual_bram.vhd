library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dual_BRAM is
    generic (
        addr_width : integer := 8;
        data_width : integer := 15 
    );
    port(
        clk: in std_logic;
        we : in std_logic;
        addr_wr, addr_rd : in std_logic_vector(addr_width-1 downto 0);
        din : in std_logic_vector(data_width-1 downto 0);
        dout : out std_logic_vector(data_width-1 downto 0)
        );
end dual_BRAM;

architecture arch of dual_BRAM is
    type ram_type is array (2**addr_width-1 downto 0) of std_logic_vector (data_width-1 downto 0);
    signal ram_dual_port : ram_type;
begin
    process(clk)
    begin 
        if (clk'event and clk='1') then
            if (we = '1') then -- write data to address 'addr_wr'
        -- convert 'addr_wr' type to integer from std_logic_vector
                ram_dual_port(to_integer(unsigned(addr_wr))) <= din;
            end if;
            dout<=ram_dual_port(to_integer(unsigned(addr_rd)));
        end if;
    end process;

    -- get address for reading data from 'addr_rd'
  -- convert 'addr_rd' type to integer from std_logic_vector
end arch;