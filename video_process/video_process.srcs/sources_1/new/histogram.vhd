library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.all;

entity Histogram is
    Generic (
        ADDR_WIDTH: integer := 8;
        DATA_WIDTH: integer := 15;
        IMAGE_SIZE: integer := 112 * 200
    );
    Port (
        clk                   : in STD_LOGIC;
        reset_sig             : in STD_LOGIC;
        pixel_in              : in STD_LOGIC_VECTOR(ADDR_WIDTH - 1 downto 0); 
        histogram             : out STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0) := (others => '0');
        valid                 : in STD_LOGIC;
        read_finished         : in STD_LOGIC;
        start_finished        : in STD_LOGIC;
        finished              : in STD_LOGIC;
        total_finished        : in STD_LOGIC;
        equalization_finished : in STD_LOGIC;
        summation_finished    : in STD_LOGIC;
        pixel_equalized       : out STD_LOGIC_VECTOR(ADDR_WIDTH - 1 downto 0) := (others => '0')
    );
end Histogram;

architecture Behavioral of Histogram is
    signal bram_we                    : STD_LOGIC := '0';
    signal bram_addr_wr, bram_addr_rd : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal bram_din                   : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal bram_dout                  : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal cnt                        : integer := 0;
    signal temp_addr_buffer           : STD_LOGIC_VECTOR(4 * ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal prev_din                   : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
    signal sum                        : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0) := (others => '0'); 
    signal no_bins                    : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 downto 0);

    -- Instantiate the dual_BRAM component
    component dual_BRAM is
        generic (
            addr_width : integer := 8;
            data_width : integer := 15 
        );
        port (
            clk       : in STD_LOGIC;
            we        : in STD_LOGIC;
            addr_wr   : in STD_LOGIC_VECTOR(ADDR_WIDTH - 1 downto 0);
            addr_rd   : in STD_LOGIC_VECTOR(ADDR_WIDTH - 1 downto 0);
            din       : in STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
            dout      : out STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0)
        );
    end component;
    
    -- Define the states as a type
    type t_state is (START, WRITE, READ, IDLE, SUMMATION, CDF, HIST_EQ);

    -- Initialize the state to START
    signal STATE: t_state := IDLE;

begin
-- Connect the dual_BRAM component
    BRAM_inst: dual_BRAM
    generic map (
        addr_width => ADDR_WIDTH,
        data_width => DATA_WIDTH
    )
    port map (
        clk       => clk,
        we        => bram_we,
        addr_wr   => bram_addr_wr,
        addr_rd   => bram_addr_rd,
        din       => bram_din,
        dout      => bram_dout
    );
    
    process(clk)
    begin
        no_bins <= "11111111";
        if reset_sig = '1' then
            bram_din <= (others => '0');
            bram_we <= '0';
        elsif rising_edge(clk) then
            case STATE is
                when IDLE => 
                    bram_we <= '0';
                    
                    if not finished = '1' then
                        STATE         <= START;
                    end if;
                when START => 
                    bram_we <= '1';
                    bram_addr_wr  <= pixel_in;
                    bram_din      <= (others => '0');
                    if start_finished = '1' then
                        STATE <= WRITE;
                    end if;
                    cnt <= 0;
                    
                when WRITE => 
                    if valid = '1' then                    
                        cnt <= cnt + 1;
                        
                        if cnt > 1 then
                            if temp_addr_buffer(4 * ADDR_WIDTH - 1 downto 3 * ADDR_WIDTH) = temp_addr_buffer(2 * ADDR_WIDTH - 1 downto ADDR_WIDTH) and
                               temp_addr_buffer(3 * ADDR_WIDTH - 1 downto 2 * ADDR_WIDTH) /= temp_addr_buffer(2 * ADDR_WIDTH - 1 downto ADDR_WIDTH) then
                                bram_din <= prev_din + 1;
                            elsif temp_addr_buffer(3 * ADDR_WIDTH - 1 downto 2 * ADDR_WIDTH) = temp_addr_buffer(2 * ADDR_WIDTH - 1 downto ADDR_WIDTH) then
                                bram_din <= bram_din + 1;
                            else 
                                bram_din   <= bram_dout + 1;
                            end if;
                        else
                            bram_din <= bram_dout;
                        end if;
                                               
                        prev_din <= bram_din;
                        bram_addr_rd  <= pixel_in;
                        temp_addr_buffer(ADDR_WIDTH - 1 downto 0) <= pixel_in;
                        temp_addr_buffer(4 * ADDR_WIDTH - 1 downto ADDR_WIDTH) <= temp_addr_buffer(3 * ADDR_WIDTH - 1 downto 0);
                        bram_addr_wr  <= temp_addr_buffer(2 * ADDR_WIDTH - 1 downto ADDR_WIDTH);
                                
                    elsif read_finished = '1' then
                            STATE <= READ;
                    end if;
                when READ => 
                    if valid = '1' then
                        histogram <= bram_dout;
                        -- Set up the inputs for the BRAM read operation
                        bram_we       <= '0';
                        bram_addr_rd  <= pixel_in;
                        if finished = '1' then
                            bram_addr_rd  <= (others => '0');
                            sum <= bram_dout;
                            STATE <= SUMMATION;
                        end if;
                    end if;        
                when SUMMATION => 
                    if valid = '1' then
                        bram_we <= '0';
                        if pixel_in > 1 then
                        bram_we <= '1';
                        end if;
                        
                        if pixel_in > 2 then
                        sum <= sum + bram_dout;
                        bram_din <= sum + bram_dout;
                        else 
                        sum <= bram_dout;
                        bram_din <= sum;
                        end if;
                        
                        bram_addr_rd  <= pixel_in;
                        bram_addr_wr  <= temp_addr_buffer(2 * ADDR_WIDTH - 1 downto ADDR_WIDTH);
                        
                        temp_addr_buffer(ADDR_WIDTH - 1 downto 0) <= pixel_in;
                        temp_addr_buffer(4 * ADDR_WIDTH - 1 downto ADDR_WIDTH) <= temp_addr_buffer(3 * ADDR_WIDTH - 1 downto 0);
                        if summation_finished = '1' then
                            STATE <= CDF;
                        end if;
                    end if;     
                when CDF =>
                    if valid = '1' then
                        bram_we <= '0';
                        if pixel_in > 1 then
                        bram_we <= '1';
                        end if;
                        bram_addr_rd  <= pixel_in;
                        bram_din <= std_logic_vector(to_unsigned(to_integer(unsigned(bram_dout)) * to_integer(unsigned(no_bins)) / IMAGE_SIZE, DATA_WIDTH)); 
                        bram_addr_wr  <= temp_addr_buffer(2 * ADDR_WIDTH - 1 downto ADDR_WIDTH);
                        temp_addr_buffer(ADDR_WIDTH - 1 downto 0) <= pixel_in;
                        temp_addr_buffer(4 * ADDR_WIDTH - 1 downto ADDR_WIDTH) <= temp_addr_buffer(3 * ADDR_WIDTH - 1 downto 0);
                        histogram <= bram_din;
                        if equalization_finished = '1' then
                            STATE <= HIST_EQ;
                            bram_we <= '0';
                        end if;
                    end if;     
                when HIST_EQ => 
                    if valid = '1' then
                        bram_we       <= '0';
                        bram_addr_rd  <= pixel_in;
                        pixel_equalized <= bram_dout(7 downto 0);
                        if total_finished = '1' then
                            bram_addr_rd  <= (others => '0');
                            STATE <= IDLE;
                        end if;
                    end if;       
                                    
            end case;
        end if;
    end process;
end Behavioral;