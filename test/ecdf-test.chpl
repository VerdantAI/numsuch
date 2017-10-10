use NumSuch;

var x = [3,3,1,4];
var ecdf = new ECDF(x);
writeln("Number of observations: ", ecdf.nobs);
var y = [3.0, 55.0, 0.5, 1.5];
var d = ecdf(y);
writeln(d);
