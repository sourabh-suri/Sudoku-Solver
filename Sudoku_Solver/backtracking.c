#include <stdio.h>
#include <time.h> 
#define N 9



// Function to check if number assigning is valid or not???
int is_valid_num(int grid[N][N], int row, int col, int num) 
	{
		int startRow = row - (row % 3);
		int startCol = col - (col %3);
		int r=0,c=0, rowfound=0, colfound=0, boxfound=0;
		//Check for row
		for (int c = 0; c < 9; c++) 
		{
			if (grid[row][c] == num) 
			{
				  rowfound =  1;
				  break;
			}
		}
		

		//Check for col
		for (int r = 0; r < 9; r++)
		{
			if (grid[r][col] == num) 
			{
				 colfound = 1;
				 break;
			}
		}

		//Check for block



		for (int r = 0; r < 3; r++) 
			{
			for (int c = 0; c < 3; c++) 
				{
					if (grid[r + startRow][c + startCol] == num)
						{
							 boxfound = 1;
							 break;
						} 
				}
			}

	return (!rowfound && !colfound && !boxfound);
}

// Recursive function to solve puzzle....

int solve(int grid[N][N]) {
	
	int row = 0;
	int col = 0;
	int not_alloted = 1;

	//..........Finding empty spaces in grid..............


	for (row = 0; row < N; row++)
	 {
		for (col = 0; col < N; col++)
		 {
			if (grid[row][col] == 0)
			 {
				goto Continue; 			//Unalloted found
			}

		}
	}

	return 1; 						//End case
Continue: 
	for (int num = 1; num <= N; num++ ) 
	{
		
		if (is_valid_num(grid, row, col, num)) 
		{
			grid[row][col] = num;
			
			if (solve(grid)) 
			{
				return 1;
			}
			
			grid[row][col] = 0;
		}
	}
	
	return 0;


}

void print_grid(int grid[N][N]) {
	for (int row = 0; row < N; row++) {
		for (int col = 0; col < N; col++) {
			printf("%2d", grid[row][col]);
		}
		printf("\n");
	}
}

int main() {
	
	int grid_easy[N][N] = {{0,0,0, 0,0,3, 2,9,0},
			 {0,8,6, 5,0,0, 0,0,0},
			 {0,2,0, 0,0,1, 0,0,0},
			 {0,0,3, 7,0,5, 1,0,0},
			 {9,0,0, 0,0,0, 0,0,8},
			 {0,0,2, 9,0,8, 3,0,0},
			 {0,0,0, 4,0,0, 0,8,0},
			 {0,4,7, 1,0,0, 0,0,0}};

	int grid_hard[N][N] = {{8,0,0, 0,0,0, 0,0,0},
			 {0,0,3, 6,0,0, 0,0,0},
			 {0,7,0, 0,9,0, 2,0,0},
			 {0,5,0, 0,0,7, 0,0,0},
			 {0,0,0, 0,4,5, 7,0,0},
			 {0,0,0, 1,0,0, 0,3,0},
			 {0,0,1, 0,0,0, 0,6,8},
			 {0,0,8, 5,0,0, 0,1,0},
			 {0,9,0, 0,0,0, 4,0,0}};


	int grid_hard_2[N][N] ={ {6,0,0,0,0,0,0,0,3},
			{8,0,0,4,5,6,1,0,0},
			{0,5,0,0,0,0,0,0,0},
			{0,1,5,9,0,0,3,0,0},
			{0,0,0,0,1,0,0,0,0},
			{0,6,0,0,8,0,5,0,7},
		    {0,0,2,0,0,0,0,0,0},
			{9,0,0,0,0,1,7,4,0},
			{4,7,0,0,9,0,0,0,6} };


// Calculate the time taken by function()........
    clock_t t; 
    t = clock(); 
printf("To solve \n"); 
//Selecting Easy sudoku to be solved....
print_grid(grid_easy);
	if (solve(grid_easy)) {
		printf("Solution \n"); 
		print_grid(grid_easy);
	} else {
		printf("no solution");
	}
	
    t = clock() - t; 
    double time_taken = ((double)t)/CLOCKS_PER_SEC; // in seconds 
  
    printf("Program took %f seconds to execute \n", time_taken); 
    return 0; 

}
