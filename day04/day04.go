package main

import (
	"bufio"
	"fmt"
	"os"
)

func main() {
	if len(os.Args[1:]) != 1 {
		fmt.Println(fmt.Errorf("Provide filename as only command line argument."))
		return
	}

	// open the file:
	f, err := os.Open(os.Args[1])
	if err != nil {
		fmt.Println(fmt.Errorf("Could not open file."))
		return
	}
	defer f.Close()

	// read in the grid, '@' = 1, '.' = 0
	var grid [][]int32
	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		row := scanner.Text()
		arr := make([]int32, len(row))
		for i, c := range row {
			if c == '@' {
				arr[i] = 1
			} else {
				arr[i] = 0
			}
		}

		grid = append(grid, arr)
	}

	count := 0
	var dirs = [][2]int{
		{-1, -1}, {-1, 0}, {-1, 1},
		{0, -1}, {0, 1},
		{1, -1}, {1, 0}, {1, 1}}

	rows := len(grid)
	cols := len(grid[0])
	for i := range rows {
		for j := range cols {
			if grid[i][j] != 1 {
				continue
			}
			n := 0
			for _, d := range dirs {
				ii := i + d[0]
				jj := j + d[1]

				if ii >= 0 && ii < rows && jj >= 0 && jj < cols {
					if grid[ii][jj] == 1 {
						n++
					}
				}
			}
			if n < 4 {
				count++
			}
		}
	}

	fmt.Println("Part 1: ", count)

	totalRemoved := 0

	for {
		var toRemove [][2]int
		for i := range rows {
			for j := range cols {
				if grid[i][j] != 1 {
					continue
				}
				n := 0
				for _, d := range dirs {
					ii := i + d[0]
					jj := j + d[1]
					if ii >= 0 && ii < rows && jj >= 0 && jj < cols {
						if grid[ii][jj] == 1 {
							n++
						}
					}
				}
				if n < 4 {
					toRemove = append(toRemove, [2]int{i, j})
				}
			}
		}

		// remove cells:
		if len(toRemove) == 0 {
			break
		}
		for _, cell := range toRemove {
			i, j := cell[0], cell[1]
			grid[i][j] = 0
		}
		totalRemoved += len(toRemove)

	}
	fmt.Println("Part 2: ", totalRemoved)
}
