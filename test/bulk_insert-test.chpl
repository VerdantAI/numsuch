use NumSuch,
    Postgres;

config const DB_HOST: string = "localhost";
config const DB_USER: string = "postgres";
config const DB_NAME: string = "postgres";
config const DB_PWD: string = "noether";
var con = PgConnectionFactory(host=DB_HOST, user=DB_USER, database=DB_NAME, passwd=DB_PWD);

var nameTable = "cho_names",
    idField = "ftr_id",
    nameField = "name",
    edgeTable = "cho_edges",
    fromField = "fromID",
    toField = "toID",
    wField = "w",
    wTable = "testing3",
    n = 8;

config param batchsize: int = 3;


var X = Matrix(
   [1.0,0.0,1.0,0.0],
   [1.0,0.0,1.0,1.0]);


writeln(X);
writeln("Something is a foot");
writeln(X.domain);
writeln(batchsize);
//writeln(bulkInsertFromArray().type)


//persistSparseMatrix(con, aTable=wTable, fromField=fromField, toField=toField, weightField=wField, A=X);
bulkInsertMatrix(con, aTable=wTable, fromField=fromField, toField=toField, weightField=wField, A=X);
