CC = g++
CFLAGS = -Wall -Wextra -lm -Werror
TARGET = day03
SRC = day03.cpp

$(TARGET): $(SRC)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS)

run: $(TARGET)
	./$(TARGET) $(ARG)

clean:
	rm -f $(TARGET)
