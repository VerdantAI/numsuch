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
      rows: BiMap = new BiMap(),
      cols: BiMap = new BiMap();

   proc init() {
     this.initDone(); // NAMEDMATRIX DOESNT EXPLICITLY INHERIT ANYTHING SO IS THIS NECESSARY??
   }

   proc init(X) {
     this.D = {X.domain.dim(1), X.domain.dim(2)};
     this.initDone();
     this.loadX(X);
   }

   proc init(X, names: [] string) {
     this.init(X);
     try! this.setRowNames(names);
     try! this.setColNames(names);
   }

   proc init(X, rownames: [] string, colnames: [] string) {
     this.init(X);
     try! this.setRowNames(rownames);
     try! this.setColNames(colnames);
   }

   proc init(N: NamedMatrix) {
     this.init(N.X);
     this.rows = N.rows;
     this.cols = N.cols;
   }
}

/*
Loads the data from X into the internal array, also called X.  We call them all X to keep it clear.

:arg real[]: Array representing the matrix
 */
proc NamedMatrix.loadX(X:[], shape: 2*int =(-1,-1)) {
  if shape(1) > 0 && shape(2) > 0 {
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
    this.rows.add(rn[i]);
  }
  return this.rows;
}

/*
Sets the column names for the matrix X
*/
proc NamedMatrix.setColNames(cn:[]): string throws {
  if cn.size != X.domain.dim(2).size then throw new Error();
  for i in 1..cn.size {
    this.cols.add(cn[i]);
  }
  return this.cols;
}

/*
 Gets the value of the (i,j) entry of the matrix X in the NamedMatrix
 */
proc NamedMatrix.get(i: int, j: int) {
   return this.X(i,j);
 }

 /*
 Get the values using the named rows and columns
  */
proc NamedMatrix.get(f: string, t: string) {
    return this.X(rows.get(f), cols.get(t));
 }

/*
 Set the value of this.X(i,j) by index row
 */
proc NamedMatrix.set(i: int, j: int, w: real) {
    if this.SD.member((i,j)) {
      this.X(i,j) = w;
    } else {
      this.SD += (i,j);
      this.X(i,j) = w;
    }
    return w;
}

/*
Set the values using the row and column names
*/
proc NamedMatrix.set(f: string, t: string, w: real) {
  return this.set(rows.get(f), cols.get(t), w);
}

/*
Update the value in X(i,j) with `w`
 */
proc NamedMatrix.update(i: int, j: int, w: real) {
  const x = this.get(i,j);
  return this.set(i,j, x + w);
}

/*
Update the value in X(i,j) with `w` using the row column names
 */
proc NamedMatrix.update(f: string, t: string, w: real) {
  const x = this.get(rows.get(f),cols.get(t));
  return this.set(rows.get(f),cols.get(t), x + w);
}

/*
Find the number of non-zeroes in the matrix
 */
proc NamedMatrix.nnz() {
  var i: int = 0;
  for ij in this.X.domain {
    i += 1;
  }
  return i;
}

/*
Calculates the sparsity of the matrix: Number of entries / frame size
 */
proc NamedMatrix.sparsity() {
  const d = this.X.shape[1]:real * this.X.shape[2]: real;
  return this.nnz():real / d;
}

/*
 Multiplies the current NamedMatrix `X` against the argument `Y`, but first it aligns
 the names of `X.cols` with `Y.rows`.  Returns an appropriately named NamedMatrix
 :arg NamedMatrix Y:
 */
proc NamedMatrix.alignAndMultiply(Y: NamedMatrix) {
    var rcOverlap: domain(string) = this.cols.keys & Y.rows.keys;

    var xSD: sparse subdomain(this.D) dmapped CS(),
        ySD: sparse subdomain(Y.D) dmapped CS(),
        xX: [xSD] real,  // the actual data
        yX: [ySD] real,  // the actual data
        xrows: BiMap = new BiMap(),
        yrows: BiMap = new BiMap(),
        xcols: BiMap = new BiMap(),
        ycols: BiMap = new BiMap();

    for (left_row, right_col) in zip(this.D.dim(2), Y.D.dim(1)) {
      for rc in rcOverlap {
        const j = this.cols.get(rc);
        if this.SD.member(left_row, j) {
          xSD += (left_row, j);
          xX[left_row, j] = this.X[left_row, j];
        }
        if Y.SD.member(j, right_col) {
          ySD += (j, right_col);
          yX[j, right_col] = Y.X[j, right_col];
        }
      }
    }
    const z = xX.dot(yX);
    var n = new NamedMatrix(X=z);
    n.rows = this.rows;
    n.cols = Y.cols;
    return n;
}



/*
 Creates a NamedMatrix from a table in Postgres.  Does not optimize for square matrices.  This assumption
 is that the matrix is sparse.

 :arg string edgeTable: The SQL table holding the values of the matrix.
 :arg string fromField: The table column representing rows, e.g. `i`.
 :arg string toField: The table column representing columns, e.g. 'j'.
 :arg string wField: `default=NONE` the table column containing the values of cell `(i,j)``
 :arg boolean square: Whether the matrix should be built to have the same rows and columns
 */


 proc NamedMatrixFromPG(con: Connection
   , edgeTable: string
   , fromField: string, toField: string, wField: string = "NONE"
   , square=false) {
  if square {
    return NamedMatrixFromPGSquare(con: Connection
      , edgeTable, fromField, toField, wField);
  } else {
    return NamedMatrixFromPGRectangular(con: Connection
      , edgeTable, fromField, toField, wField);
  }
}

proc NamedMatrixFromPGRectangular(con: Connection
  , edgeTable: string
  , fromField: string, toField: string, wField: string = "NONE") {

  var q = """
  SELECT ftr, t
  FROM (
    SELECT distinct(%s) AS ftr, 'r' AS t FROM %s
    UNION ALL
    SELECT distinct(%s) AS ftr, 'c' AS t FROM %s
  ) AS a
  GROUP BY ftr, t
  ORDER BY ftr, t ;
  """;

  var rows: BiMap = new BiMap(),
      cols: BiMap = new BiMap();

  var cursor = con.cursor();
  cursor.query(q, (fromField, edgeTable, toField, edgeTable));

  for row in cursor {
    if row['t'] == 'r' {
      rows.add(row['ftr']);
    } else if row['t'] == 'c' {
      cols.add(row['ftr']);
    }
  }

  var D: domain(2) = {1..rows.size(), 1..cols.size()},
      SD = CSRDomain(D),
      X: [SD] real;  // the actual data

  var r = """
  SELECT %s, %s
  FROM %s
  ORDER BY %s, %s ;
  """;
  var cursor2 = con.cursor();
  cursor2.query(r, (fromField, toField, edgeTable, fromField, toField));
  const size = cursor2.rowcount(): int;
  var count = 0: int,
      dom = {1..size},
      indices: [dom] (int, int),
      values: [dom] real;

  // This guy is causing problems.  Exterminiate with extreme prejudice
  //forall row in cursor2 {
  forall row in cursor2 with (+ reduce count) {
    count += 1;
    indices[count]=(
       rows.get(row[fromField])
      ,cols.get(row[toField])
      );

    if wField == "NONE" {
      values[count] = 1;
    } else {
      values[count] = row[wField]: real;
    }
  }

  SD.bulkAdd(indices);
  forall (ij, a) in zip(indices, values) {
    X(ij) = a;
  }

  const nm = new NamedMatrix(X=X);
  nm.rows = rows;
  nm.cols = cols;
  return nm;
}

/*
 Build a square version of the matrix.  Still directed, but with the same number of rows/cols
 */
proc NamedMatrixFromPGSquare ( con: Connection
    , edgeTable: string
    , fromField: string, toField: string, wField: string = "NONE") {

    var q = """
    SELECT ftr
    FROM (
      SELECT distinct(%s) AS ftr FROM %s
      UNION ALL
      SELECT distinct(%s) AS ftr FROM %s
    ) AS a
    GROUP BY ftr ORDER BY ftr;
    """;

    var cursor = con.cursor();
    cursor.query(q, (fromField, edgeTable, toField, edgeTable));
    var rows: BiMap = new BiMap();

    forall row in cursor {
    //for row in cursor {
      rows.add(row['ftr']);
    }

    var D: domain(2) = {1..rows.size(), 1..rows.size()},
        SD = CSRDomain(D),
        X: [SD] real;  // the actual data

    var r = """
    SELECT %s, %s
    FROM %s
    ORDER BY %s, %s ;
    """;
    var cursor2 = con.cursor();
    cursor2.query(r, (fromField, toField, edgeTable, fromField, toField));
    var dom1: domain(1) = {1..0},
        dom2: domain(1) = {1..0},
        indices: [dom1] (int, int),
        values: [dom2] real;
    //forall row in cursor2 {
    for row in cursor2 {
      indices.push_back((
         rows.get(row[fromField])
        ,rows.get(row[toField])
        ));

      if wField == "NONE" {
        values.push_back(1);
      } else {
        values.push_back(row[wField]: real);
      }
    }

    SD.bulkAdd(indices);
    forall (ij, a) in zip(indices, values) {
      X(ij) = a;
    }

    const nm = new NamedMatrix(X=X);
    nm.rows = rows;
    nm.cols = rows;
    return nm;
}

proc NamedMatrixFromPG_(con: Connection
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

  var rows: BiMap = new BiMap(),
      cols: BiMap = new BiMap();

  var cursor = con.cursor();
  cursor.query(q, (fromField, edgeTable, toField, edgeTable));
  for row in cursor {
    if row['t'] == 'r' {
      rows.add(row['ftr'], row['ftr_id']:int);
    } else if row['t'] == 'c' {
      cols.add(row['ftr'], row['ftr_id']:int);
    }
  }

  var D: domain(2) = {1..rows.size(), 1..cols.size()},
      SD = CSRDomain(D),
      X: [SD] real;  // the actual data

  var r = """
  SELECT %s, %s
  FROM %s
  ORDER BY %s, %s ;
  """;
  var cursor2 = con.cursor();
  cursor2.query(r, (fromField, toField, edgeTable, fromField, toField));
  var dom1: domain(1) = {1..0},
      dom2: domain(1) = {1..0},
      indices: [dom1] (int, int),
      values: [dom2] real;

  //forall row in cursor2 {
  for row in cursor2 {
//    writeln("row: ", row[fromField], " -> ", row[toField]);
    indices.push_back((
       rows.get(row[fromField])
      ,cols.get(row[toField])
      ));

    if wField == "NONE" {
      values.push_back(1);
    } else {
      values.push_back(row[wField]: real);
    }
  }
  SD.bulkAdd(indices);
  for (ij, a) in zip(indices, values) {
    X(ij) = a;
  }

  const nm = new NamedMatrix(X=X);
  nm.rows = rows;
  nm.cols = cols;
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
    , fromField: string, toField: string, wField: string, weights=false) {
  var q = "SELECT %s, %s FROM %s ORDER BY 1, 2;";
  var source_size_q = """
                      SELECT count(*) AS n FROM (SELECT distinct(s.source_cui) FROM r.cui_confabulation s) AS sources;
                      """;

  var target_size_q = """
                      SELECT count(*) AS n FROM (SELECT distinct(s.exhibited_cui) FROM r.cui_confabulation s) AS exhibited;
                      """;
  var cursor2 = con.cursor();
  var cursor3 = con.cursor();
  cursor2.query(source_size_q);
  cursor3.query(target_size_q);
  const row2 = cursor2.fetchone();
  const row3 = cursor3.fetchone();
  const source_size = row2['n']: int;
  const exhibit_size = row3['n']: int;

  var cursor = con.cursor();
  cursor.query(q,(fromField, toField, edgeTable));
  const size = cursor.rowcount(): int;
  var D: domain(2) = {1..source_size, 1..exhibit_size};
  var SD: sparse subdomain(D) dmapped CS();
  var X: [SD] real;
  var dom: domain(1) = {1..size};
  var indices: [dom] (int, int);
  var values: [dom] real;
  forall (row, i) in zip(cursor, dom) {
    indices[i] = (row[fromField]: int,row[toField]: int);
    values[i] = 1: real;
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

proc sparsity(X) {
  const d = X.shape[1]:real * X.shape[2]: real;
  var i: real = 0.0;
  for ij in X.domain {
    i += 1.0;
  }
  return i / d;
}
