use NumSuch,
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
    this.results.push_back(assertIntEquals(msg="Number of non-zeroes", 11:int, nm.nnz() ));
    this.results.push_back(assertRealEquals(msg="X.sparsity", 0.171875:real, nm.sparsity() ));
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
    vn.push_back("nebula");
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

  proc run() {
    super.run();
    testIndexSort();
    testNamedMatrix();
    testSetRowNames();
    testSetColNames();
    return 0;
  }

}

proc main(args: [] string) : int {
  var t = new NumSuchTest();
  var ret = t.run();
  t.report();
  return ret;
}
