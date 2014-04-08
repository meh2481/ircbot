OS = $(shell uname -s)
LIBS = ./dep/lua/liblua.a
OBJECTS = bot.o parse.o network.o actions.o minihttp.o luainterface.o luafuncs.o
CXXFLAGS = -Wno-write-strings
INCLUDE = -I./dep/lua
CC = g++

TARGET = ircbot
ifeq ($(BUILD),debug)
    TARGET = ircbot_test
    CXXFLAGS = -Wno-write-strings -DDEBUG
endif

ifneq (,$(findstring MINGW,$(OS)))
    LIBS := $(LIBS) -lWs2_32
	TARGET := $(TARGET).exe
endif

all: lua $(TARGET)

%.o: %.cpp
	$(CC) -g -c -o $@ $< $(CXXFLAGS) $(INCLUDE)

clean: clean-obj clean-bin

clean-obj:
	rm -rf *.o
	
clean-bin:
	rm -rf $(TARGET)
	
lua:
	cd dep/lua && make
	
$(TARGET): $(OBJECTS)
	$(CC) -g -o $(TARGET) $(OBJECTS) $(LIBS)
