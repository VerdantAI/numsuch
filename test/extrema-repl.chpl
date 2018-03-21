use LinearAlgebra,
    LinearAlgebra.Sparse,
    Chingon;

/* MERGE WITH chingon-base-test.chpl ONCE REFACTORED
   BRANCH IS MERGED WITH DEVELOP.
*/

    var nv: int = 8,
        D: domain(2) = {1..nv, 1..nv},
        SD: sparse subdomain(D),
        X: [SD] real;

    var vn: [1..0] string;
    vn.push_back("star lord");
    vn.push_back("gamora");
    vn.push_back("groot");
    vn.push_back("drax");
    vn.push_back("rocket");
    vn.push_back("mantis");
    vn.push_back("yondu");
    vn.push_back("nebula");

    writeln(vn);

    SD += (1,2); X[1,2] = 1;
//    SD += (2,3); X[2,3] = 1;
    SD += (3,1); X[3,1] = 3;
    SD += (3,4); X[3,4] = 4;
//    SD += (4,5); X[4,5] = 1;
    SD += (3,6); X[3,6] = 1;
//    SD += (6,8); X[6,8] = 1;
//    SD += (1,4); X[1,4] = 1;
//    SD += (1,5); X[1,5] = 1;
//    SD += (2,6); X[2,6] = 1;
//    SD += (2,7); X[2,7] = 1;

    var nm = new NamedMatrix(X=X, names = vn);
    writeln("NamedMatrix");
    writeln(nm.X);
    writeln(nm.rowMax(3));
    writeln(nm.colMax());
    writeln(nm.colMax().domain);
    writeln(nm.rowArgMax(3));
    writeln(nm.rowArgMax());
    writeln(nm.rowArgMax().domain);
    writeln(nm.colArgMin());
    writeln(nm.colMin(4));
