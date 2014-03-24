OS = $(shell uname -s)

LIBS = ""

ifneq (,$(findstring MINGW,$(OS)))
    LIBS = -lWs2_32
endif

CC = g++

TARGET = ircbot

OBJECTS = bot.o

CXXFLAGS = -Wno-write-strings

all: $(TARGET)

%.o: %.cpp
	$(CC) -g -c -o $@ $< $(CXXFLAGS)

clean: clean-obj clean-bin

clean-obj:
	rm -rf *.o
	
clean-bin:
	rm -rf $(TARGET)
	
$(TARGET): $(OBJECTS)
	$(CC) -g -o $(TARGET) $(OBJECTS) $(LIBS)
