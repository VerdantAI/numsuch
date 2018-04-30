use NumSuch, LinearAlgebra.Sparse, Norm;

/* Create some fake data */

/* Create the actual function w */
const EPSILON: real = 0.05,
      ETA: real = 0.005;
var n = 10,
    d = 50,
    w: [1..n] real;



// Create X, the data, using sparse data since that's how I roll
var D = CSRDomain(d,n),
    X = CSRMatrix(D, real);

for i in 1..d {
  for j in 1..n {
    D += (i,j);
    var r = rand(-1,1);
    X[i,j] = r;
  }
}

// Create y = f(X) = Xw
for i in 1..n do w[i] = rand(2,9);
const y = X.dot(w);
writeln("Actual y: ", y);
writeln("Actual w: ", w);
/* Run Procedure */

var theta = SGD(X=X, y=y, method="linear");
writeln("final theta: ", theta);


proc SGD(X:[] real, y:[] real, method:string = "linear") {
  if method=="linear" {
    return linearSGD(X=X, y=y);
  } else {
    halt("NO! You can't do that!!");
  }
}

proc linearSGD(X:[] real, y:[] real, epsilon:real=0.05, eta:real=0.05) {
  var rows = seq(1, X.domain.dim(1).size),
      ncols = X.domain.dim(2).size,
      theta:[1..ncols] real,
      loss: real = 1000,
      itr: int = 1;

  var yAvg = (+reduce y) / y.size;
  for i in 1..theta.size do theta[i] = yAvg;
  writeln("theta 0: ", theta);
  do {
    shuffle(rows);
    for r in rows {
        var x:[1..ncols] real;
        for j in X.domain.dimIter(2,r) {
          x[j] = X[r,j];
        }
        theta = theta - ETA * linearSGDdf(x=x,theta=theta, y=y[r]);
    }
    var yHat = X.dot(theta),
        err = yHat - y;
    loss = norm(err);
    //writeln("* iteration %n  loss = %n".format(itr, loss));
    itr += 1;
  } while loss >= epsilon && itr < 100;
  writeln("Loss after %n iterations: %n".format(itr, loss));
  return theta;
}


/*
 Calculates the derivative of (theta * x - y)^2
 */
proc linearSGDdf(x:[] real, theta:[] real, y: real) {
  var z: [1..theta.size] real;
  //var wx = theta.dot(x) - y;
  //writeln("wx: ", wx);
  for i in 1..theta.size {
    z[i] = 2*x[i] * (theta.dot(x) - y);  // Also transpose(x) * (theta.dot(x) - y)
  }
  return z;
}
