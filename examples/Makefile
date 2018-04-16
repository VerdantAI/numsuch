include ../local.mk
CC=chpl
BLAS_HOME= /usr/local/Cellar/openblas/0.2.20
INCLUDES=-I$(BLAS_HOME)/include
LIBS=-L${BLAS_HOME}/lib -lblas
MODULES=-M../src
FLAGS=--fast

all: test

labels: labelmatrix-from-file.chpl
	$(CC) $(FLAGS) $(MODULES) $(INCLUDES) $(LIBS) -o labels $<
	./labels
	rm labels

cos: cosineDistance.chpl
	$(CC) $(FLAGS) $(MODULES) $(INCLUDES) $(LIBS) -o cos $<
	./cos
	rm cos

lgd: linearGradientDescent.chpl
	$(CC) $(FLAGS) $(MODULES) $(INCLUDES) $(LIBS) -o lgd $< ; \
	./lgd; \
	rm lgd;

nlfa: nonlinearFunctionApproximation.chpl
	$(CC) $(FLAGS) $(MODULES) $(INCLUDES) $(LIBS) -o nlfa $< ; \
  ./nlfa; \
	rm nlfa
