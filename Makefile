include local.mk
CC=chpl
INCLUDES=-I$(BLAS_HOME)/include
LIBS=-L${BLAS_HOME}/lib -lblas
EXEC=numsuch
SRCDIR=src
BINDIR=target
default: all

#all: NumSuch.chpl
all: $(SRCDIR)/NumSuch.chpl
	$(CC) $(INCLUDES) $(LIBS) $(MODULES) -o $(BINDIR)/$(EXEC) $<

mlp: mlp.chpl
	$(CC) $(INCLUDES) $(LIBS) -o mlp $<
