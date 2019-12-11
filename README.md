# CS66-ASSEMBLY-TETRIS

A standard tetris game board has 20 rows ×10 columns of blocks.

To travel from one row to the next would be:
   From starting column of one row:
   Next row = current Index + 10
   The starting square for every row would be every square at first square + 10.

The game should be a loop that:
   Moves the current tetris shape down one space.
   Reads in a keyboard input either [←] or [→] and moves the current tetris shape according to the user input. Must be a valid    move:
         -Each tetris shape is assigned to some of the memory of the game board.
         -A valid move is valid if incrementing or decrementing the position of the memory assigned to each tetris shape does            not pass the memory of each row, should be in the range of (first square of row to first square + 9).
         -A move is also valid if incrementing or decrementing the position of the memory assigned to each tetris shape does            not equal the memory passing the memory for last know set of available spaces. 
   Checks if the current tetris shape has reached the last set of available spaces since the placement of the previous shape.
         -At the beginning of the game the bottom most row of squares should be the set of available spaces.
         -If the last known set of available spaces has been reached (the memory addresses assigned for the current tetris               shape are equal to the memory addresses of the last known set of available spaces) then update the known set of               available spaces to consider the addresses assigned to the current tetris shape and then load the next shape onto             the game board.
         -Otherwise, keep reading in input.
   Checks to see if any rows have been filled after each placement of blocks.
      -If filled, the entire row will be set as 'available' and any memory that is 'set' as taken above each column drops down        to fill the gaps created.
   Updates the graphics for all blocks.
      -Graphics for the current moving tetris shape at each iteration of the loop
      -Graphics for taken spaces after the placement of each tetris shape
      -Graphics for spaces deleted after a row of squares has been filled

Potential issues
      -Boundaries
      -Threading: We need to update the falling block once a second, while reading keypresses as fast as possible
      -Colors
