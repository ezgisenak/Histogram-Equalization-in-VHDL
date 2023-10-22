library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.std_logic_textio.all;

entity testbench is
end testbench;

architecture Behavioral of testbench is
    signal clk : STD_LOGIC := '0';
    signal wr_en : STD_LOGIC := '0';
    signal read_en : STD_LOGIC := '0';
    signal address : STD_LOGIC_VECTOR(7 downto 0) := (others => '0'); 
    signal data_in : STD_LOGIC_VECTOR(7 downto 0);
    signal data_out : STD_LOGIC_VECTOR(7 downto 0);
    signal finished : BOOLEAN := FALSE;
    signal read_finished : BOOLEAN := FALSE; 
begin

 UUT : entity work.BRAM
        port map (
            clk => clk,
            wr_en => wr_en,
            read_en => read_en,
            address => address,
            data_in => data_in,
            data_out => data_out
        );
    -- Clock generation
    clk_process: process
    begin
        wait for 5 ns;
        clk <= not clk;
    end process;

    -- Testbench process
    testbench_process: process
       
        variable data_in_line : LINE; -- For reading binary data
        variable data_in_value: STD_LOGIC_VECTOR(7 downto 0);
        file bin_file : TEXT open READ_MODE is "D:\Users\ezgi\project_1\pixel_values.txt";
        file output_file : TEXT open WRITE_MODE is "D:\Users\ezgi\project_1\output_file.txt";
        variable row : LINE;
    begin    
        -- Write data to BRAM
        while not read_finished loop
            readline(bin_file, data_in_line);
            read(data_in_line, data_in_value); -- Read binary data from the binary file
            data_in <= data_in_value;
            wr_en <= '1';
            wait until rising_edge(clk);
            wr_en <= '0';
            address <= std_logic_vector(unsigned(address) + 1);
            if address = "11111110" then
                read_finished <= TRUE;
            end if;
        end loop;
        
        address <= (others => '0'); 
        while not finished loop
            read_en <= '1';
            wait until rising_edge(clk);
            wait until rising_edge(clk);
            read_en <= '0';
            write(row, data_out);
            writeline(output_file, row);
            address <= std_logic_vector(unsigned(address) + 1);
            if address = "11111110" then
                finished <= TRUE;
            end if;
        end loop;
        
        address <= "00000000"; -- Reset address

    end process;

    -- Simulation termination process
    end_simulation: process
    begin
        wait until finished;
        report "Simulation finished" severity note;
        wait;
    end process;

end Behavioral;