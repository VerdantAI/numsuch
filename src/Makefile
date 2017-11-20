CC=chpl
INCLUDES=-I${ZMQ_BASE}/include -I$(BLAS_HOME)/include
LIBS=-L${ZMQ_BASE}/lib -lzmq -L${BLAS_HOME}/lib -lblas
SOURCES =  $(wildcard *.chpl)
default: all

#all: NumSuch.chpl
all: NumSuch.chpl Core.chpl
	$(CC) $(INCLUDES) $(LIBS) -o numsuch $(SOURCES)

mlp: mlp.chpl
	$(CC) $(INCLUDES) $(LIBS) -o mlp $<
