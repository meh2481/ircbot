OS = $(shell uname -s)
LIBS = ""
OBJECTS = bot.o parse.o network.o actions.o trex.o
CXXFLAGS = -Wno-write-strings
CC = g++

TARGET = ircbot
ifeq ($(BUILD),debug)
    TARGET = ircbot_test
    CXXFLAGS = -Wno-write-strings -DDEBUG
endif

ifneq (,$(findstring MINGW,$(OS)))
    LIBS = -lWs2_32
	TARGET := $(TARGET).exe
endif

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
