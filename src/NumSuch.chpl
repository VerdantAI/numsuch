/*
 View NumSuch `on Github <https://github.com/buddha314/numsuch>`_

 In NumSuch, matrices are considered sparse until proven otherwise.

 */
module NumSuch{
  use LinearAlgebra,
      Core,
      PeelPropagation,
      MatrixOps,
      Stats;

  /*
  Sort an array ``arr`` according to the values in the array ``idx``

  :arg arr: The array to be sorted
  :arg idx: The indexing array
  :arg reverse: Boolean indicating whether ``idx`` should be considered in reverse order. Default is ``false``

  :returns: An iterator producing elements of ``arr`` sorted by values in ``idx``

examples::

  const Arr = [7, 10, 23, 1];
  const Idx = [2.2, 3.3, 1.1, 4.4];

  for a in indexSort(arr=Arr, idx=Idx) {
    writeln(a);
  }
  > 23
  > 7
  > 10
  > 1

  for a in indexSort(arr=Arr, idx=Idx, reverse=true) {
    writeln(a);
  }

  > 1
  > 10
  > 7
  > 23

  */
  iter indexSort(arr, idx, reverse=false) {
    const AB = [ab in zip(idx, arr)] ab;
    if !reverse {
      for ab in AB.sorted() {
        yield ab[2];
      }
    } else {
      for ab in AB.sorted(comparator=reverseComparator) {
        yield ab[2];
      }
    }
  }

}
