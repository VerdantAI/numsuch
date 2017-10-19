use NumSuch;
var nv: int = 8,
    D: domain(2) = {1..nv, 1..nv},
    SD: sparse subdomain(D) dmapped CS(),
    A: [SD] real;

SD += (1,2); A[1,2] = 1;
SD += (1,3); A[1,3] = 1;
SD += (1,4); A[1,4] = 1;
SD += (2,4); A[2,4] = 1;
SD += (3,4); A[3,4] = 1;
SD += (4,5); A[4,5] = 1;
SD += (5,6); A[5,6] = 1;
SD += (6,7); A[6,7] = 1;
SD += (6,8); A[6,8] = 1;
SD += (7,8); A[7,8] = 1;

var G = buildFromSparseMatrix(A, weighted=false, directed=false);
var H = buildFromSparseMatrix(A, weighted=false, directed=false, names = ["alice", "bob"]);
var n = ["alice", "bob", "cindy","darren","efram","fanny","gordon", "hiram"];
var I = buildFromSparseMatrix(A, weighted=false, directed=false, names = n);
writeln(I.names(1));
writeln(I.names());
const ssd: domain(int) = {2,5,7};
const (subG, vertMap) = I.subgraph(ssd);
writeln(subG.names());
