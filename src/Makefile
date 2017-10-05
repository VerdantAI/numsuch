CC=chpl
INCLUDES=-I${ZMQ_BASE}/include -I$(BLAS_HOME)/include
LIBS=-L${ZMQ_BASE}/lib -lzmq -L${BLAS_HOME}/lib -lblas

default: all

all: NumSuch.chpl
	$(CC) $(INCLUDES) $(LIBS) -o numsuch $<

mlp: mlp.chpl
	$(CC) $(INCLUDES) $(LIBS) -o mlp $<
