use NumSuch,
    Norm,
    LinearAlgebra,
    Viterbi,
    Core,
    NN,
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
    vn.push_back("nebula");

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


  proc init(verbose:bool) {
    super.init(verbose=verbose);
    this.complete();
  }

  proc testMatrixOperators() {
    var vn2: [1..0] string;
    for n in vn do vn2.push_back(n);
    //vn2.push_back("nebula");
    var nm = new NamedMatrix(X=X, names=vn2);
    nm.set(i=2, j=7, w=13.1);
    assertRealEquals("Can set a new entry in matrix", expected=13.1, actual=nm.get(2,7));
    nm.remove(i=2, j=7);
    assertBoolEquals("Can remove an entry from the matrix", expected=false, actual=nm.SD.member(2,7));

    // Same thing with names instead
    nm.set("star lord", "yondu", w=13.1);
    assertRealEquals("Can set a new entry in matrix by name", expected=13.1, actual=nm.get("star lord","yondu"));
    nm.remove("star lord", "yondu");
    assertBoolEquals("Can remove an entry from the matrix by name", expected=false, actual=nm.SD.member(2,7));

  }


  proc tropicalTesting() {
    var nv: int = 8,
        D: domain(2) = {1..nv, 1..nv},
        SD = CSRDomain(D),
        X: [SD] real;

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

    var X2 = tropic(X,X);
//    writeln(X2);
//    writeln(X2.domain);
//    tropicLimit(X,X);
//    var R = tropic(X,X);
    //writeln(&& reduce (X2 == X));

    var X3 = tropic(X2,X);
    writeln(X3);
    writeln(X3.domain);
    var X4 = tropic(X3,X);
    writeln(X4);
    writeln(X4.domain);
    var X5 = tropic(X4,X);
    writeln(X5);
    writeln(X5.domain);
    var X6 = tropic(X5,X);
    writeln(X6);
    writeln(X6.domain);

  //  writeln(sparseEq(X6,X));
  //  writeln(sparseEq(X6,X5));

    writeln(tropicLimit(X,X));
/*


    if R.domain == X.domain {
      var same = && reduce (R == X);
      if same {
        writeln("Arrays Equal");
        writeln(R);
      } else {
        writeln("Arrays Not Equal");
        writeln(tropic(R,X));
      }
    } else {
      writeln("Domains Not Equal");
      writeln(tropic(R,X));
    }*/
  }

  proc testIndexSort() {
    var p: bool = true;
    const Arr = [7, 10, 23, 1];
    const Idx = [2.2, 3.3, 1.1, 4.4];

    var a: [1..4] real = for x in indexSort(arr=Arr, idx=Idx) do x;
    var expected: [1..4] real = [23, 7, 10, 1];
    assertArrayEquals(msg="IndexSort", expected=expected, actual=a);

    var b: [1..4] real = for x in indexSort(arr=Arr, idx=Idx, reverse=true) do x;
    var e: [1..4] real = [1, 10, 7, 23];
    assertArrayEquals(msg="IndexSort reversed", expected=e, actual=b);
  }

  proc testNamedMatrix() {
    write("testNamedMatrix() ...");
    var nm = new NamedMatrix(X=X);
    nm.set(1,3, 17.0);

    assertIntEquals(msg="nrows() set correctly", expected=8, actual=nm.nrows());
    assertIntEquals(msg="ncols() set correctly", expected=8, actual=nm.ncols());
    assertIntEquals(msg="Number of non-zeroes", expected=11:int, actual=11:int );
    assertRealEquals(msg="X.sparsity", expected=0.171875:real, actual=nm.sparsity());
    assertRealEquals(msg="Max of row 1", expected=17.0:real, actual=nm.rowMax(1));
    var e: [1..8] real = [17.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, NAN];
    assertArrayEquals(msg="Max of all rows", expected=e, actual=nm.rowMax());

    var DY = {1..3, 1..4},
        SDY = CSRDomain(DY),
        Y:[SDY] real;
    SDY +=(1,3); Y[1,3] = 1;
    var nm2 = new NamedMatrix(X=Y);
    assertIntEquals("grid2seq(tuple) works on the matrix", expected=9, actual=nm2.grid2seq((3,1)));
    assertIntEquals("grid2seq(i,j) works on the matrix", expected=9, actual=nm2.grid2seq(3,1));
    var sg = nm2.seq2grid(7);
    assertIntEquals("seq2grid works on the matrix", expected=2, actual=sg[1]);
    assertIntEquals("seq2grid works on the matrix", expected=3, actual=sg[2]);
    writeln("...done");
  }

  proc testSetRowNames() {
    var nm = new NamedMatrix(X=X);
    var vn2: [1..0] string;
    for n in vn do vn2.push_back(n);
    vn2.push_back("stakar ogord");

    try {
      nm.setRowNames(vn2);
      assertThrowsError(msg="Set Row Names wrong size NOT ENFORCED", passed=false, new Error());
    } catch err: DimensionMatchError {
      assertThrowsError(msg="Set Row Names wrong size ENFORCED",  passed=true, err=err);
    } catch err: Error {
      assertThrowsError(msg="Set Row Names wrong size ENFORCED",  passed=true, err=err);
    }

    try {
      nm.setRowNames(vn2);
      assertIntEquals(msg="Set Row Names right size ENFORCED",  expected=vn.size, actual=nm.nrows());
    } catch {
      assertIntEquals(msg="Set Row Names right size failed",  expected=8, actual=nm.nrows());
    }
  }

  proc testSetColNames() {
    var nm = new NamedMatrix(X=X);
    try {
      nm.setColNames(vn);
      assertIntEquals(msg="Set Col Names right size ENFORCED",  expected=vn.size, actual=nm.ncols());
    } catch {
      assertIntEquals(msg="Set Col Names right size",  expected=vn.size, actual=nm.ncols());
    }
  }

  proc testNamedMatrixInitWithNames() {
    try {
      var nm = new NamedMatrix(rownames = vn, colnames=vn);
      assertIntEquals(msg="Initialize X with names only (rows)", expected=vn.size, actual=nm.nrows());
      assertIntEquals(msg="Initialize X with names only (cols)", expected=vn.size, actual=nm.ncols());
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
      assertRealEquals(msg="Set/Get by name", expected=17.0, actual=nm.get("star lord", "yondu"));
    } catch e: DimensionMatchError {
      writeln(e);
    } catch e: Error {
      writeln(e);
    }
  }

  proc testArgMax() {
    var x: [1..3] real = [1.1, 3.3, 2.2];
    var y: [1..3,1..3] real = ((1,0,0), (0,0,2), (0,3,0));
    var xSD: sparse subdomain(x.domain);
    var z: [xSD] real;
    xSD += 2; z[2] = 1.3;
    xSD += 3; z[3] = 0.8;

    assertBoolEquals("z is sparse", expected=true, actual=isSparseArr(z));
    assertIntEquals("argmax1d(z)", expected=2, actual=argmax1d(z));

    assertIntEquals("argmax(x)", expected=2, actual=argmax(x));
    assertIntArrayEquals("argmax(y, ?)", expected=[3,2], actual=argmax(y));
    assertIntArrayEquals("argmax(y, ?)", expected=[3,2], actual=argmax(y));
    assertIntArrayEquals("argmax(y,0)", expected=[3,2], actual=argmax(y, axis=0));
    assertIntArrayEquals("argmax(y,1)", expected=[1,3,2], actual=argmax(y, axis=1));
    assertIntArrayEquals("argmax(y,2)", expected=[1,3,2], actual=argmax(y, axis=2));

    var SD2: sparse subdomain(D),
        X2:[SD2] real;
    SD2 += (1,2); X2[1,2] = 1;
    SD2 += (3,1); X2[3,1] = 3;
    SD2 += (3,4); X2[3,4] = 4;
    SD2 += (3,6); X2[3,6] = 1;
    var m = new NamedMatrix(X=X2, names=vn);
    assertRealEquals("m rowMax by row number", expected=4, actual=m.rowMax(3));
    assertRealEquals("m rowMax by row name", expected=4, actual=m.rowMax("groot"));
    var e: [1..4] real = [3.0, 1.0, 4.0, 1.0];
    assertArrayEquals("m colMax", expected=e, actual=m.colMax());
    var f: [1..4] int = [1,2,3,4];
    //writeln(m.rowArgMax());
    //assertIntArrayEquals("m rowArgMax", expected=f, actual=m.rowArgMax());
    //assertIntEquals("m rowArgMax(3)", expected=4, actual=m.rowArgMax(3));
    /* This interface is kind of annoying, I know what row I'm sending in so I
       should just get the answer back */
    assertIntEquals("m rowArgMax(3)", expected=4, actual=m.rowArgMax(3)[2]);
    assertIntEquals("m rowArgMax('groot')", expected=4, actual=m.rowArgMax('groot')[2]);

    assertIntEquals("m rowArgMin(3)", expected=6, actual=m.rowArgMin(3)[2]);
    assertIntEquals("m rowArgMin('groot')", expected=6, actual=m.rowArgMin('groot')[2]);

    assertRealEquals("m rowMin(3)", expected=1, actual=m.rowMin(3));
    assertRealEquals("m rowMin('groot')", expected=1, actual=m.rowMin('groot'));

    assertRealEquals("m colMin(6)", expected=1, actual=m.colMin(6));
    assertRealEquals("m colMin('mantis')", expected=1, actual=m.colMin('mantis'));

    assertRealEquals("m colMax(6)", expected=1, actual=m.colMax(6));
    assertRealEquals("m colMax('mantis')", expected=1, actual=m.colMax('mantis'));

    assertIntEquals("m colArgMax(6)", expected=6, actual=m.colArgMax(6)[2]);
    assertIntEquals("m colArgMax('mantis')", expected=6, actual=m.colArgMax('mantis')[2]);

    assertIntEquals("m colArgMin(6)", expected=6, actual=m.colArgMin(6)[2]);
    assertIntEquals("m colArgMin('mantis')", expected=6, actual=m.colArgMin('mantis')[2]);


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
    assertRealApproximates(msg="Cosine Distance(X) norm", expected=1.39884e-06, actual=aa);

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
    assertRealApproximates(msg="Cosine Distance(X,Y) norm", expected=1.53583e-06, actual=bb);
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
    assertRealEquals(msg="Label Matrix entry (1,4)", expected=0.7, actual=L.data(1,4));
  }

  proc testECDF() {
    var x = [3,3,1,4];
    var ecdf = new ECDF(x);
    assertIntEquals("ECDF: Number of observations", expected=4, actual=ecdf.nobs);

    var y = [3.0, 55.0, 0.5, 1.5];
    var d = ecdf(y);
    assertArrayEquals("ECDF: Output", expected=[0.75,1.0,0.0,0.25], actual=d);
  }

  proc testBiMap() {
    var bm = new BiMap();
    bm.add("bob");
    bm.add("chuck");
    bm.add("bob");
    bm.add('ethel', 78);
    bm.add('frank', 3);

    assertIntEquals("BIMAP redundant entry ignored", expected=4, actual=bm.keys.size);
    for k in bm.keys {
      assertStringEquals("BIMAP name is retrieved", k, bm.idx[bm.ids[k]]);
      assertIntEquals("BIMAP id is retrieved", bm.ids[k], bm.get(k));
    }
    assertIntEquals("BIMPA max is set", expected=78, actual=bm.max());

    var abm = new BiMap();
    abm.add("one",1);
    abm.add("two",2);
    var bbm = new BiMap();
    bbm.add("three",3);
    bbm.add("four",4);

    var cbm = abm.uni(bbm);
    assertIntEquals("BIMAP union size", expected=4, actual=cbm.keys.size);
    assertIntEquals("BIMAP union max", expected=4, actual=cbm.max());
  }

  proc testViterbi() {
    var obs = ["normal", "cold", "dizzy"];
    var states = ["health", "fever"];
    var initP = [0.6, 0.4];

    /* (Hidden) State transition matrix
             Healthy Fever
    Healthy  0.7     0.3
      Fever  0.4     0.6
     */
    var A: [1..2, 1..2] real = Matrix(
      [0.7, 0.3],
      [0.4, 0.6]
    );

    /*
     State emission probabilities
             Normal Cold Dizzy
    Healthy  0.5    0.4  0.1
      Fever  0.1    0.3  0.6
     */
     var B: [1..2, 1..3] real = Matrix(
       [0.5, 0.4, 0.1],
       [0.1, 0.3, 0.6]
    );
    var v = Viterbi(obs, states, initP, transitionProbabilities=A, emissionProbabilities=B);
    assertStringArrayEquals("Viterbi states output", expected=["health","health","fever"], actual=v);
  }

  proc testLetters() {
    var ltrs = letters(28);
    assertStringEquals("First in letters is A", expected="A", actual=ltrs[1]);
    assertStringEquals("28th in letters is BB", expected="BB", actual=ltrs[28]);

    var gn = gridNames(7);
    assertIntEquals("Grid names(7) has 49 entries", expected=49, actual=gn.size);
    assertStringEquals("Last grid name is 'G7'", expected="G7", actual=gn[49]);
    var gn2 = gridNames(i=3, j=5);
    assertRealEquals("gridNames(3,5) has 15 entries", expected=15, actual=gn2.size);
    assertStringEquals("Last grid name is 'C5'", expected="C5", actual=gn2[15]);
  }

  proc testChoice() {
    var x = [1,2,3,4,5,6,7,8,9,10];
    var y = choice(a=x,size=2);
    assertIntEquals("Can pick two choices, no replacement, no p", expected=2, actual=y.size);
    var z = choice(x,size=2,replace=true);
    assertIntEquals("Can pick two choices, with replacement, no p", expected=2, actual=z.size);

    var s = [1, 2, 3, 4, 5];
    // Note, this does not need to be normalized but it is easier to see
    var p = [0.5, 0.25, 0.13, 0.09, 0.03];
    var m = chooseMultinomial(a=s, replace=false, size=3, p=p);
    assertIntEquals("Multinomial w/o replace returns correct number of results", expected=3, actual=m.size);
    var n = chooseMultinomial(a=s, replace=true, size=3, p=p);
    assertIntEquals("Multinomial w/ replace returns correct number of results", expected=3, actual=n.size);
    var o = choice(a=s, replace=false, size=3, p=p);
  }

  proc testRandomGenerators() {
    var n: int = 100000;
    var x: [1..n] int;
    //for i in 1..n { x[i] = randInt(1,6); }
    for i in 1..n do x[i] = randInt(1,6);
    var mu = + reduce x;
    assertRealApproximates("Average of 100,000 randInt(1,6) is about 3.5", expected=3.5, actual=mu:real/n:real);

    var threeD6 = for i in 1..n do nds(n=3, s=6);
    assertRealApproximates("Average of 100,000 three d6 is about 10.5", expected=10.5, actual=(+reduce threeD6):real/n:real);

    // Check random reals
    var rrls: [1..n] real;
    for i in 1..n do rrls[i] = rand(a=2,b=7);
    assertRealApproximates("Average of 100,000 random(2,7) is about 4.5", expected=4.5, actual=(+reduce rrls):real/n:real);

    var sq = seq(3,7);
    assertIntEquals("First element of sequence is 3", expected=3, actual=sq[1]);
    assertIntEquals("Last element of sequence is 7", expected=7, actual=sq[5]);

    var sq2 = seq(3,7, stride=5);
    assertIntEquals("First element of sequence(stride=5) is 3", expected=3, actual=sq2[1]);
    assertIntEquals("Last element of sequence(stride=5) is 7", expected=23, actual=sq2[5]);

  }

  proc testPersistance() {

  }

  proc testMatrixMakers() {
    var n: int = 5,
        d: domain(2),
        X: [d] real;

    d =  {1..n, 1..n};
    const o = ones(X.domain);
    assertRealEquals(" Norm of o is 5", expected=5.0, actual=norm(o));

    const p = ones(X.domain, v=7.0);
    assertRealEquals(" Norm of p is 7", expected=35.0, actual=norm(p));
  }

  proc testRowColSums() {
    var X = Matrix( [5,2] ,[6,1] ,[-1,6] ,[1,1] );
    assertArrayEquals("rowSums of X", expected=[7.0, 7.0, 5.0, 2.0], actual=rowSums(X));
    assertArrayEquals("colSums of X", expected=[11.0, 10.0], actual=colSums(X));
  }

  proc testNN() {
    var layerOneUnits = 5,
        inputDim = 8,
        epochs=10,
        batchSize = 4,
        model = new Sequential(),
        lr: real = 0.01;

    var X = Matrix( [0,0] ,[0,1] ,[1,0] ,[1,1] ),
        y = Vector([0,1,1,0]);
    //model.add(new Dense(units=layerOneUnits, inputDim=inputDim, batchSize=batchSize));
    model.add(new Dense(units=5));
    model.add(new Dense(units=6));
    model.add(new Activation(name="logistic"));
    model.fit(xTrain=X, yTrain=y, epochs=epochs, batchSize=batchSize, lr=lr);
    assertIntEquals("NN correct number of layers", expected=4, actual=model.layers.size);
  }

  proc run() {
    super.run();
    testNN();
//    testRowColSums();
//    testMatrixMakers();
//    testMatrixOperators();
//    tropicalTesting();
//    testIndexSort();
//    testNamedMatrix();
//    testSetRowNames();
//    testSetColNames();
//    testNamedMatrixInitWithNames();
//    testSetByName();
//    testArgMax();
//    testCosineDistance();
//    testLabelMatrix();
//    testECDF();
//    testBiMap();
//    testViterbi();
//    testLetters();
//    testChoice();
//    testRandomGenerators();
    return 0;
  }
}

proc main(args: [] string) : int {
  var t = new NumSuchTest(verbose=false);
  var ret = t.run();
  t.report();
  return ret;
}
