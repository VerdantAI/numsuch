module Stats {
  use Sort, BigInteger, Math, Random;

  /*
  Trying to make this as close as possible to the `SciPy Version <http://www.statsmodels.org/stable/_modules/statsmodels/distributions/empirical_distribution.html#ECDF>`_
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

  /*
    Generate a single Poisson random variable
   */
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

  /*
   The Gamma distribution, density function
   */
   proc dgamma(x: real, shape: real, scale: real) {
     var y = (x**(shape-1) * exp(-x / scale)) / (scale**shape * tgamma(shape));
     return y;
   }

   /*
    The Gamma distribution, random generation.

    From this paper? https://arxiv.org/pdf/1304.3800.pdf
    Or maybe this one, includes C code: http://www.hongliangjie.com/2012/12/19/how-to-generate-gamma-random-variables/

    :TODO: Finish the Gamma distribution
    */
    proc rgamma() {
      return 0;
    }

    /*
    Routine to choose from a set, hopefully follwing this:
    https://docs.scipy.org/doc/numpy-dev/reference/generated/numpy.random.choice.html

    :returns: array of choices, size
     */
    proc choice(a:[] ?t, size=1, replace=true) {
      var b: [1..0] a.eltType,
          result: [1..0] a.eltType;

      for i in a do b.push_back(a);
      if !replace {
        shuffle(b);
        result = b[1..size];
      } else {
          for i in 1..size {
            shuffle(b);
            result.push_back(b[1]);
            b.remove(1);
          }
      }
      return result;
    }


    proc choice(a:[] ?t, size=1, replace=true, p:[] ?u) {
      return chooseMultinomial(a=a,size=size,replace=replace,p=p);
    }

    /*
    Well, I'll be damned. This is what I came up with over a cup of coffee
    https://en.wikipedia.org/wiki/Multinomial_distribution#Sampling_from_a_multinomial_distribution
     */
    proc chooseMultinomial(a:[] ?t, size:int, replace=true, p:[] real) {
      var result: [1..0] a.eltType,
          r: [1..size] real,
          b = for i in a do i:a.eltType,
          q = for i in p do i:p.eltType;

      fillRandom(r);

      for i in 1..size {
        var sum: real = 0,
            k: int = 1,
            denom: real = + reduce q;
        const c = r[i];

        do {
          sum += q[k]/denom;
          k+= 1;
        } while sum <= c;
        result.push_back(b[k-1]);
        if !replace {
          b.remove(k-1);
          q.remove(k-1);
        }
      }
      return result;
    }

   /*
    Returns a random integer between `a <= N <= b`
   */
   proc randInt(a:int, b:int) {
     var rs: [1..1] real;
     fillRandom(rs);
     return (floor(rs[1] * b) + a):int;
   }

   /* Get a random number drawn uniformly along [a,b] */
   proc rand(a:real, b:real) {
     if b <= a then halt();
     var rs: [1..1] real;
     fillRandom(rs);
     return (rs[1]*(b-a)+a);
   }

   /* Returns a sequence as an integer array from a to b, inclusive */
   proc seq(start: int, stop: int) {
     if start >= stop then halt();
     var x: [1..stop-start+1] int;
     for i in 1..stop-start+1 do x[i] = start+i-1;
     return x;
   }

   /*
    Returns the sum of rolling `n` `s`-sided dice.  E.g. n=3, s=6, is three six sided die
    */
   proc nds(n:int, s:int) {
     var roll: [1..n] int;
     for d in 1..n do roll[d] = randInt(a=1, b=s);
     return + reduce roll;
   }

}
