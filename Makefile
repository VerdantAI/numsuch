include local.mk
CC=chpl
INCLUDES=-I${ZMQ_BASE}/include -I$(BLAS_HOME)/include
LIBS=-L${ZMQ_BASE}/lib -lzmq -L${BLAS_HOME}/lib -lblas
EXEC=numsuch
SRCDIR=src
BINDIR=bin
MODULES=-M$(CDO_HOME)/src
default: all

#all: NumSuch.chpl
all: $(SRCDIR)/NumSuch.chpl
	$(CC) $(INCLUDES) $(LIBS) $(MODULES) -o $(BINDIR)/$(EXEC) $<

mlp: mlp.chpl
	$(CC) $(INCLUDES) $(LIBS) -o mlp $<
