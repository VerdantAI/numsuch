/*
 This is a pretty good example of the pseudocode http://www.cleveralgorithms.com/nature-inspired/neural/backpropagation.html

 The visuals on this page are good: http://briandolhansky.com/blog/2014/10/30/artificial-neural-networks-matrix-form-part-5

 This page goes a little deeper: https://towardsdatascience.com/under-the-hood-of-neural-network-forward-propagation-the-dreaded-matrix-multiplication-a5360b33426

 Still getting dimension errors, feel like I'm doing somthing stupid.

 */
module NN {
  use LinearAlgebra,
      Time,
      Random;

  class Sequential {
    var layerDom = {1..0},
        layers: [layerDom] Layer,
        trained: bool = false;

    proc add(d: Dense) {
      var l = new Layer(units=d.units, name="L" + (this.layerDom.high+1):string);
      //l.d = d;
      //l.units = d.units;
      this.layers.push_back(l);
    }

    proc add(a: Activation) {
      ref currentLayer = this.layers[this.layerDom.last];
      currentLayer.activation = a;
    }

    proc compile(xTrain:[], yTrain:[], predict=false) {
      var outDim: int = 1;
      if yTrain.shape.size == 2 {
        outDim = yTrain.shape[2];
      }
      var data = new Dense(units=xTrain.shape[2]);
      data.inputDim = xTrain.shape[1];
      var dataLayer = new Layer(units=xTrain.shape[2], name="Data");
      dataLayer.inputDim=xTrain.shape[1];
      dataLayer.units=xTrain.shape[2];
      dataLayer.weightDom = {1..xTrain.shape[1], 1..xTrain.shape[2]};
      dataLayer.sDom = {1..xTrain.shape[1], 1..xTrain.shape[2]};
      dataLayer.Z = xTrain;
      //dataLayer.d = data;
      try! writeln(dataLayer);

      var outputLayer = new Layer(units=outDim, name="Yhat");

      // Set up the rest of the layers.
      if this.trained {
        this.layers[this.layerDom.low] = dataLayer;
      } else {
        this.layers.push_front(dataLayer);
        this.layers.push_back(outputLayer);

        //try! writeln("layer %s input size: %i  output size %s".format(dataLayer.name, dataLayer.d.inputDim, dataLayer.d.units));
        for i in this.layerDom.low+1..this.layerDom.high {
            ref lowerLayer = this.layers[i-1];
            ref currentLayer = this.layers[i];
            currentLayer.inputDim = lowerLayer.inputDim;  // propogate the height of X
            currentLayer.weightDom = {1..lowerLayer.units, 1..currentLayer.units};
            currentLayer.sDom = {1..lowerLayer.inputDim, 1..currentLayer.units};
            currentLayer.fDom = {1..currentLayer.units, 1..lowerLayer.inputDim};
            currentLayer.dDom = {1..lowerLayer.inputDim, 1..currentLayer.units};
            fillRandom(currentLayer.W);
            try! writeln(currentLayer);
          }
        }
      }

    proc fit(xTrain:[], yTrain:[], epochs: int, batchSize:int, lr: real=0.01) {
      this.compile(xTrain=xTrain, yTrain=yTrain);
      for e in 1..epochs {
        const output = this.feedForward(X=xTrain, y=yTrain);
        writeln("at the top, output is ", output.Z);
        this.backProp(X=xTrain);
      }
      this.trained = true;
    }

    proc feedForward(X:[], y:[]) {
      for l in this.layerDom.low+1..this.layerDom.high {
        try! writeln("feedForward layer %n".format(l));
        ref lowerLayer = this.layers[l-1];
        ref currentLayer = this.layers[l];
        currentLayer.S = (lowerLayer.Z).dot(currentLayer.W);
        currentLayer.Z = currentLayer.activation.f(currentLayer.S);
        currentLayer.F = currentLayer.activation.df(currentLayer.S.T);
        if l == this.layerDom.high {
          try! writeln("currentLayer: %s".format(currentLayer.name));
          var m = currentLayer.Z.T.minus(Matrix(y));
          writeln("m.shape: ", m.shape);
          currentLayer.D = m.T;
          // calculate loss
        }
      }
      return this.layers[this.layerDom.high];
    }

    proc backProp(X:[]) {
      for l in this.layerDom.low..this.layerDom.high-1 by -1 {
        writeln("backprop layer ", l);
        ref upperLayer = this.layers[l+1];
        ref currentLayer = this.layers[l];
        try! writeln(upperLayer);
        try! writeln(currentLayer);
        //var wtd = (currentLayer.W.T).dot(upperLayer.D);
        var wtd = (upperLayer.W).dot(upperLayer.D.T);
        writeln("wtd shape: ", wtd.shape);
        currentLayer.D = currentLayer.F * (upperLayer.W).dot(upperLayer.D.T);
      }
    }

  }

  class Layer {
    var units: int,
        name: string,
        inputDim: int,
        activation: Activation,
        weightDom: domain(2),  // size of the W matrix, inputDim x units
        sDom: domain(2),
        fDom: domain(2),
        dDom: domain(2),
        biasDom = {1..units},
        W: [weightDom] real,
        S: [sDom] real,
        Z: [sDom] real,
        F: [fDom] real,
        D: [dDom] real;
    proc init(units: int, name: string = "BLANK") {
      this.units = units;
      this.name = name;
      this.activation = new Activation(name="ident");
    }

    proc readWriteThis(f) throws {
      f <~> " * %6s".format(this.name) <~> " W.shape " <~> this.W.shape <~> " S " <~> this.S.shape
        <~> " Z.shape " <~> this.Z.shape <~> " F.shape " <~> this.F.shape <~> " D.shape " <~> this.D.shape;
    }
  }

  class Dense {
    var units: int,
        inputDim: int;

    proc init(units:int, inputDim=0) {
      this.units=units;
      this.inputDim=inputDim;
    }
  }

  class Activation {
    var name: string;
    proc init(name: string) {
      this.name=name;
    }

    proc f(x: real) {
      if name == "relu" {
        return sigmoid(x);
      } else {
       return x;
      }
    }

    proc df(x:real) {
      if this.name == "relu" {
        return derivativesSigmoid(x);
      } else {
        return 1;
      }
    }

    proc sigmoid(x: real) {
      return (1/(1 + exp(-x)));
    }
    proc derivativesSigmoid(x) {
      return x * (1-x);
    }

  }

}
