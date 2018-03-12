/*
DROP TABLE IF EXISTS r.cho_named_edges;
CREATE TABLE r.cho_named_edges
(
 from_nm text
, to_nm text
);
INSERT INTO r.cho_named_edges (from_nm, to_nm) VALUES
  ('star lord', 'gamora') , ('star lord', 'groot')
, ('star lord', 'drax') , ('gamora', 'drax')
, ('groot', 'drax') , ('drax', 'rocket')
, ('rocket', 'mantis') , ('mantis', 'yondu')
, ('mantis', 'nebula') , ('yondu', 'nebula')
;

 */
use NumSuch,
    Postgres,
    Assert;

var nv: int = 8,
    D: domain(2) = {1..nv, 1..nv},
    SD: sparse subdomain(D),
    X: [SD] real;

var vn: [1..0] string;
vn.push_back("star lord");
vn.push_back("gamora");
vn.push_back("groot");
vn.push_back("drax");
vn.push_back("rocket");
vn.push_back("mantis");
vn.push_back("yondu");

SD += (1,2); X[1,2] = 1;
SD += (1,3); X[1,3] = 1;
SD += (1,4); X[1,4] = 1;
SD += (2,2); X[2,2] = 1;
SD += (2,4); X[2,4] = 1;
SD += (3,4); X[3,4] = 1;
SD += (4,5); X[4,5] = 1;
SD += (5,6); X[5,6] = 1;
SD += (6,7); X[6,7] = 1;
SD += (6,8); X[6,8] = 1;
SD += (7,8); X[7,8] = 1;

var nm = new NamedMatrix(X=X);

/* Should Error out, too few names */
try {
  nm.setRowNames(vn);
} catch {
  writeln("throwing to second!");
}

try {
  vn.push_back("nebula");
} catch {
  writeln("Could not set row names");
}

try {
} catch {
  writeln("Could not set column nmaes");
}
