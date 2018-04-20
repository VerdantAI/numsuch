use NumSuch, NN, LinearAlgebra.Sparse, Norm;
use Random,IO;

/*
 Can we train the NN to find the answer [1,1,0] ?
 */

const p = 0.3,
      inputDim = 7,
      randomSeed = 17,
      nObservations = 50,
      epochs:int = 5000,
      lr: real = 0.1;

proc buildX(nobs: int) {
  var X = Matrix(nobs, inputDim);
  var R: [1..nobs,1..3] real;
  fillRandom(R, randomSeed);
  for m in 1..nobs {
    for k in  1..3 {
      if R[m,k] < p then X[m,k] = 1.0;
    }                            // construct a backpack
    X[m, 3 + (m % 3) +1] = 1.0;  // Which object is being presented
    X[m,7] = (m % 2) : real;     // Collect or ignore action
  }
  return X;
}

/*
 state is  [backpack, options, choice]
          [have A?,  have B?,  have C?,  choosing A?,  choosing B?  choosing C?, collected=1 else 0]
  Correct answer is choose A and B, leave C
 */
proc yf(x:[] real) {
  var m = x.shape(1),
      n = x.shape(2);
  var y:[1..m] real;

  for i in 1..m {
    if x.equals([1.0,0.0,0.0, 0.0,1.0,0.0, 1.0]) {
      y[i] = 10;
    } else if x.equals([0.0,1.0,0.0, 1.0,0.0,0.0, 1.0]) {
      y[i] = 10;
    } else {
      y[i] = 0;
    }
  }
  return Vector(y);
}

var goldX = Matrix(2, inputDim);
goldX(1,..) = Vector([1.0,0.0,0.0, 0.0,1.0,0.0, 1.0]);
goldX(2,..) = Vector([1.0,0.0,0.0, 0.0,1.0,0.0, 0.0]);
writeln("goldX.shape %s", goldX.shape);
const fn = "ngh.out.txt";
var f = open(fn, iomode.cwr);
writeln("writing output to %s".format(fn));
var w = f.writer();
w.writeln("epochs\t  obs\t h\tlr  \tnorm\tmax\tavg\t  time");
for N in [50, 100] {
  var X = buildX(nobs = N);
  var y = yf(X);
  for e in [5000, 10000] {
    for l in [0.1] {
      for n in 1..5 {
        var model = new Sequential();
        model.add(new Dense(units=n, inputDim=inputDim, batchSize=N));
        model.add(new Dense(units=1));
        model.add(new Activation(name="relu"));
        var o = model.fit(xTrain=X,yTrain=y, epochs=e, lr=l);
        w.writeln("%6i\t%5i\t%2i\t%4.3dr\t%7.4dr\t%7.4dr\t%7.4dr\t%7.2dr".format(e, N, n, l, o.normError, o.maxError, o.avgError, o.elapsedTime));
        w.flush();
        f.fsync();
        var a1 = model.predict(goldX);
        writeln("a1 prediction: ", a1);
      }
    }
  }
}
w.close();
f.close();
