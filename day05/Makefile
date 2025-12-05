# Makefile
TARGET = day05
SRC = day05.rs

$(TARGET): $(SRC)
	rustc $< -o $@

run: $(TARGET)
	./$(TARGET) $(ARG)

clean:
	rm -f $(TARGET)
