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
    Postgres;

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
  writeln(nm.setRowNames(vn));
} catch {
  writeln("Aww snap");
}

try {
  writeln(nm.setColNames(vn));
} catch {
  writeln("Aww snap");
}


/*
Now test it with Postgres
 */

config const DB_HOST: string = "";
config const DB_USER: string = "";
config const DB_NAME: string = "";
config const DB_PWD: string = "";

if DB_HOST == "" {
   var msg = """
 Cannot find the file 'db_creds.txt'.  Please create it in the current directory with the fields

 DB_HOST=
 DB_USER=
 DB_NAME=
 DB_PWD=

 And DO NOT check it into GitHub. (In fact, Git will try to ignore it.)
   """;
   writeln(msg);
   halt();
}

var con = PgConnectionFactory(host=DB_HOST, user=DB_USER, database=DB_NAME, passwd=DB_PWD);
var nm2 = NamedMatrixFromPG(con, edgeTable="r.cho_named_edges", fromField="from_nm", toField="to_nm");
writeln("nm2\n", nm2.X);
for ij in nm2.X.domain {
  writeln("ij: ", ij, "\tfrom: ", nm2.rows.get(ij(1)), "\tto: ", nm2.cols.get(ij(2)));
}
for c in nm2.rows.entries() {
  writeln("rows k: ", c(1), "\tv: ", c(2)
  ,"\tGet(string): ", nm2.rows.get(c(1))
  ,"\tGet(int): ", nm2.rows.get(c(2)));
}

for c in nm2.cols.entries() {
  writeln("cols k: ", c(1), "\tv: ", c(2)
  ,"\tGet(string): ", nm2.cols.get(c(1))
  ,"\tGet(int): ", nm2.cols.get(c(2)));
}

writeln("nm2.get(1,6): ", nm2.get(1,6));
writeln("nm2.get('star lord', 'gamora'): ", nm2.get("star lord", "gamora"));
writeln("nm2.set(1,6) -> 3.14: ", nm2.set(1,6, 3.14));
writeln("nm2.get(1,6): ", nm2.get(1,6));
writeln("nm2.set('star lord', 'gamora') -> 2.71: ", nm2.set("star lord", "gamora", 2.71));
writeln("nm2.set(2,5) -> 71.97: ", nm2.set(2,5, 71.97));
writeln("nm2.get(2,5): ", nm2.get(2,5));
writeln("nm2.get('gamora', 'nebula'): ", nm2.get("gamora", "nebula"));
writeln("nm2.set('yondu', 'groot') -> 13.11: ", nm2.set("yondu", "groot", 13.11));
writeln("nm2.get('yondu', 'groot'): ", nm2.get("yondu", "groot"));
