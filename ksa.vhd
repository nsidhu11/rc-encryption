library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-- Entity part of the description.  Describes inputs and outputs

entity ksa is
  port(CLOCK_50 : in  std_logic;  -- Clock pin
       KEY : in  std_logic_vector(3 downto 0);  -- push button switches
       SW : in  std_logic_vector(17 downto 0);  -- slider switches
		 LEDG : out std_logic_vector(7 downto 0);  -- green lights
		 LEDR : out std_logic_vector(17 downto 0));  -- red lights
end ksa;

-- Architecture part of the description

architecture rtl of ksa is

   -- Declare the component for the ram.  This should match the entity description 
	-- in the entity created by the megawizard. If you followed the instructions in the 
	-- handout exactly, it should match.  If not, look at s_memory.vhd and make the
	-- changes to the component below
	
   COMPONENT s_memory IS
	   PORT ( address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
				 clock		: IN STD_LOGIC  := '1';
				 data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
				 wren		: IN STD_LOGIC ;
				 q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
   END component;
	
	COMPONENT d_memory IS
	   PORT ( address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		       clock		: IN STD_LOGIC  := '1';
		       data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
				 wren		: IN STD_LOGIC ;
				 q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
   END component;
	
	COMPONENT r_rom IS
	PORT(	address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
			clock		: IN STD_LOGIC  := '1';
			q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
	END component;

	-- Enumerated type for the state variable.  You will likely be adding extra
	-- state names here as you complete your design
	
	type state_type is (state_init, state_fill, state_wait_1, state_read_i, state_compute_j, state_wait_2, state_write_i, state_write_j,state_start_decrypt,state_wait_3,compute_j_decrypt,state_wait_4,write_i_decrypt,write_j_decrypt,read_f_decrypt,read_k_decrypt,get_f_decrypt,write_decrypt, state_done);
	signal state: state_type;
								
    -- These are signals that are used to connect to the memory													 
	 signal address_1,address_2, address_3 : STD_LOGIC_VECTOR (7 DOWNTO 0);	 
	 signal data_1, data_2 : STD_LOGIC_VECTOR (7 DOWNTO 0);
	 signal wren_1, wren_2 : STD_LOGIC;
	 signal q_1, q_2,q_3 : STD_LOGIC_VECTOR (7 DOWNTO 0);	
	 signal secret_key_0: std_logic_vector(7 downto 0):="000000"&sw(17 downto 16);
	 signal secret_key_1: std_logic_vector(7 downto 0):= sw(15 downto 8);
	 signal secret_key_2: std_logic_vector(7 downto 0):= sw(7 downto 0);
	 signal secret_key: unsigned(23 downto 0);
	
	 begin
	    -- Include the S memory structurally
	
       u0: s_memory port map (
	        address_1, clock_50, data_1, wren_1, q_1);
			  
		 u1: d_memory port map (
	        address_2, clock_50, data_2, wren_2, q_2);
		 u3: r_rom port map(
				address_3, clock_50, q_3);
		LEDR(17 downto 0)<=std_logic_vector(secret_key(17 downto 0));
			  
	process(clock_50)
		variable i: integer;
		variable j: integer;
		variable k: integer;
		variable temp: integer;
		variable key_bf: unsigned(21 downto 0):="0000000000000000000000";
		variable s_i,s_j,f:std_logic_vector(7 downto 0);
		variable decrypted_output: std_logic_vector(7 downto 0);
		begin
			if(rising_edge(clock_50))then
				case state is
					when state_init =>
						i:=0;
						j:=0;
						k:=0;
						s_i:="00000000";
						s_j:="00000000";
						wren_1<='1';
						address_1<="00000000";
						data_1<="00000000";
						secret_key<= "00" & key_bf;
						state<=state_fill;
						
					when state_fill =>
						i:=i+1;
						address_1 <= std_logic_vector(to_unsigned(i,8));
						data_1 <= std_logic_vector(to_unsigned(i,8));
						wren_1 <= '1';
						if(i>=255)then
							j:=0;
							i:=0;
							state<=state_read_i;
						else
							state<=state_fill;
						end if;
					
					when state_read_i =>
						wren_1 <='0';
						address_1 <= std_logic_vector(to_unsigned(i,8));
						state <= state_wait_1;
						
					when state_wait_1 =>
						state<=state_compute_j;
					
					when state_compute_j =>
						s_i:=q_1;
						if(i mod 3 = 0)then
							j:=j+ to_integer(unsigned(s_i));
							j:=j+ to_integer(secret_key(23 downto 16));--(unsigned(secret_key_0));
							j:=j mod 256;
						elsif(i mod 3 = 1)then
							j:=j+ to_integer(unsigned(s_i));
							j:=j+ to_integer(secret_key(15 downto 8));--(unsigned(secret_key_1));
							j:=j mod 256;
						elsif(i mod 3 = 2) then
							j:=j+ to_integer(unsigned(s_i));
							j:=j+ to_integer(secret_key(7 downto 0));--(unsigned(secret_key_2));
							j:=j mod 256;
						end if;
						wren_1 <='0';
						address_1 <=std_logic_vector(to_unsigned(j,8));
						state<=state_wait_2;
					
					when state_wait_2 =>
						state<=state_write_i;
					
					when state_write_i =>
						s_j:=q_1;
						wren_1<='1';
						data_1<=s_j;
						address_1<=std_logic_vector(to_unsigned(i,8));
						state<=state_write_j;	
						
					when state_write_j =>
						wren_1 <='1';
						data_1<=s_i;
						address_1<=std_logic_vector(to_unsigned(j,8));
						if(i<255)then
							i:=i+1;
							state<=state_read_i;
						else
							i:=0;
							j:=0;
							k:=0;
							state<=state_start_decrypt;
						end if;
					
					when state_start_decrypt =>
						i:=(i+1) mod 256;
						address_1<=std_logic_vector(to_unsigned(i,8));
						wren_1<='0';
						state<=state_wait_3;
					
					when state_wait_3 =>
						state <= compute_j_decrypt;
						
					when compute_j_decrypt =>
						s_i:=q_1;
						j:=(j+ to_integer(unsigned(s_i))) mod 256;
						wren_1<='0';
						address_1<=std_logic_vector(to_unsigned(j,8));
						state <= state_wait_4;
						
					when state_wait_4 =>
						state <= write_i_decrypt;
					
					when write_i_decrypt =>
						s_j:=q_1;
						wren_1<='1';
						data_1<=s_j;
						address_1<=std_logic_vector(to_unsigned(i,8));
						state<= write_j_decrypt;
					
					when write_j_decrypt =>
						wren_1 <= '1';
						data_1 <= s_i;
						address_1 <=std_logic_vector(to_unsigned(j,8));
						state<=read_f_decrypt;
						
					when read_f_decrypt =>
						wren_1<='0';
						temp:=(to_integer(unsigned(s_i))+to_integer(unsigned(s_j))) mod 256;
						address_1<= std_logic_vector(to_unsigned(temp,8));
						state<=read_k_decrypt;
						
					when read_k_decrypt =>
						address_3<=std_logic_vector(to_unsigned(k,8));
						state<=get_f_decrypt;
						
					when get_f_decrypt =>
						f:=q_1;
						state<=write_decrypt;
						
					when write_decrypt =>
						decrypted_output:=f xor q_3;
						if( (decrypted_output<"01100001" or decrypted_output>"01111010" ) and decrypted_output/="00100000") then
								key_bf:=key_bf+1;
								
								if(key_bf=0)then
									state<=state_done;
									LEDG<="00000001";
								else
									state<=state_init;
								end if;
								
						else
							wren_2<='1';
							data_2<=decrypted_output;
							address_2<=std_logic_vector(to_unsigned(k,8));
							
							
							if(k<31)then
								k:=k+1;
								state<=state_start_decrypt;
							else
								LEDG<="00000010";
								state<=state_done;
							end if;
							
						end if;
						
					when state_done =>
						state <= state_done;
				end case;
			end if;
	end process;
	
end RTL;


