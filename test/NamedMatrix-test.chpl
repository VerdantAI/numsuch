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

var nm2 = new NamedMatrix();
nm2.fromPG(con, edgeTable="r.cui_confabulation", fromField="source_cui", toField="exhibited_cui");
