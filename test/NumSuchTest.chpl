use NumSuch,
    Charcoal;


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
