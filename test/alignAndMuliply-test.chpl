use NumSuch,
    Postgres,
    Assert;

var D: domain(2) = {1..7, 1..7},
    D2: domain(2) = {1..7, 1..6},
    SD: sparse subdomain(D),
    SD2: sparse subdomain(D2),
    X: [SD] real,
    Y: [SD2] real;

SD += (1,1); X[1,1] = 1;
SD += (1,2); X[1,2] = 1;
SD += (1,3); X[1,3] = 1;
SD += (2,1); X[2,1] = 1;
SD += (2,3); X[2,3] = 1;
SD += (3,3); X[3,3] = 1;
SD += (4,4); X[4,4] = 1;
SD += (5,5); X[5,5] = 1;
SD += (6,6); X[6,6] = 1;
SD += (6,7); X[6,7] = 1;
SD += (7,7); X[7,7] = 1;

SD2 += (1,1); Y[1,1] = 1;
SD2 += (1,2); Y[1,2] = 1;
SD2 += (1,3); Y[1,3] = 1;
SD2 += (2,1); Y[2,1] = 1;
SD2 += (2,3); Y[2,3] = 1;
SD2 += (3,3); Y[3,3] = 1;
SD2 += (4,4); Y[4,4] = 1;
SD2 += (5,5); Y[5,5] = 1;
SD2 += (6,6); Y[6,6] = 1;
//SD2 += (6,7); Y[6,7] = 1;
//SD2 += (7,7); Y[7,7] = 1;


var nm = new NamedMatrix(X=X),
    ml = new NamedMatrix(X=Y);
nm.setRowNames(["star lord", "gamora", "groot", "drax", "rocket", "mantis", "yondu"]);
nm.setColNames(["gamora", "groot", "drax", "rocket", "mantis", "yondu", "nebula"]);

ml.setRowNames(["star lord", "gamora", "groot", "drax", "rocket", "mantis", "yondu"]);
//ml.setColNames(["gamora", "groot", "drax", "rocket", "mantis", "yondu", "nebula"]);
ml.setColNames(["groot", "drax", "rocket", "mantis", "yondu", "nebula"]);

var z = nm.alignAndMultiply(ml);
assert(z.nnz() == 10, "Z has ", z.nnz(), " non-zeroes, expected 10");
