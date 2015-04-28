OS = $(shell uname -s)
LIBS = ./dep/lua/liblua.a ./dep/tinyxml2/libtinyxml2.a -lmbedtls -L./dep/win32 -L./dep/lin64
OBJECTS = bot.o network.o minihttp.o luainterface.o luafuncs.o
CXXFLAGS = -Wno-write-strings
INCLUDE = -I./dep/lua -I./dep/tinyxml2 -I./dep
CC = g++

TARGET = ircbot
ifeq ($(BUILD),debug)
    TARGET = ircbot_test
    CXXFLAGS = -Wno-write-strings -DDEBUG
endif

ifneq (,$(findstring MINGW,$(OS)))
    LIBS := $(LIBS) -lWs2_32
	TARGET := $(TARGET).exe
else
    LIBS := $(LIBS) -lrt
endif

all: lua tinyxml2 $(TARGET)

%.o: %.cpp
	$(CC) -g -c -o $@ $< $(CXXFLAGS) $(INCLUDE)

clean: clean-obj clean-bin

clean-obj:
	rm -rf *.o
	
clean-bin:
	rm -rf $(TARGET)
	
lua:
	cd dep/lua && make
	
tinyxml2:
	cd dep/tinyxml2 && make
	
$(TARGET): $(OBJECTS)
	$(CC) -g -o $(TARGET) $(OBJECTS) $(LIBS)
