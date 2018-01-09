/*
Basic implementation of the [Viterbi Algorithm](https://en.wikipedia.org/wiki/Viterbi_algorithm)
Note the ``observations`` and ``states`` are assume to be an array of strings.  Future implementations
may send a flag

:arg observations: A sequence of observed states. Assumed to be an array of strings.
:arg states: An array of hidden state names, assumed to be strings
:arg initialProbabilities: A probability distribution over the hidden states
:arg transitionProbabilities: Transition matrix for hidden state to hidden state
:arg emissionProbabilities: Probabilites mapping hidden state -> observed state
 */
 proc Viterbi(observations: [], states: []
   , initialProbabilities: [], transitionProbabilities: [], emissionProbabilities: []) {
     var T_1:[1..states.size, 1..observations.size] real;
     var T_2:[1..states.size, 1..observations.size] int;
     T_1 = 0;
     T_2 = 0;
     /*
     Initialize the matrices ``T_1``, ``T_2``
     We can be parallel here, but it doesn't get us much
      */
     forall k in 1..states.size {
       T_1[k,1] = initialProbabilities[k] * emissionProbabilities[k, 1];
     }

     /*
     Create an index to take the observations
      */
    var obsDom: domain(string);
    var obsInd: [obsDom] int;
    for o in 1..observations.size {
      obsDom += observations[o];
      obsInd[observations[o]] = o;
    }

     /*
     Run through the observations
      */
     for t in 2..observations.size {
       // happens along each column
       const oInd: int = obsInd[observations[t]];
       for s in 1..states.size {
            // create a vector of the column T_1[1..states.size,t-1]
            var ys, ts, ap, bp: [1..states.size] real;
            for x in 1..states.size {
              ts[x] = T_1[x, t-1];
              if transitionProbabilities.domain.member((x,s)) {
                ap[x] = transitionProbabilities(x,s);
              } else {
                ap[x] = 0;
              }
              if emissionProbabilities.domain.member((s, oInd)) {
                bp[x] = emissionProbabilities(s, oInd);
              } else {
                bp[x] = 0;
              }
              ys[x] = ts[x] * ap[x] * bp[x];
            }
            T_1[s,t] = max reduce(ys);
            T_2[s,t] = argmax(ys);
       }
     }
     // Output the most probable path, X
     var X: [observations.domain] string;
     const f = argmax(T_1[..,observations.size]);
     X[observations.size] = states[f];
     for t in 1..(observations.size-1) by -1 {
       var z = T_2[argmax(T_1[..,t+1],axis=1), t+1];
       X[t] = states[z];
     }

     return X;
   }
