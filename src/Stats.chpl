module Stats {
  use Sort, BigInteger, Math, Random;

  /*
  Trying to make this as close as possible to the `SciPy Version<http://www.statsmodels.org/stable/_modules/statsmodels/distributions/empirical_distribution.html#ECDF`_
   */
  class ECDF {
    var nobs: int,
        odom = {1..nobs},
        dist: [odom] real,
        mx: real;

    proc init(x:[]) {
      sort(x);
      this.nobs = x.size;
      this.odom = {1..this.nobs};
      this.dist = x;
      this.mx = max reduce x;
    }
    proc this(x:[]) {
      var r: [x.domain] real;
      for i in x.domain {
        var p = findPosition(x[i]);
        r[i] = p;
      }
      return r;
    }

    proc this(x:real) {
      return findPosition(x);
    }

    proc findPosition(y) {
       var idx = 0;
       for i in 1..this.dist.size {
          if y < this.dist[i] {
            break;
          }
          idx = i;
       }
       return 1.0 * idx / this.nobs;
    }
  }

  /*
   Wrapper for BigInt.fac provided by Chapel.
   */

  proc factorial(k: int) {
    var b = new bigint();
    b.fac(k);
    return b;
  }

  /*
   The Poisson distribution.  Designed after https://stat.ethz.ch/R-manual/R-devel/library/stats/html/Poisson.html

   Find the the density of an integer n from a random Poisson X with lambda = l
   */
  proc dpois(n: int, l: real) {
    const f = factorial(n): real;
    var x = exp(-l) * l**n / f;
    return x;
  }

  /*
  Generate n random values from a Poisson rv with intensity lambda = l
  based on the first version here: https://en.wikipedia.org/wiki/Poisson_distribution#Generating_Poisson-distributed_random_variables
   */
  proc rpois(n: int, l: real) {
    var r: [1..n] real;
    for i in 1..n {
      r[i] = rpois(l);
    }
    return r;
  }

  proc rpois(l: real) {
    var L: real = exp(-l),
        k: int = 0,
        p: real = 1;
    do {
      k += 1;
      var u: [1..1] real;
      fillRandom(u);
      p = p * u[1];
    } while p > L;
    return k - 1;
  }
}
