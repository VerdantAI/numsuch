use Cdo,
    LinearAlgebra,
    LinearAlgebra.Sparse,
    Random;

config param batchsize = 10000;

/*
 A matrix of data with named rows and columns.
 */
class NamedMatrix {
  var D: domain(2),
      SD = CSRDomain(D),
      X: [SD] real;  // the actual data

   proc init(X) {
     this.D = {X.domain.dim(1), X.domain.dim(2)};
     super.init();
     this.loadX(X);
   }
}

proc NamedMatrix.loadX(X:[]) {
  for (i,j) in X.domain {
    this.SD += (i,j);
    this.X(i,j) = X(i,j);
  }
}

/*

  :arg con: A CDO Connection to Postgres
  :arg edgeTable: The table in PG of edges
  :arg fromField: The field of edgeTable containing the id of the head vertex
  :arg toField: the field of edgeTable containing the id of the tail vertex
  :arg wField: The field of edgeTable containing the weight of the edge
  :arg n: number of distinct vertices. In practice, this may be gives and the number of names
  :arg weights: Boolean on whether to use the weights in the table or a 1 (indicator)
 */
proc wFromPG(con: Connection, edgeTable: string
    , fromField: string, toField: string, wField: string, n: int, weights=true) {
  var q = "SELECT %s, %s, %s FROM %s ORDER BY 1, 2;";
  var cursor = con.cursor();
  cursor.query(q,(fromField, toField, wField, edgeTable));
  const D: domain(2) = {1..n, 1..n};
  var SD: sparse subdomain(D) dmapped CS();
  var X: [SD] real;
  var dom1: domain(1) = {1..0};
  var dom2: domain(1) = {1..0};
  var indices: [dom1] (int, int);
  var values: [dom2] real;
  forall row in cursor {
    indices.push_back((row[fromField]: int,row[toField]: int));
    values.push_back(row[wField]: real);
  }
  SD.bulkAdd(indices);
  forall (ij, a) in zip(indices, values) {
    if weights {
      WXij) = a;
    } else {
      WXij) = 1;
    }
  }
  return X;
}

//SERIAL EXTRACTION FUNCTION FOR PERFORMANCE COMPARISONS
proc wFromPG_(con: Connection, edgeTable: string
    , fromField: string, toField: string, wField: string, n: int, weights=true) {
  var q = "SELECT %s, %s, %s FROM %s ORDER BY 1, 2;";
  var cursor = con.cursor();
  cursor.query(q,(fromField, toField, wField, edgeTable));
  const D: domain(2) = {1..n, 1..n};
  var SD: sparse subdomain(D) dmapped CS();
  var W: [SD] real;

  for row in cursor {
    SD += (row[fromField]: int, row[toField]:int);
    if weights {
      W[row[fromField]:int, row[toField]:int] = row[wField]: real;
    } else {
      W[row[fromField]:int, row[toField]:int] = 1;
    }
  }
   return W;
}


/*

 :arg con: A connection to a Postgres database containing a table with <ftr_id>, <vertex_name> pairs
 :arg nameTable: The name of the Postgres table containing the pairs
 :arg nameField: The name of the field in the nameTable containing the names
 :arg idField: The name of the field in the nameTable containing the feature ids

 :returns: An array of strings in order of feature id
 */
proc vNamesFromPG(con: Connection, nameTable: string
  , nameField: string, idField: string ) {

  var cursor = con.cursor();
  var q1 = "SELECT max(%s) AS n FROM %s";
  cursor.query(q1, (idField, nameTable));
  var n:int= cursor.fetchone()['n']: int;
  var vertexNames: [1..n] string;

  var q2 = "SELECT %s, %s FROM %s ORDER BY 1";
  cursor.query(q2, (idField, nameField, nameTable));
  for row in cursor {
      vertexNames[row[idField]:int ] = row[nameField];
  }
  return vertexNames;
}


/*
 */

proc generateRandomSparseMatrix(size: int, sparsity: real) {
  const D: domain(2) = {1..size, 1..size};
  var SD: sparse subdomain(D) dmapped CS();
  var R: [SD] real;
  var da: domain(1) = {1..size};
  var array: [da] int = 1..size;
  var dom: domain(1) = {1..0};
  var indices: [dom] 2*int;
  var N = floor(size*(1-sparsity)): int;
  forall i in array {
    forall j in array {
      indices.push_back((i,j));
    }
  }
  shuffle(indices);
  var sparseids = indices[1..N];
  SD.bulkAdd(sparseids);
  forall (i,j) in sparseids {
    R(i,j) = 1;
  }
  //ndices = zip(array1, array2)
  return R;
}


// BATCH PERSISTENCE
 proc persistSparseMatrix(con: Connection, aTable: string, fromField: string, toField: string, weightField: string, A:[?D] real) {
   const q = "INSERT INTO %s (%s, %s, %s) VALUES (%s, %s, %s);";
   var cur = con.cursor();
   var count: int = 0;
   var dom: domain(1, int, false) = {1..0};
   var ts: [dom] (string, string, string, string, int, int, real);
   for ij in A.domain {
     ts.push_back((aTable, fromField, toField, weightField, ij(1), ij(2), A(ij)));
     count += 1;
     if count >= batchsize {
       cur.execute(q, ts);
       count = 0;
       var reset: [dom] (string, string, string, string, int, int, real);
       ts = reset;
     }
   }
   cur.execute(q,ts);
 }

//SERIAL PERSISTANCE FUNCTION FOR PERFORMANCE COMPARISONS
proc persistSparseMatrix_(con: Connection, aTable: string, fromField: string, toField: string, weightField: string, A:[?D] real) {
  const q = "INSERT INTO %s (%s, %s, %s) VALUES (%s, %s, %s);";
  var cur = con.cursor();
  for ij in A.domain {
    const d: domain(1) = {1..0};
    var t: [d] (string, string, string, string, int, int, real);
    t.push_back((aTable, fromField, toField, weightField, ij(1), ij(2), A(ij)));
    cur.execute(q, t);
  }
}


// PARALLEL PERSISTENCE FUNCTION FOR PERFORMANCE COMPARISONS
proc persistSparseMatrix_P(con: Connection, aTable: string, fromField: string, toField: string, weightField: string, A:[?D] real) {
  const q = "INSERT INTO %s (%s, %s, %s) VALUES (%s, %s, %s);";
  var cur = con.cursor();
  forall ij in A.domain {
    const d: domain(1) = {1..0};
    var t: [d] (string, string, string, string, int, int, real);
    t.push_back((aTable, fromField, toField, weightField, ij(1), ij(2), A(ij)));
    cur.execute(q, t);
  }
}
