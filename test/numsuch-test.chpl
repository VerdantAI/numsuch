use NumSuch;

// Test the indexSort function
const Arr = [7, 10, 23, 1];
const Idx = [2.2, 3.3, 1.1, 4.4];
for a in indexSort(arr=Arr, idx=Idx) {
  writeln(a);
}
for a in indexSort(arr=Arr, idx=Idx, reverse=true) {
  writeln(a);
}
