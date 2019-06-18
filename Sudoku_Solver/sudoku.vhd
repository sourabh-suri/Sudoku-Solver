--------------------------------------------------------------Sudoku Solver using hardware accleration------------------------------------------------
--------------------------------------------------------------Synthesisable code on Quartus-----------------------------------------------------------
--------------------------------------------------------------Basic backtracking with contraints to acclerate the performance-------------------------
----------------------------------------------Process are independent and thus better performance than stack implemented C code--------------------------
library ieee; 
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
--------------------------------------------------------------Package------------------------------------------------------------------------------
package newtype is 
subtype cell_type is integer range 0 to 9;
subtype symbol is std_logic;
type sudoku_array is array (integer range 1 to 9, integer range 1 to 9) of cell_type;
type bitmap_array is array (integer range 0 to 9, integer range 0 to 9) of symbol;
type guess_type is array (integer range 1 to 9) of symbol;
type stack is array (integer range 0 to 127) of integer range 0 to 9;
end newtype; 
------------------------------------------------------------------Code starts here--------------------------------------------------------------------------
library ieee; 
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL; 
use work.newtype.all;
------------------------------------------------------------------Entity--------------------------------------------------------------------------
 entity sudoku is
 port(  clk, reset: in std_logic;
		 i : in std_logic_vector(3 downto 0);
		 j : in std_logic_vector(3 downto 0);
		 puzzle_buffer : in std_logic_vector(3 downto 0);
		 start: in std_logic;
		 ready: out std_logic);

end sudoku;
 ------------------------------------------------------------------Architecture--------------------------------------------------------------------------
architecture test of sudoku is
type state_type is (idle, next_empty_cell, guess, backtrack, solve);
signal state_present, state_next: state_type;
---------------------------------Easy Sudoku--------------------------------------------------------
signal puzzle : sudoku_array := ( (0,0,0,0,0,3,2,9,0),(0,8,6,5,0,0,0,0,0),(0,2,0,0,1,0,0,0,0)
										,(0,0,3,7,0,5,1,0,0),(9,0,0,0,0,0,0,0,8),(0,0,2,9,0,8,3,0,0)
											,(0,0,0,4,0,0,0,8,0),(0,4,7,1,0,0,0,0,0),(0,0,0,0,0,0,0,0,0) );
---------------------------------Hard Sudoku--------------------------------------------------------
--signal puzzle : sudoku_array := ( (8,0,0,0,0,0,0,0,0),(0,0,3,6,0,0,0,0,0),(0,7,0,0,9,0,2,0,0)
	--								,(0,5,0,0,0,7,0,0,0),(0,0,0,0,4,5,7,0,0),(0,0,0,1,0,0,0,3,0)
		--								,(0,0,1,0,0,0,0,6,8),(0,0,8,5,0,0,0,1,0),(0,9,0,0,0,0,4,0,0) );
											

---------------------------------Hard_2 Sudoku--------------------------------------------------------
--signal puzzle : sudoku_array := ( (6,0,0,0,0,0,0,0,3),(8,0,0,4,5,6,1,0,0),(0,5,0,0,0,0,0,0,0)
	--											,(0,1,5,9,0,0,3,0,0),(0,0,0,0,1,0,0,0,0),(0,6,0,0,8,0,5,0,7)
		--										,(0,0,2,0,0,0,0,0,0),(9,0,0,0,0,1,7,4,0),(4,7,0,0,9,0,0,0,6) );
--------------------------------------------------------------------------------------------------------------------------------------------								
signal bitmap_row : bitmap_array := (others=>(others=>('0'))); ----row 0 1o 9 and Symbol flag in each cell.
signal bitmap_col : bitmap_array := (others=>(others=>('0'))); ----col 0 1o 9 and Symbol flag in each cell.
signal bitmap_block : bitmap_array := (others=>(others=>('0')));---block 0 1o 9 and Symbol flag in each cell.
signal selected_row: integer range 0 to 9;-------------------------global signal to store value of selected row under operation.
signal selected_col:  integer range 0 to 9;------------------------global signal to store value of selected column under operation.
signal selected_block: integer range 0 to 9;-----------------------global signal to store value of selected block under operation.
signal valid: std_logic :='0';-------------------------------------signal to check if guess made by Guess state is valid element.
signal next_cell_found: std_logic :='0';------------------------- signal to check if next cell found by next empty state.
signal error: std_logic :='0';-- If guess state cannot produce any guess, it will set error and proceeds to backtracking state.
signal restored_last_valid_fill: std_logic :='0';--when backtrack clears the previous bit on stack and check for next vlaid element. 
signal all_cell_filled: std_logic :='0';-- If there are no emplty cells found.
signal stack_row : stack := (others=>(0)); --Stack to store row addresss map.
signal stack_col : stack := (others=>(0)); -- Stack to store column address map.
signal pointer : integer range 0 to 127 := 127; -- Stack pointer
signal symbol_variable: integer range 0 to 9;-- Variable poped from address of stack to be written here. 
signal update: std_logic :='0';-- signal to update bit map.
--------------------------------------------------Functionn returing block number of sudoku puzzle whose row and column is known------------------------------------------------------------------------------------------
 
function block_number_function ( i,j: integer) 
	return integer is
	variable block_i : integer range 0 to 10;
	variable block_j : integer range 0 to 10;
	variable block_number: integer range 0 to 9;
	variable index :integer range 0 to 80;   
begin
-------------------------------------------------block is determined using i-i%3 and j-j%3 where i and j are present index of row and column whose block number to be determined-----------------------------------------------
	block_i := ((i-1)-((i-1) mod 3))+1 ;    --temporary varibla to store i-i%3
	block_j := ((j-1) -((j-1) mod 3))+1;	--temporary varibla to store j-j%3
	index := (block_i)*10+(block_j);	
	case (index)  is						-- case statmenet to define block number from above iinformation
			when 11 =>
			block_number := 1;
			when 14 =>
			block_number := 2;
			when 17  =>
			block_number := 3;
			when 41  =>
			block_number := 4;
			when 44  =>
			block_number := 5;
			when 47  =>
			block_number := 6;
			when 71  =>
			block_number := 7;
			when 74  =>
			block_number := 8;
			when 77  =>
			block_number := 9;
			when others  =>
			block_number := 0;
		end case;
  return block_number;
end function;
 
 
 
 
 begin
  -------------------------------------To initialise and update the sequence of FSM------------------------------------------------------------------------
 process(clk, reset)
 begin
 if (reset='1') then
 state_present <= idle;
 elsif (clk'event and clk='1') then
 state_present <= state_next;
 end if;
 end process;
 -------------Control path: the logic that determines the next state of the FSM---------------------------------------------------- 
process(clk, reset, start)
 begin
 case state_present is
 when idle =>
	if ( start='1' ) then
		 state_next <= next_empty_cell;
	else
		 state_next <= idle;
	end if;
 when next_empty_cell =>
	if ( next_cell_found='1' ) then
		 state_next <= guess;
	elsif (all_cell_filled = '1') then
		 state_next <= solve;
	else
		 state_next <= next_empty_cell;
	 end if;
 when guess =>
	if (error='1' ) then
		 state_next <= backtrack;
	elsif (valid = '1') then
		 state_next <= next_empty_cell;
	else
		state_next <= guess;
	 end if;
 when backtrack =>
	if ( restored_last_valid_fill='1' ) then
		 state_next <= guess;
	else
		state_next <= backtrack;
		
	 end if;
when solve =>
	state_next <= idle;
 end case;
 end process;
-------------------------------------Control flow of FSM and its logic---------------------------------------------------------------------- 
process(state_present,clk)
variable guess_report : guess_type := (others=>('0')); 
variable Test_variable : integer range 0 to 9;
variable error_variable: std_logic:='1';
variable i_var : integer range 1 to 9;
variable j_var : integer range 1 to 9;
variable block_number: integer range 1 to 9;
variable variable1 : integer range 0 to 9;
---------------------------------
begin
case state_present is
---------------------------------When state is idle read the puzzle game to be entered by user---------------------------------------
 when idle=>
	i_var :=conv_integer(unsigned(i));
	j_var :=conv_integer(unsigned(j));
		if (i = "0000") then
			i_var:=1;
		end if;
		if (j="0000") then
			j_var:=1;
		end if;
 puzzle_in(i_var,j_var)<=conv_integer(unsigned(puzzle_buffer));
---------------------------------When state is next empty cell finding next empty cell by comparing with zero using priority encoder---------------------------------------

 when next_empty_cell =>
	valid<='0';
	loop1:    for i in integer range 1 to 9 loop --row
		loop2:		for j in integer range 1 to 9 loop --column
				Test_variable := (puzzle(i,j));
					if (Test_variable = 0) then
						selected_row <= i;
						selected_col <= j;
						selected_block<= block_number_function(i,j);
						next_cell_found <= '1';
						symbol_variable <= Test_variable;	
						exit loop1 when Test_variable = 0; ----------introducing priority
						exit loop2 when Test_variable = 0;
					elsif (i=9 and j=9 and Test_variable /= 0 ) then
						all_cell_filled <= '1'; --solve now
						exit loop1 when Test_variable = 0;
						exit loop2 when Test_variable = 0;
					else 
						selected_row<=0;
						selected_col<=0;
						selected_block<=0;
						next_cell_found <= '0';
						all_cell_filled <= '0';
						symbol_variable<=0;
					end if;
			end loop;				
		end loop;				
---------------------------------When state is guess finding next valid cell which is smallest valid and not rejected from backtrack using priority encoder---------------------------------------

when guess =>  
	error_variable:='1';
		selected_block<= block_number_function(selected_row,selected_col);
	for j in integer range 1 to 9 loop 
			guess_report(j) := bitmap_row(selected_row,j) or bitmap_col(selected_col,j) or bitmap_block(selected_block,j);
			error_variable := error_variable and guess_report(j);
	
	end loop;
	loop_i: for i in integer range 1 to 9 loop 
		if (guess_report(i) = '0' and restored_last_valid_fill = '0') then
			stack_row(pointer) <= selected_row;
			stack_col(pointer) <= selected_col;
			pointer <= pointer - 1;
			error <= '0';
			valid <='1'; -----goto next cell fsm
			puzzle(selected_row,selected_col) <= i; ------------------will update bitmap as next event
			update <= not update;
			exit loop_i;
		elsif (error_variable='1' and restored_last_valid_fill = '0') then
			error <= error_variable;
			valid<='0';
			exit loop_i;
		
		end if;
		end loop;
-------------------------------------------------------If the element is rejected from backtrack then choose the next larger valid element----------------------
		if (restored_last_valid_fill = '1' ) then
			selected_block<= block_number_function(selected_row,selected_col);
			for j in integer range 1 to 9 loop 
				guess_report(j) := bitmap_row(selected_row,j) or bitmap_col(selected_col,j) or bitmap_block(selected_block,j);
				error_variable := error_variable and guess_report(j);
				end loop;
			loop_2 : for i in integer range 1 to 9 loop 
				if ( i > variable1 and guess_report(i) = '0') then
				stack_row(pointer) <= selected_row;
				stack_col(pointer) <= selected_col;
				pointer <= pointer - 1;
						puzzle(selected_row, selected_col) <= i;
						update <= not update;
						error<='0';
						valid<='1';
						restored_last_valid_fill <='0';
				exit loop_2;
				else
					restored_last_valid_fill <='1';
				end if;
			end loop;
	end if;
	
--------------------------------------------------- Store and Clear the element from stack and ask for next vlaid element which is not the element cleared from the stack----------------	
when backtrack =>  
			pointer <= pointer + 1;
			selected_row <= stack_row(pointer+1);
			selected_col <= stack_col(pointer+1);
			selected_block<= block_number_function(stack_row(pointer+1),stack_col(pointer+1));
			symbol_variable <= puzzle(stack_row(pointer+1),stack_col(pointer+1));
			variable1 := puzzle(stack_row(pointer+1),stack_col(pointer+1));
			puzzle(stack_row(pointer+1),stack_col(pointer+1))<=0;
			update <= not update;
			restored_last_valid_fill<='1';
------------------------------------------------When no next element left is empty, puzzle is solved, move to idle state--------------------------

when solve=>
	ready <='1';
end case;
end process;

-------------------------------------------------------------------Update the bitmaps and candidate selection table-----------------------------------------------

 process(start,puzzle,bitmap_row,bitmap_col,bitmap_block)
	variable block_number: integer range 1 to 9;
	variable Test_variable : integer range 0 to 9;
	begin
	-------------------------------------------------------------MUX to initialse every bit to be zero unless filled using below logic----------------------------
			bitmap_row <= (others=>(others=>('0'))); 
			bitmap_col <= (others=>(others=>('0')));
			bitmap_block <= (others=>(others=>('0')));
    for i in integer range 1 to 9 loop --row
		for j in integer range 1 to 9 loop --column
			Test_variable := (puzzle(i,j));--------------------Loading element from puzzle and update its presence in bitmaps--------------------------------------
			block_number:= block_number_function(i,j);
			case Test_variable is------------------------------Update row, column and block number of identified element--------------------------------------------
				when 0  =>
				bitmap_row(i,Test_variable) <= '0';
				bitmap_col(j,Test_variable) <= '0';
				bitmap_block(block_number,Test_variable) <= '0';
				when 1  =>
				bitmap_row(i,Test_variable) <= '1';
				bitmap_col(j,Test_variable) <= '1';
				bitmap_block(block_number,Test_variable) <= '1';
				when 2  =>
				bitmap_row(i,Test_variable) <= '1';
				bitmap_col(j,Test_variable) <= '1';
				bitmap_block(block_number,Test_variable) <= '1';
				when 3  =>
				bitmap_row(i,Test_variable) <= '1';
				bitmap_col(j,Test_variable) <= '1';
				bitmap_block(block_number,Test_variable) <= '1';
				when 4  =>
				bitmap_row(i,Test_variable) <= '1';
				bitmap_col(j,Test_variable) <= '1';
				bitmap_block(block_number,Test_variable) <= '1';
				when 5  =>
				bitmap_row(i,Test_variable) <= '1';
				bitmap_col(j,Test_variable) <= '1';
				bitmap_block(block_number,Test_variable) <= '1';
				when 6  =>
				bitmap_row(i,Test_variable) <= '1';
				bitmap_col(j,Test_variable) <= '1';
				bitmap_block(block_number,Test_variable) <= '1';
				when 7  =>
				bitmap_row(i,Test_variable) <= '1';
				bitmap_col(j,Test_variable) <= '1';
				bitmap_block(block_number,Test_variable) <= '1';
				when 8  =>
				bitmap_row(i,Test_variable) <= '1';
				bitmap_col(j,Test_variable) <= '1';
				bitmap_block(block_number,Test_variable) <= '1';
				when 9  =>
				bitmap_row(i,Test_variable) <= '1';
				bitmap_col(j,Test_variable) <= '1';
				bitmap_block(block_number,Test_variable) <= '1';
				when others =>--------------------------------------Dont care for others
				bitmap_row(i,j) <= '-';
				bitmap_col(j,Test_variable) <= '-';
				bitmap_block(block_number,Test_variable) <= '-';
			end case;
		
		end loop;  -- j
    end loop;  -- i
end process;
end test;
-------------------------------------------------------------------end of code--------------------------------------------------------------------------------------------------------
