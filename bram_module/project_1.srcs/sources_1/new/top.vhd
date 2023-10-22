library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity BRAM is
    Generic (
        ADDR_WIDTH: integer := 8;
        DATA_WIDTH: integer := 8
    );
    Port (
        clk      : in  STD_LOGIC;
        wr_en    : in  STD_LOGIC;
        read_en  : in  STD_LOGIC;
        address  : in  STD_LOGIC_VECTOR(ADDR_WIDTH - 1 downto 0);
        data_in  : in  STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
        data_out : out STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0)
    );
end BRAM;

architecture Behavioral of BRAM is
    use IEEE.NUMERIC_STD.ALL;
    type ram_type is array (0 to 2 ** ADDR_WIDTH -1) of STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
    signal ram : ram_type;
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if wr_en = '1' then
                ram(to_integer(unsigned(address))) <= data_in;
            end if;
            if read_en = '1' then
                data_out <= ram(to_integer(unsigned(address)));
            end if;
        end if;
    end process;
end Behavioral;