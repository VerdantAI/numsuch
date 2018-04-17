use NumSuch, NN, LinearAlgebra.Sparse, Norm;
use Random,IO;

const p = 0.3,
      inputDim = 4,
      randomSeed = 17,
      nObservations = 50,
      epochs:int = 5000,
      lr: real = 0.1;

proc buildX(nobs: int) {
  var X = Matrix(nobs, inputDim);
  var R = Matrix(nobs, inputDim);
  fillRandom(R, randomSeed);
  for ij in X.domain {
    if R(ij) < p {
      X(ij) = 1;
    } else {
      X(ij) = 0;
    }
  }
  return X;
}




/*
 Populate y from an actual function so we know something exists
 */
proc yf(x: [] real) {
  var m = x.shape(1),
      n = x.shape(2);
  var y:[1..m] real;

  for i in 1..m {
    var w = 2*x[i,1] + 0.5*x[i,2] - 1.8*x[i,3] + x[i,4] + 0.7*x[i,2] * x[i,4] - x[i,1]*x[i,2]*x[i,3]*x[i,4];
    y[i] = w;
  }
  return Vector(y);
}
//var y = yf(X);



var f = open('nlfa.out.txt', iomode.cwr);
var w = f.writer();
w.writeln("epochs\t  obs\t h\tlr  \tnorm\tmax\tavg\t  time");
writeln("epochs\t  obs\t h\tlr  \tnorm\tmax\tavg\t  time");
for N in [50, 500] {
  var X = buildX(nobs = N);
  var y = yf(X);
  for e in [5000, 50000, 500000] {
    for l in [0.1, 0.01, 0.001] {
      for n in 1..10 {
        var model = new Sequential();
        model.add(new Dense(units=n, inputDim=inputDim, batchSize=N));
        model.add(new Dense(units=1));
        model.add(new Activation(name="relu"));
        var o = model.fit(xTrain=X,yTrain=y, epochs=e, lr=l);
        //writeln("\tepochs: %n observations: %n  hidden units: %n  norm(err): %n  max(err): %n  time: %n".format(epochs, nObservations, n, o.normError, o.maxError, o.elapsedTime));
        w.writeln("%6i\t%5i\t%2i\t%4.3dr\t%7.4dr\t%7.4dr\t%7.4dr\t%7.2dr".format(e, N, n, l, o.normError, o.maxError, o.avgError, o.elapsedTime));
        writeln("%6i\t%5i\t%2i\t%4.3dr\t%7.4dr\t%7.4dr\t%7.4dr\t%7.2dr".format(e, N, n, l, o.normError, o.maxError, o.avgError, o.elapsedTime));
      }
    }
  }
}
w.close();
f.close();

/*
var model = new Sequential();
model.add(new Dense(units=4, inputDim=inputDim, batchSize=nObservations));
model.add(new Dense(units=1));
//model.add(new Dense(units=6));
model.add(new Activation(name="relu"));

var o = model.fit(xTrain=X,yTrain=y, epochs=epochs, lr=lr);
writeln(o);
*/
