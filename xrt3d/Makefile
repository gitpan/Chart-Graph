RM = rm -f

# Parameters.

OBJECTS = xrt3d.o graph.o
PROGRAMS = graph

# Compiler flags

CPPFLAGS = -DSOLARIS -DSYSV -I$(XRTHOME)/include -D_ALL_SOURCE
#CFLAGS   = -g  -Xc -dalign $(CPPFLAGS)
#LDFLAGS = -L$(XRTHOME)/lib
CC=gcc
CPP=g++
CFLAGS=-g -O0 -I/usr/openwin/include -I/usr/dt/include $(CPPFLAGS) 
LDFLAGS = -L$(XRTHOME)/lib -L/usr/openwin/lib -L/usr/dt/lib -L/usr/local/lib/perl5/sun4-solaris/5.00404/CORE
LDLIBS = -lxrt3d -lMrm -lXm -lXt -lX11 -lm -lsocket -lgen -lnsl -ldl -lw -lg++ -lperl
LIB = XrtGraph.so
.SUFFIXES: .cpp $(.SUFFIXES)

# Standard targets

all: graph

lib: $(LIB)

$(LIB): xrt3d_wrap.o xrt3d.o
	$(CC) -G -o $(LIB) xrt3d_wrap.o xrt3d.o $(LDFLAGS) $(LDLIBS)

xrt3d_wrap.c: xrt3d.swig
	swig -perl5 xrt3d.swig
xrt3d_wrap.o: xrt3d_wrap.c
	$(CC) $(CFLAGS) -c $< -I/usr/local/lib/perl5/sun4-solaris/5.00404/CORE
	
graph: xrt3d.o graph.o
	$(CPP) $(CFLAGS) -o $@ graph.o xrt3d.o $(LDFLAGS) $(LDLIBS)
	$(XRTHOME)/bin/xrt_auth $@

tester: booga.o 
	$(CPP) $(CFLAGS) -o $@ booga.o XrtGraph.so $(LDFLAGS) $(LDLIBS)
	$(XRTHOME)/bin/xrt_auth $@

clean:
	$(RM) *.o $(PROGRAMS) core

# Inference rules

.c.o:
	$(CC) $(CFLAGS) -c $<
.cpp.o:
	$(CPP) $(CFLAGS) -c $<

# Header dependencies

xrt3d.o:	xrt3d.h
