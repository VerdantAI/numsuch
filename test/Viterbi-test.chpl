use NumSuch,
    Viterbi,
    LinearAlgebra;

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
writeln(v);
