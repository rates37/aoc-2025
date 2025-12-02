CC = gcc
CFLAGS = -Wall -Wextra -lm -Werror
TARGET = day02
SRC = day02.c

$(TARGET): $(SRC)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS)

run: $(TARGET)
	./$(TARGET) $(ARG)

clean:
	rm -f $(TARGET)
