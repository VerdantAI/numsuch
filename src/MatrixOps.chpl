use Cdo,
    LinearAlgebra,
    LinearAlgebra.Sparse,
    NumSuch,
    Random;

config param batchsize = 10000;

/*
 A matrix of data with named rows and columns.
 */
class NamedMatrix {
  var D: domain(2),
      SD = CSRDomain(D),
      X: [SD] real,  // the actual data
      rowNames: domain(string),
      rowIds: [rowNames] int,
      rowNameIndex:[1..0] string,
      colNames: domain(string),
      colIds: [colNames] int,
      colNameIndex:[1..0] string,
      rows: BiMap;

   proc init() {
     super.init();
   }

   proc init(X) {
     this.D = {X.domain.dim(1), X.domain.dim(2)};
     super.init();
     this.loadX(X);
   }

   /*
   proc init(X:[]
     , rowNames: domain(string), rowIds:[] int
     , colNames: domain(string), colIds:[] int) {
     this.D = {X.domain.dim(1), X.domain.dim(2)};
     this.rowNameIndex: [{1..rowNames.size}] int;
     super.init();
     for rown in rowNames {
       this.rowNames += rown;
       this.rowIds[rown] = rowIds[rown];
       //this.rowNameIndex[this.rowIds[rown]] = rown;
     }
     for coln in colNames {
       this.colNames += coln;
       this.colIds[coln] = colIds[coln];
       this.colNameIndex.push_back(coln);
     }
     this.loadX(X);
   }
   */

}

/*
Loads the data from X into the internal array, also called X.  We call them all X to keep it clear.

:arg real[]: Array representing the matrix
 */
proc NamedMatrix.loadX(X:[], shape: 2*int =(-1,-1)) {
  if shape(1) > 0 && shape(2) > 0 {

    writeln("re-shaping D! ", shape);
    this.D = {1..shape(1), 1..shape(2)};
  }
  for (i,j) in X.domain {
    this.SD += (i,j);
    this.X(i,j) = X(i,j);
  }
}


/*
Sets the row names for the matrix X
 */
proc NamedMatrix.setRowNames(rn:[]): string throws {
  if rn.size != X.domain.dim(1).size then throw new Error();
  for i in 1..rn.size {
    this.rowNames += (rn[i]);
    this.rowIds[rn[i]] = this.rowNames.size;
    this.rowNameIndex.push_back(rn[i]);
  }
  return this.rowNames;
}

/*
Sets the column names for the matrix X
 */
proc NamedMatrix.setColNames(cn:[]): string throws {
  if cn.size != X.domain.dim(2).size then throw new Error();
  for i in 1..cn.size {
    this.colNames += (cn[i]);
    this.colIds[cn[i]] = this.colNames.size;
    this.colNameIndex.push_back(cn[i]);
  }
  return this.colNames;
}

/*
 Creates a NamedMatrix from a table in Postgres.  Does not optimize for square matrices.  This assumption
 is that the matrix is sparse.

 :arg string edgeTable: The SQL table holding the values of the matrix.
 :arg string fromField: The table column representing rows, e.g. `i`.
 :arg string toField: The table column representing columns, e.g. 'j'.
 :arg string wField: `default=NONE` the table column containing the values of cell `(i,j)``
 */
proc NamedMatrixFromPG(con: Connection
  , edgeTable: string
  , fromField: string, toField: string, wField: string = "NONE") {

  var q = """
  SELECT ftr, t, row_number() OVER(PARTITION BY t ORDER BY ftr ) AS ftr_id
  FROM (
    SELECT distinct(%s) AS ftr, 'r' AS t FROM %s
    UNION ALL
    SELECT distinct(%s) AS ftr, 'c' AS t FROM %s
  ) AS a
  GROUP BY ftr, t
  ORDER BY ftr_id, t ;
  """;

  var rowNames: domain(string),
      rowIds: [rowNames] int,
      rowNameIndex:[1..0] string,
      colNames: domain(string),
      colIds: [colNames] int,
      colNameIndex:[1..0] string,
      rows: BiMap();

  //var nm = new NamedMatrix();
  var cursor = con.cursor();
  cursor.query(q, (fromField, edgeTable, toField, edgeTable));
  for row in cursor {
    if row['t'] == 'r' {
      /*
      nm.rowNames += row['ftr'];
      nm.rowIds[row['ftr']] = row['ftr_id']:int;
      nm.rowNameIndex.push_back(row['ftr']);
      */
      rowNames += row['ftr'];
      rowIds[row['ftr']] = row['ftr_id']:int;
      rowNameIndex.push_back(row['ftr']);
      rows.add(row['ftr'], row['ftr_id']);
    } else if row['t'] == 'c' {
      /*
      nm.colNames += row['ftr'];
      nm.colIds[row['ftr']] = row['ftr_id']:int;
      nm.colNameIndex.push_back(row['ftr']);
      */
      colNames += row['ftr'];
      colIds[row['ftr']] = row['ftr_id']:int;
      colNameIndex.push_back(row['ftr']);
    }
  }


  var D: domain(2) = {1..max reduce rowIds, 1..max reduce colIds},
      SD = CSRDomain(D),
      X: [SD] real;  // the actual data

  var r = """
  SELECT %s, %s
  FROM %s
  ORDER BY %s, %s ;
  """;
  cursor.query(r, (fromField, toField, edgeTable, fromField, toField));
  var dom1: domain(1) = {1..0},
      dom2: domain(1) = {1..0},
      indices: [dom1] (int, int),
      values: [dom2] real;
  forall row in cursor {
    indices.push_back((
       rowIds[row[fromField]]: int
      ,colIds[row[toField]]: int
      ));
      /*
    indices.push_back((
       rowIds[row[fromField]]: int
      ,colIds[row[toField]]: int));
      */
    if wField == "NONE" {
      values.push_back(1);
    } else {
      values.push_back(row[wField]: real);
    }
  }
  SD.bulkAdd(indices);
  writeln("rowNames: ", rowNames);
  writeln("colNames: ", colNames);
  writeln("this.SD\n", SD);
  forall (ij, a) in zip(indices, values) {
    X(ij) = a;
  }

  const nm = new NamedMatrix();
  /*
  const nm = new NamedMatrix(X=X
    , rowNames = rowNames, rowIds=rowIds
    //rowNameIndex=rowNameIndex,
    , colNames=colNames, colIds=colIds
    //colNameIndex=colNameIndex
    );
  writeln("X.shape: ", X.shape);
    */
  //nm.loadX(X, shape=X.shape);
  /*
  var nm = new NamedMatrix(X=X);
  nm.rowNames = rowNames;
  nm.rowIds = rowIds;
  nm.rowNameIndex = rowNameIndex;
  nm.colNames = colNames;
  nm.colIds = colIds;
  nm.colNameIndex = colNameIndex;
  */

  return nm;
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
      X(ij) = a;
    } else {
      X(ij) = 1;
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
 Build a random sparse matrix.  Good for testing;
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
 proc persistSparseMatrix(con: Connection, aTable: string
   , fromField: string, toField: string, weightField: string
   , X:[?D] real) {
   const q = "INSERT INTO %s (%s, %s, %s) VALUES (%s, %s, %s);";
   var cur = con.cursor();
   var count: int = 0;
   var dom: domain(1, int, false) = {1..0};
   var ts: [dom] (string, string, string, string, int, int, real);
   for ij in X.domain {
     ts.push_back((aTable, fromField, toField, weightField, ij(1), ij(2), X(ij)));
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
proc persistSparseMatrix_(con: Connection, aTable: string
  , fromField: string, toField: string, weightField: string
  , X:[?D] real) {
  const q = "INSERT INTO %s (%s, %s, %s) VALUES (%s, %s, %s);";
  var cur = con.cursor();
  for ij in X.domain {
    const d: domain(1) = {1..0};
    var t: [d] (string, string, string, string, int, int, real);
    t.push_back((aTable, fromField, toField, weightField, ij(1), ij(2), X(ij)));
    cur.execute(q, t);
  }
}


// PARALLEL PERSISTENCE FUNCTION FOR PERFORMANCE COMPARISONS
proc persistSparseMatrix_P(con: Connection, aTable: string
  , fromField: string, toField: string, weightField: string
  , X:[?D] real) {
  const q = "INSERT INTO %s (%s, %s, %s) VALUES (%s, %s, %s);";
  var cur = con.cursor();
  forall ij in X.domain {
    const d: domain(1) = {1..0};
    var t: [d] (string, string, string, string, int, int, real);
    t.push_back((aTable, fromField, toField, weightField, ij(1), ij(2), X(ij)));
    cur.execute(q, t);
  }
}

proc sparsity(X:[]) {
  const d = X.shape[1]:real * X.shape[2]: real;
  var i: real = 0.0;
  for ij in X.domain {
    i += 1.0;
  }
  return i / d;
}
