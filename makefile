all:
	dmd -property -w -wi -O -release -ofqueue src/queue.d
