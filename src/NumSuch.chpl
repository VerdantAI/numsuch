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


  /*
  Class to hold a <string, int> bimap.  This class does NOT enforce uniqueness but
  will skip duplicate keys.
   */
  class BiMap {
    var keys: domain(string),
        ids:  [keys] int,
        idxkey: domain(int),
        idx: [idxkey] string;

    /*
    Create an empty BiMap.
    */
    proc init() {
      super.init();
    }

    /*
      Add string key, gives it the id based on when it entered.

      :arg k string: The string <e.g. key> to add to the BiMap
     */
    proc add(k:string) {
      if !this.keys.member(k) {
        this.keys += k;
        var i = this.keys.size;
        if i == 0 then i = 1;
        this.ids[k] = i;
        this.idxkey += i;
        this.idx[i] = k;
      }
    }

    /*
    Add a key with a given ID.  Must be done in serial.  But it begs the question: Do I need
    to have the feature ids if they have to be done in serial?
     */
    proc add(k:string, v:int) {
      this.keys += k;
      this.ids[k] = v;
      this.idxkey += v;
      this.idx[v] = k;
    }

    /*
    Send in a string, get an integer back.
     */
    proc get(k:string) {
      return this.ids[k];
    }

    /*
    Put in an integer, return a string
     */
    proc get(v:int) {
      return this.idx[v];
    }

    /*
     Iterator return tuples of (key, value)
     */
    iter entries() {
      for k in this.keys {
        yield (k, this.ids[k]);
      }
    }

    /*
    How many entries?
     */
    proc size() {
      return this.keys.size;
    }

    /*
    Returns the max value for "value", assuming it's a real number
    */
    proc max() {
      return max reduce this.idxkey;
    }
  }

}
