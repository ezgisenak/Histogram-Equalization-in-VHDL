library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.std_logic_textio.all;

entity testbench is
    generic (
            ADDR_WIDTH: integer := 8; -- Generic from the top module
            DATA_WIDTH: integer := 14 -- Generic from the top module
            -- Other generics for the testbench
        );
end testbench;

architecture Behavioral of testbench is
    signal clk                   : STD_LOGIC := '0';
    signal pixel_in              : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal histogram             : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
    signal histogram_equalized   : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
    signal finished              : STD_LOGIC := '0';
    signal read_finished         : STD_LOGIC := '0';
    signal start_finished        : STD_LOGIC := '0';
    signal equalization_finished : STD_LOGIC := '0';
    signal valid                 : STD_LOGIC := '0';
    signal reset_sig             : STD_LOGIC := '0';
begin

 UUT : entity work.Histogram
    generic map (
        ADDR_WIDTH => ADDR_WIDTH,
        DATA_WIDTH => DATA_WIDTH
    )
        port map (
            clk                   => clk,
            reset_sig             => reset_sig,
            pixel_in              => pixel_in,
            valid                 => valid,
            histogram             => histogram,
            read_finished         => read_finished,
            start_finished        => start_finished,
            equalization_finished => equalization_finished,
            finished              => finished
        );
        
    -- Clock generation
    clk_process: process
    begin
        wait for 5 ns;
        clk <= not clk;
    end process;
    
    reset_process: process
    begin
        reset_sig <= '1';
        wait for 5 ns;
        reset_sig <= '0';
        wait;
    end process;
   
    -- Testbench process
    testbench_process: process
        variable pixel_in_line : LINE; -- For reading binary data
        variable pixel_in_value: STD_LOGIC_VECTOR(ADDR_WIDTH - 1 downto 0);
        file bin_file : TEXT open READ_MODE is "D:\Users\ezgi\histogram_equalization\pixel_values.txt";
        file output_file : TEXT open WRITE_MODE is "D:\Users\ezgi\histogram_equalization\output_file.txt";
        variable row : LINE;
    begin    
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        pixel_in <= (others => '0'); 
        for i in 0 to 255 loop
            wait until rising_edge(clk); -- Synchronize with clock
            pixel_in <= std_logic_vector(unsigned(pixel_in) + 1);
        end loop;
        start_finished <= '1';
        
        -- Write data to BRAM
        wait until rising_edge(clk);
        while not endfile(bin_file) loop
            readline(bin_file, pixel_in_line);
            read(pixel_in_line, pixel_in_value); -- Read binary data from the binary file
            pixel_in <= pixel_in_value;
            valid <= '1';
            wait until rising_edge(clk);
            valid <= '0';
        end loop;
        valid <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        valid <= '0';
        
        read_finished <= '1';
        pixel_in <= (others => '0');
          
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        
        while not finished = '1' loop
            valid <= '1';
            wait until rising_edge(clk);
            valid <= '0'; 
            if pixel_in > 2 then
                write(row, histogram);
                writeline(output_file, row);
            end if;
            pixel_in <= std_logic_vector(unsigned(pixel_in) + 1);
            if pixel_in = "11111111" then
                valid <= '1';
                for i in 0 to 2 loop
                    wait until rising_edge(clk); -- Synchronize with clock
                    write(row, histogram);
                    writeline(output_file, row);
                end loop;
                finished <= '1';
                wait until rising_edge(clk);
                valid <= '0'; 
            end if;
        end loop;
        wait until rising_edge(clk);
        
        for i in 1 to 255 loop
            valid <= '1';
            wait until rising_edge(clk); -- Synchronize with clock
            pixel_in <= std_logic_vector(unsigned(pixel_in) + 1);
        end loop;
        
        equalization_finished <= '1';
        wait until rising_edge(clk);
        valid <= '0'; 
        
    end process;

    -- Simulation termination process
    end_simulation: process
    begin
        wait until finished = '1';
        report "Simulation finished" severity note;
        wait;
    end process;

end Behavioral;