include local.mk
CC=chpl
MODULES =-M$(CHARCOAL_HOME)/src
INCLUDES=-I$(BLAS_HOME)/include
LIBS=-L${BLAS_HOME}/lib -lblas
EXEC=numsuch
SRCDIR=src
BINDIR=target
TESTDIR=test
default: all

#all: NumSuch.chpl
all: $(SRCDIR)/NumSuch.chpl
	$(CC) $(INCLUDES) $(LIBS) $(MODULES) -o $(BINDIR)/$(EXEC) $<

mlp: mlp.chpl
	$(CC) $(INCLUDES) $(LIBS) -o mlp $<

test: $(TESTDIR)/NumSuchTest.chpl
	$(CC) -M$(SRCDIR) $(MODULES) $(FLAGS) ${INCLUDES} ${LIBS} -o $(TESTDIR)/test $<; \
	./$(TESTDIR)/test;  \
	rm $(TESTDIR)/test

run-test: test
