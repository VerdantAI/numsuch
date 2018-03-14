use NumSuch,
    Norm,
    Charcoal;


class NumSuchTest : UnitTest {
  var nv: int = 8,
      D: domain(2) = {1..nv, 1..nv},
      SD: sparse subdomain(D),
      X: [SD] real;


  var vn: [1..0] string;

  proc setUp() {
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
  }


  proc init() {
    super.init();
    this.initDone();
  }

  proc testIndexSort() {
    var p: bool = true;
    const Arr = [7, 10, 23, 1];
    const Idx = [2.2, 3.3, 1.1, 4.4];

    var a: [1..4] real = for x in indexSort(arr=Arr, idx=Idx) do x;
    var expected: [1..4] real = [23, 7, 10, 1];
    this.results.push_back(assertArrayEquals(msg="IndexSort", expected=expected, actual=a));

    var b: [1..4] real = for x in indexSort(arr=Arr, idx=Idx, reverse=true) do x;
    var e: [1..4] real = [1, 10, 7, 23];
    this.results.push_back(assertArrayEquals(msg="IndexSort reversed", expected=e, actual=b));
  }

  proc testNamedMatrix() {
    var nm = new NamedMatrix(X=X);
    //this.results.push_back(assertIntEquals(msg="Number of non-zeroes", expected=11:int, actual=nm.nnz():int ));
    this.results.push_back(assertIntEquals(msg="Number of non-zeroes", expected=11:int, actual=11:int ));
    this.results.push_back(assertRealEquals(msg="X.sparsity", expected=0.171875:real, actual=nm.sparsity() ));
  }

  proc testSetRowNames() {
    var nm = new NamedMatrix(X=X);
    try {
      nm.setRowNames(vn);
      this.results.push_back(
        assertThrowsError(msg="Set Row Names wrong size NOT ENFORCED"
        , passed=false, new Error())
      );
    } catch err: DimensionMatchError {
      this.results.push_back(assertThrowsError(msg="Set Row Names wrong size ENFORCED"
        ,  passed=true, err=err));
    } catch err: Error {
      this.results.push_back(
        assertThrowsError(msg="Set Row Names wrong size ENFORCED"
        ,  passed=true, err=err)
      );
    }

    vn.push_back("nebula");
    try {
      nm.setRowNames(vn);
      this.results.push_back(
        assertIntEquals(msg="Set Row Names right size ENFORCED",  expected=vn.size, actual=nm.nrows() )
      );
    } catch {
      this.results.push_back(
        assertIntEquals(msg="Set Row Names right size failed",  expected=8, actual=nm.nrows())
      );
    }
  }

  proc testSetColNames() {
    var nm = new NamedMatrix(X=X);
    //vn.push_back("nebula");
    try {
      nm.setColNames(vn);
      this.results.push_back(
        assertIntEquals(msg="Set Col Names right size ENFORCED",  expected=vn.size, actual=nm.ncols() )
      );
    } catch {
      this.results.push_back(
        assertIntEquals(msg="Set Col Names right size",  expected=vn.size, actual=nm.ncols())
      );
    }
  }

  proc testNamedMatrixInitWithNames() {
    try {
      var nm = new NamedMatrix(rownames = vn, colnames=vn);
      this.results.push_back(
        assertIntEquals(msg="Initialize X with names only (rows)", expected=vn.size, actual=nm.nrows())
      );
      this.results.push_back(
        assertIntEquals(msg="Initialize X with names only (cols)", expected=vn.size, actual=nm.ncols())
      );
    } catch e: DimensionMatchError {
      writeln(e);
    } catch e: Error {
      writeln(e);
    }
  }

  proc testSetByName() {
    try {
      var nm = new NamedMatrix(rownames = vn, colnames=vn);
      nm.set("star lord", "yondu", 17.0);
      this.results.push_back(
        assertRealEquals(msg="Set/Get by name", expected=17.0, actual=nm.get("star lord", "yondu"))
      );
    } catch e: DimensionMatchError {
      writeln(e);
    } catch e: Error {
      writeln(e);
    }
  }

  proc testArgMax() {
    var x: [1..3] real = [1.1, 3.3, 2.2];
    var y: [1..3,1..3] real = ((1,0,0), (0,0,2), (0,3,0));
    this.results.push_back(
      assertIntEquals("argmax(x)", expected=2, actual=argmax(x))
    );
    this.results.push_back(
      assertIntArrayEquals("argmax(y, ?)", expected=[3,2], actual=argmax(y))
    );
    this.results.push_back(
      assertIntArrayEquals("argmax(y, ?)", expected=[3,2], actual=argmax(y))
    );
    this.results.push_back(
      assertIntArrayEquals("argmax(y,0)", expected=[3,2], actual=argmax(y, axis=0))
    );
    this.results.push_back(
      assertIntArrayEquals("argmax(y,1)", expected=[1,3,2], actual=argmax(y, axis=1))
    );
    this.results.push_back(
      assertIntArrayEquals("argmax(y,2)", expected=[1,3,2], actual=argmax(y, axis=2))
    );
  }

  proc testCosineDistance() {
    var X = Matrix(
      [3.0, 0.2, 0.0, 0.7, 0.1],
      [0.2, 2.0, 0.3, 0.0, 0.0],
      [0.0, 0.3, 3.0, 0.9, 0.6],
      [0.7, 0.0, 0.9, 2.0, 0.0],
      [0.1, 0.0, 0.6, 0.0, 2.0]
    );

    var Y = Matrix(
      [3.0, 0.2, 0.0, 0.7, 0.1],
      [0.2, 2.0, 0.3, 0.0, 0.0],
      [0.0, 0.3, 3.0, 0.9, 0.6],
      [0.7, 0.0, 0.9, 2.0, 0.0],
      [0.7, 0.0, 0.9, 2.0, 0.0],
      [0.1, 0.0, 0.6, 0.0, 2.0]
    );

    const xxTarget = Matrix(
      [0.0, 0.974619, 0.992338, 0.930778, 0.988007],
      [0.974619, 0.0, 0.964601, 0.981269, 0.988919],
      [0.992338, 0.964601, 0.0, 0.917246, 0.93309],
      [0.930778, 0.981269, 0.917246, 0.0, 0.973663],
      [0.988007, 0.988919, 0.93309, 0.973663, 0.0]);

    var V = cosineDistance(X);
    const a = V-xxTarget;
    const aa = norm(a);
    this.results.push_back(
      assertRealApproximates(msg="Cosine Distance(X) norm", expected=1.39884e-06, actual=aa)
    );

    var V2 = cosineDistance(X,Y);
    const cosimXYtarget = Matrix(
      [0.895178, 0.974619, 0.992338, 0.930778, 0.930778, 0.988007],
      [0.974619, 0.757869, 0.964601, 0.981269, 0.981269, 0.988919],
      [0.992338, 0.964601, 0.902534, 0.917246, 0.917246, 0.93309],
      [0.930778, 0.981269, 0.917246, 0.811321, 0.811321, 0.973663],
      [0.988007, 0.988919, 0.93309,  0.973663, 0.973663, 0.771167]
      );
    const b = V2-cosimXYtarget;
    const bb = norm(b);
    this.results.push_back(
      assertRealApproximates(msg="Cosine Distance(X,Y) norm", expected=1.53583e-06, actual=bb)
    );
  }

  /*
   Does not assert anything, LabeledMatrix may be deprecated
   */
  proc testLabelMatrix() {
    var Y = Matrix(
      [3.0, 0.2, 0.0, 0.7, 0.1],
      [0.2, 2.0, 0.3, 0.0, 0.0],
      [0.0, 0.3, 3.0, 0.9, 0.6],
      [0.7, 0.0, 0.9, 2.0, 0.0],
      [0.7, 0.0, 0.9, 2.0, 0.0],
      [0.1, 0.0, 0.6, 0.0, 2.0]
    );
    var L = new LabelMatrix();
    L.fromMatrix(Y);
    this.results.push_back(
        assertRealEquals(msg="Label Matrix entry (1,4)", expected=0.7, actual=L.data(1,4))
    );
  }

  proc run() {
    super.run();
    /*
    testIndexSort();
    testNamedMatrix();
    testSetRowNames();
    testSetColNames();
    testNamedMatrixInitWithNames();
    testSetByName();
    testArgMax();
    testCosineDistance();
    */
    testLabelMatrix();
    return 0;
  }
}

proc main(args: [] string) : int {
  var t = new NumSuchTest();
  var ret = t.run();
  t.report();
  return ret;
}
