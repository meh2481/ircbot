OS = $(shell uname -s)
LIBS = ""
OBJECTS = bot.o parse.o network.o
CXXFLAGS = -Wno-write-strings
CC = g++

ifneq (,$(findstring MINGW,$(OS)))
    LIBS = -lWs2_32
endif

TARGET = ircbot
ifeq ($(BUILD),debug)
    TARGET = ircbot_test
    CXXFLAGS = -Wno-write-strings -DDEBUG
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
