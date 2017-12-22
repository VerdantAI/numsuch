use Cdo,
    LinearAlgebra,
    LinearAlgebra.Sparse;

proc verticesFromPG(con: Connection, edgeTable: string, fromField: string, toField: string, wField: string) {
  return 0;
}

/*
 :arg n: number of distinct vertices.  If none provide, it will look into the table for the max of the feature ids.
 */
proc wFromPG(con: Connection, edgeTable: string
    , fromField: string, toField: string, wField: string, n: int) {
  var q = "SELECT %s, %s, %s FROM %s ORDER BY 1, 2 LIMIT 10;";
  var cursor = con.cursor();
  cursor.query(q,(fromField, toField, wField, edgeTable));
  const D: domain(2) = {1..n, 1..n};
  var SD: sparse subdomain(D) dmapped CS();
  var W: [SD] real;

  for row in cursor {
    SD += (row[fromField]: int, row[toField]:int);
    W[row[fromField]:int, row[toField]:int] = row[wField]: real;
  }
   return W;
}
