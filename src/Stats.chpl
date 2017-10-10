module Stats {
  use Sort;
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
}
