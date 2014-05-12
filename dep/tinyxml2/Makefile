# Simple makefile for building tinyxml2 as static lib
OBJECTS = tinyxml2.o
TARGET = libtinyxml2.a
CFLAGS = 
CC = cc

all: $(TARGET)

%.o: %.cpp
	$(CC) -g -c -o $@ $< $(CFLAGS)

clean: clean-obj clean-lib

clean-obj:
	rm -rf *.o
	
clean-lib:
	rm -rf $(TARGET)
	
$(TARGET): $(OBJECTS)
	ar rcs $(TARGET) $(OBJECTS)