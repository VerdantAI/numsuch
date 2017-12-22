use NumSuch,
    Postgres;

config const DB_HOST: string = "localhost";
config const DB_USER: string = "buddha";
config const DB_NAME: string = "buddha";
config const DB_PWD: string = "buddha";
var con = PgConnectionFactory(host=DB_HOST, user=DB_USER, database=DB_NAME, passwd=DB_PWD);

var edgeTable = "r.cho_edges",
    fromField = "from_fid",
    toField = "to_fid",
    wField = "w",
    n = 8;

// Should have loaded the data from test/reference/entropy_base_graph_schema.sql
var W = wFromPG(con=con, edgeTable=edgeTable, fromField, toField, wField, n=n);
writeln(W);

/* completes in about 160 seconds
var W2 = wFromPG(con=con, edgeTable="r.yummly_edges", fromField, toField, wField, n=6714);
*/
