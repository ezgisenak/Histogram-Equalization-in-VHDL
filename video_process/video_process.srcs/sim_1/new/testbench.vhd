library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.std_logic_textio.all;

entity testbench is
    generic (
            ADDR_WIDTH: integer := 8; -- Generic from the top module
            DATA_WIDTH: integer := 15; -- Generic from the top module
            IMAGE_SIZE: integer := 112 * 200
        );
end testbench;

architecture Behavioral of testbench is
    signal clk                   : STD_LOGIC := '0';
    signal pixel_in              : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal histogram             : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal count                 : integer := 0;
    signal pixel_equalized       : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 downto 0);
    signal finished              : STD_LOGIC := '0';
    signal read_finished         : STD_LOGIC := '0';
    signal start_finished        : STD_LOGIC := '0';
    signal total_finished        : STD_LOGIC := '0';
    signal equalization_finished : STD_LOGIC := '0';
    signal summation_finished    : STD_LOGIC := '0';
    signal valid                 : STD_LOGIC := '0';
    signal reset_sig             : STD_LOGIC := '0';
    signal pixel_count           : integer := 0;
    
    -- FIFO signals and constants
    signal fifo_rd_en           : STD_LOGIC := '0';
    signal fifo_wr_en           : STD_LOGIC := '0';
    signal fifo_data_in         : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal fifo_data_out        : STD_LOGIC_VECTOR(7 downto 0);
    COMPONENT fifo_generator_0
  PORT (
    clk : IN STD_LOGIC;
    srst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    wr_rst_busy : OUT STD_LOGIC;
    rd_rst_busy : OUT STD_LOGIC 
  );
END COMPONENT;
begin

 UUT : entity work.Histogram
    generic map (
        ADDR_WIDTH => ADDR_WIDTH,
        DATA_WIDTH => DATA_WIDTH,
        IMAGE_SIZE => IMAGE_SIZE
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
            summation_finished    => summation_finished,
            finished              => finished,
            pixel_equalized       => pixel_equalized,
            total_finished        => total_finished 
        );
        
    fifo : fifo_generator_0
  PORT MAP (
    clk => clk,
    srst => reset_sig,
    din => fifo_data_in,
    wr_en => fifo_wr_en,
    rd_en => fifo_rd_en,
    dout => fifo_data_out,
    full => open,
    empty => open,
    wr_rst_busy => open,
    rd_rst_busy => open
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
        file pixel_values : TEXT open READ_MODE is "D:\Users\ezgi\video_process\pixel_values_video.txt";
        file vhdl_histogram : TEXT open WRITE_MODE is "D:\Users\ezgi\video_process\vhdl_histogram_video.txt";
        file vhdl_equalized_histogram : TEXT open WRITE_MODE is "D:\Users\ezgi\video_process\vhdl_equalized_histogram_video.txt";
        file vhdl_output_image : TEXT open WRITE_MODE is "D:\Users\ezgi\video_process\vhdl_output_video.txt";
        variable row : LINE;
    begin    
    
        while not endfile(pixel_values) loop
            -- reset everything
            pixel_count <= 0;
            start_finished <= '0';
            summation_finished <= '0';
            equalization_finished <= '0';
            valid <= '0';
            total_finished <= '0';
            read_finished <= '0';
            start_finished <= '0';
            count <= 0;
            finished <= '0';
            wait until rising_edge(clk);            
                       
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
            while pixel_count /= IMAGE_SIZE - 1 loop
                readline(pixel_values, pixel_in_line);
                read(pixel_in_line, pixel_in_value); -- Read binary data from the binary file
                pixel_in <= pixel_in_value;
                valid <= '1';
                wait until rising_edge(clk);
                fifo_wr_en <= '1';
                fifo_data_in <= pixel_in;
                pixel_count <= pixel_count + 1;
            end loop;
            wait until rising_edge(clk);
            fifo_wr_en <= '0';
            wait until rising_edge(clk);
            valid <= '0';
            wait until rising_edge(clk);
            
            
            read_finished <= '1';
            pixel_in <= (others => '0');
              
            wait until rising_edge(clk);
            wait until rising_edge(clk);
            
            
            while not finished = '1' loop
                valid <= '1';
                wait until rising_edge(clk);
                if pixel_in > 2 then
                    write(row, histogram);
                    writeline(vhdl_histogram, row);
                end if;
                pixel_in <= std_logic_vector(unsigned(pixel_in) + 1);
                if pixel_in = "11111111" then
                    for i in 0 to 2 loop
                        wait until rising_edge(clk); -- Synchronize with clock
                        write(row, histogram);
                        writeline(vhdl_histogram, row);
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
            wait until rising_edge(clk);
            wait until rising_edge(clk);
            wait until rising_edge(clk);
            summation_finished <= '1';
            valid <= '0';
                 
            pixel_in <= (others => '0');
           
            while not equalization_finished = '1' loop
                fifo_wr_en <= '0';
                valid <= '1';
                wait until rising_edge(clk);
                if pixel_in > 3 then
                    write(row, histogram);
                    writeline(vhdl_equalized_histogram, row);
                end if;
                pixel_in <= std_logic_vector(unsigned(pixel_in) + 1);
                if pixel_in = "11111110" then
                    for i in 0 to 4 loop
                        wait until rising_edge(clk); -- Synchronize with clock
                        write(row, histogram);
                        writeline(vhdl_equalized_histogram, row);
                    end loop;
                    equalization_finished <= '1';
                    wait until rising_edge(clk);
                    valid <= '0'; 
                end if;
            end loop;
            wait until rising_edge(clk);
            
            pixel_in <= (others => '0');
            valid <= '0'; 
            
            wait until rising_edge(clk);
            
            while not total_finished = '1' loop
                valid <= '1';
                pixel_in <= fifo_data_out;
                wait until rising_edge(clk);
                if count > 5 then
                    write(row, pixel_equalized);
                    writeline(vhdl_output_image, row);
                end if;
                count <= count + 1;
                if count > IMAGE_SIZE then
                    fifo_rd_en <= '0';
                else 
                    fifo_rd_en <= '1';
                end if;
                if count = IMAGE_SIZE + 4 then
                    total_finished <= '1';
                end if;
            end loop;
            
            valid <= '0';
                      
            wait until rising_edge(clk);
            wait until rising_edge(clk);
        
        end loop;
        
        
    end process;

    -- Simulation termination process
    end_simulation: process
    begin
        report "Simulation finished" severity note;
        wait;
    end process;

end Behavioral;