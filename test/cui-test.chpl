use NumSuch,
    Postgres,
    Time;

// PERFORMANCE BENCHMARKS FOR MATRIX DB INTERACTIONS

// RESULTS ARE AT THE BOTTOM OF THE FILE IN A MULTILINE COMMENT




config const DB_HOST: string = "";
config const DB_USER: string = "";
config const DB_NAME: string = "";
config const DB_PWD: string = "";

if DB_HOST == "" { var msg =
  """
Cannot find the file 'db_creds.txt'. Please create it in the current directory with the fields

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

var nameTable = "r.cui_confabulation",
    idField = "ftr_id",
    nameField = "source_str",
    edgeTable1 = "r.cui_confabulation",
    fromField1 = "source_cui",
    toField1 = "exhibited_cui",
    wField1 = "NONE",
    wTable = "cc_weight",
    n = 8;




//var X = NamedMatrixFromPG();
var t: Timer;
t.start();
var X = NamedMatrixFromPG(con, edgeTable = edgeTable1, fromField = fromField1, toField = toField1); //X.fromPG(con, edgeTable = edgeTable1, fromField = fromField1, toField = toField1);
t.stop();
writeln("Time to load NamedMatrix of CUIs: %n".format(t.elapsed()));
//writeln(X.domain);
