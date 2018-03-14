use NumSuch,
    Time,
    Norm,
    MatrixMarket;

//var labelFile = "data/webkb_labels.txt";
//var vectorFile = "data/webkb_vectors.mtx";

//var L = new LabelMatrix();
//L.readFromFile(fn=labelFile, addDummy=true);

// Cosine Distance test
//var W = mmread(real, vectorFile);
// this takes 5 hours on my laptop, holy cow.

writeln("Running cosineDistance");

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

var t: Timer;
//writeln("cosineDistance(X,X)");
t.start();
var V = cosineDistance(X);
t.stop();
assert(t.elapsed() < 0.002, "cosineDistance took longer than 0.002s: ", t.elapsed());
const xxTarget = Matrix(
  [0.0, 0.974619, 0.992338, 0.930778, 0.988007],
  [0.974619, 0.0, 0.964601, 0.981269, 0.988919],
  [0.992338, 0.964601, 0.0, 0.917246, 0.93309],
  [0.930778, 0.981269, 0.917246, 0.0, 0.973663],
  [0.988007, 0.988919, 0.93309, 0.973663, 0.0]);
const a = V-xxTarget;
const aa = norm(a);
assert(aa < 1.0e-5, "cosineDistance is\n", aa, "\n...expected less than 1.0e-5");

t.start();
var V2 = cosineDistance(X,Y);
t.stop();
assert(t.elapsed() < 0.005, "cosineDistance took longer than 0.005s: ", t.elapsed());
const cosimXYtarget = Matrix(
  [0.895178, 0.974619, 0.992338, 0.930778, 0.930778, 0.988007],
  [0.974619, 0.757869, 0.964601, 0.981269, 0.981269, 0.988919],
  [0.992338, 0.964601, 0.902534, 0.917246, 0.917246, 0.93309],
  [0.930778, 0.981269, 0.917246, 0.811321, 0.811321, 0.973663],
  [0.988007, 0.988919, 0.93309,  0.973663, 0.973663, 0.771167]
  );
const b = V2-cosimXYtarget;
const bb = norm(b);
assert(bb < 1.0e-05, "cosineDistance(X,Y) is ", bb, " expected < 1.0e-05");

// Test LabelMatrix.fromMatrix()
var L = new LabelMatrix();
writeln("Loading L from matrix.");
L.fromMatrix(Y);
writeln(L.data);
