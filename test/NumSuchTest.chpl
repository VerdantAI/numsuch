use NumSuch;

class UnitTest {

  var s: int,   // Number of passing tests
      f: int,   // Number of failing tests
      t: int,   // Number of tests total
      results: [1..0] TestResult;

  proc init() {
    this.s = 0;
    this.f = 0;
  }

  proc report() {
    for r in this.results {
      writeln(" ** TEST: ", r.passed , " ... ", r.msg);
      if r.passed {
        this.s += 1;
      } else {
        this.f += 1;
      }
    }
    writeln("    Passing: ", this.s, "\tFailing: ", f);
  }

  proc run() {return 0;}

  proc assertArrayEquals(msg: string, expected: []?, actual: []?) : TestResult {
    return new TestArrayResult(msg=msg, passed=actual.equals(expected), expected, actual);
  }
}

class TestResult {
    var passed: bool = false,
        msg: string;

    proc init() {
      super.init();
      this.initDone();
    }

    /*
    proc init(passed:bool) {
      super.init();
      this.initDone();
      this.passed = passed;
    } */

    proc init(msg: string, passed:bool) {
      super.init();
      this.initDone();
    }
}

class TestArrayResult : TestResult {
  proc init(msg: string, passed: bool, expected: [] real, actual: [] real) {
    super.init();
    this.initDone();
    this.msg = msg;
    this.passed=passed;
  }

}

class NumSuchTest : UnitTest {
  proc init() {
    super.init();
    this.initDone();
  }

  proc testIndexSort() : TestResult {
    var r = new TestResult();
    var p: bool = true;
    const Arr = [7, 10, 23, 1];
    const Idx = [2.2, 3.3, 1.1, 4.4];

    var a: [1..4] real = for x in indexSort(arr=Arr, idx=Idx) do x;
    var expected: [1..4] real = [23, 7, 10, 1];
    this.results.push_back(assertArrayEquals(msg="IndexSort", expected=expected, actual=a));

    var b: [1..4] real = for x in indexSort(arr=Arr, idx=Idx, reverse=true) do x;
    var e: [1..4] real = [1, 10, 7, 23];
    this.results.push_back(assertArrayEquals(msg="IndexSort reversed", expected=e, actual=b));
    return r;
  }

  proc run() {
    testIndexSort();
    return 0;
  }

}

proc main(args: [] string) : int {
  var t = new NumSuchTest();
  var ret = t.run();
  t.report();
  return ret;
}
