use LinearAlgebra,
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

   proc init(rownames: [] string, colnames: [] string) {
     this.D = {1..rownames.size, 1..colnames.size};
     this.initDone();
     try! this.setRowNames(rownames);
     try! this.setColNames(colnames);
   }

   proc init(N: NamedMatrix) {
     this.init(N.X);
     this.rows = N.rows;
     this.cols = N.cols;
   }

   proc init(X, rows: BiMap, cols: BiMap) {
     this.init(X);
     this.rows = rows;
     this.cols = cols;
   }
}


/*
Returns the number of rows in the matrix frame
 */
proc NamedMatrix.nrows() {
  return X.domain.dim(1).size;
}

/*
Returns the number of columns in the matrix frame
 */
proc NamedMatrix.ncols() {
  return X.domain.dim(2).size;
}

/*
 Finds the max along the row indicated by row number
 */

proc NamedMatrix.rowMax(i: int) {
  return aMax(this.X, 1)[i];
}

proc NamedMatrix.rowMax() {
  return aMax(this.X, 1);
}

proc NamedMatrix.colMax(i: int) {
  return aMax(this.X, 2)[i];

}

proc NamedMatrix.colMax() {
  return aMax(this.X, 2);
}

proc NamedMatrix.rowArgMax(i) {
  return argMax(this.X, 1)[i];
}

proc NamedMatrix.rowArgMax() {
  return argMax(this.X, 1);
}

proc NamedMatrix.colArgMax(i) {
  return argMax(this.X, 2)[i];
}

proc NamedMatrix.colArgMax() {
  return argMax(this.X, 2);
}




proc NamedMatrix.rowMin(i: int) {
  return aMin(this.X, 1)[i];
}

proc NamedMatrix.rowMin() {
  return aMin(this.X, 1);
}

proc NamedMatrix.colMin(i: int) {
  return aMin(this.X, 2)[i];
}

proc NamedMatrix.colMin() {
  return aMin(this.X, 2);
}

proc NamedMatrix.rowArgMin(i) {
  return argMin(this.X, 1)[i];
}

proc NamedMatrix.rowArgMin() {
  return argMin(this.X, 1);
}

proc NamedMatrix.colArgMin(i) {
  return argMin(this.X, 2)[i];
}

proc NamedMatrix.colArgMin() {
  return argMin(this.X, 2);
}


//proc NamedMatrix.argRowMax()


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
  //if (X.domain.dim(1).size > 0) && (rn.size != X.domain.dim(1).size) {
  //if (1 > 0) && (rn.size != X.domain.dim(1).size) {
  if rn.size != X.domain.dim(1).size {
    const err = new DimensionMatchError(expected = X.domain.dim(1).size, actual=rn.size);
    throw err;
    return "";
  } else {
    for i in 1..rn.size {
      this.rows.add(rn[i]);
    }
    return this.rows;
  }
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

proc NamedMatrix.ndot(N: NamedMatrix) {
  var C: NamedMatrix = new NamedMatrix(X = dot(this.X,N.X), this.rows, N.cols);
  return C;
}




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

proc aMax(X:[], axis = 0) {
  var is: domain(1) = 1..max(X.domain.dim(1).size,X.domain.dim(2).size);
  var sis: sparse subdomain(is);
  var maxima: [sis] real;
  if axis == 0 {
    var wDom: domain(1) = 1..X.domain.size;
    var ws = reshape(X, wDom);
    sis += 1;
    maxima[1] = (max reduce ws);
  }
  if axis == 2 {
    is = X.domain.dim(1);
    for i in is {
      var wDom: domain(1);
      var ws: [wDom] real;
      for a in transpose(X).domain.dimIter(2, i) {
        sis += i;
        ws.push_back(X(a,i));
      }
      if sis.member(i) {
        maxima[i] = max reduce ws;
      }
    }
  } else if axis == 1 {
    is = X.domain.dim(2);
    for i in is {
      var wDom: domain(1);
      var ws: [wDom] real;
      for a in X.domain.dimIter(2, i) {
        sis += i;
        ws.push_back(X(i,a));
      }
      if sis.member(i) {
        maxima[i] = max reduce ws;
      }
    }
  }
  return maxima;
}

proc aMin(X:[], axis: int) {
  var is: domain(1) = 1..max(X.domain.dim(1).size,X.domain.dim(2).size);
  var sis: sparse subdomain(is);
  var minima: [sis] real;
  if axis == 0 {
    var wDom: domain(1) = 1..X.domain.size;
    var ws = reshape(X, wDom);
    sis += 1;
    minima[1] = (min reduce ws);
  }
  if axis == 2 {
    is = X.domain.dim(1);
    for i in is {
      var wDom: domain(1);
      var ws: [wDom] real;
      for a in transpose(X).domain.dimIter(2, i) {
        sis += i;
        ws.push_back(X(a,i));
      }
      if sis.member(i) {
        minima[i] = min reduce ws;
      }
    }
  } else if axis == 1 {
    is = X.domain.dim(2);
    for i in is {
      var wDom: domain(1);
      var ws: [wDom] real;
      for a in X.domain.dimIter(2, i) {
        sis += i;
        ws.push_back(X(i,a));
      }
      if sis.member(i) {
        minima[i] = min reduce ws;
      }
    }
  }
  return minima;
}


proc argMin(X:[], axis: int) {
  var is: domain(1) = 1..max(X.domain.dim(1).size,X.domain.dim(2).size);
  var sis: sparse subdomain(is);
  var minima: [sis] 2*int;
  if axis == 0 {
    sis += 1;
    minima[1] = miniLoc_(axis == 0, id = 1, X);
  } else if axis == 2 {
    for i in is {
      var idm = miniLoc_(1,i,X);
      if idm != (0,0) {
        sis += i;
        minima[i] = idm;
      }
    }
  } else if axis == 1 {
    for i in is {
      var idm = miniLoc_(2,i,X);
      if idm != (0,0) {
        sis += i;
        minima[i] = idm;
      }
    }
  }
  return minima;
}

proc argMax(X:[], axis: int) {
  var is: domain(1) = 1..max(X.domain.dim(1).size,X.domain.dim(2).size);
  var sis: sparse subdomain(is);
  var maxima: [sis] 2*int;
  if axis == 0 {
    sis += 1;
    maxima[1] = maxiLoc_(axis == 0, id = 1, X);
  } else if axis == 2 {
    for i in is {
      var idm = maxiLoc_(1,i,X);
      if idm != (0,0) {
        sis += i;
        maxima[i] = idm;
      }
    }
  } else if axis == 1 {
    for i in is {
      var idm = maxiLoc_(2,i,X);
      if idm != (0,0) {
        sis += i;
        maxima[i] = idm;
      }
    }
  }
  return maxima;
}


// HELPER FUNCTIONS SHOULD NOT BE EXPOSED TO USER
proc miniLoc_(axis:int, id, X:[]) {
  var idm: (int,int),
      minimum: real = 1000000;
  if axis == 0 {
    for (i,j) in X.domain {
      if X(i,j) < minimum {
        minimum = X(i,j);
        idm = (i,j);
      }
    }
  }
  if axis == 1 {
    for a in transpose(X).domain.dimIter(2, id) {
      if X(a,id) < minimum {
        minimum = X(a,id);
        idm = (a,id);
      }
    }
  }
  if axis == 2 {
    for a in X.domain.dimIter(2, id) {
      if X(id,a) < minimum {
        minimum = X(id,a);
        idm = (id,a);
      }
    }
  }
  return idm;
}

proc maxiLoc_(axis:int, id, X:[]) {
  var idm: (int,int),
      maximum: real;
  if axis == 0 {
    for (i,j) in X.domain {
      if X(i,j) > maximum {
        maximum = X(i,j);
        idm = (i,j);
      }
    }
  }
  if axis == 1 {
    for a in transpose(X).domain.dimIter(2, id) {
      if X(a,id) > maximum {
        maximum = X(a,id);
        idm = (a,id);
      }
    }
  }
  if axis == 2 {
    for a in X.domain.dimIter(2, id) {
      if X(id,a) > maximum {
        maximum = X(id,a);
        idm = (id,a);
      }
    }
  }
  return idm;
}



proc tropic(A:[],B:[]) { // UNDER CONSTRUCTION
  writeln("Calculating Tropic Product");
  writeln("A is");
  writeln(A);
  writeln("With domain");
  writeln(A.domain);
  var dom: domain(2) = {A.domain.dim(1),B.domain.dim(2)};
  var sps = CSRDomain(dom);
  var BT = transpose(B);
  writeln("BT is");
  writeln(BT);
  writeln("With domain");
  writeln(BT.domain);
  writeln("Tropic will have entries in");
  writeln(dom);
  var T: [sps] real;
  for (i,j) in dom {
    var mini = 100000000: real;
    var wdom: domain(1);
    var wids: [wdom] int;
    for w in A.domain.dimIter(2,i) {
      wids.push_back(w);
      writeln("Witness in A from %n to %n".format(i,w));
    }
    writeln(wids);
    for w in BT.domain.dimIter(2,j) {
      wids.push_back(w);
      writeln("Witness in B from %n to %n".format(w,j));
    }
    writeln(wids);
    var wDom: domain(1);
    var witness: [wDom] real;
    for w in wids {
      if A(i,w) + BT(j,w) > 0 {
        witness.push_back(A(i,w) + BT(j,w));
      }
    }
    writeln("Witnesses are");
    writeln(witness);
    mini = min reduce witness;
    writeln("Minimum among witnesses is");
    writeln(mini);
    if mini < 1000000000 {
      T(i,j) = mini;
    }
  }
  return T;
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


proc sparsity(X) {
  const d = X.shape[1]:real * X.shape[2]: real;
  var i: real = 0.0;
  for ij in X.domain {
    i += 1.0;
  }
  return i / d;
}

class NumSuchError : Error {
  proc init() {
    super.init();
    this.initDone();
  }
  proc message() {
    return "Generic NumSuch Error";
  }
}

class DimensionMatchError : NumSuchError {
  var expected: int,
      actual: int;

  proc init(expected: int, actual:int) {
    super.init();
    this.initDone();
    this.expected = expected;
    this.actual = actual;
  }

  proc message() {
    return "Error matching dimensions.  Expected: " + this.expected + " Actual: " + this.actual;
  }
}
