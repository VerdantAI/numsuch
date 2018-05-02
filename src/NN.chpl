/*
 Another pass at the NN based on Alg. 6.3, 6.4 in Goodfellow, et. al. Chapter 6, approx p 204
 */

 module NN {
   use LinearAlgebra,
       Time,
       Norm,
       Random;

   class Sequential {
     var layerDom = {1..0},
         layers: [layerDom] Layer,
         batchSize: int,
         outDim: int,
         loss: Loss = new Loss(),
         momentum: real = 0.05,
         lr: real = 0.03,
         trained: bool = false,
         reportInterval: int = 1000;

     proc init() { }

     proc add(d:Dense) {
       this.layers.push_back(new Layer(units=d.units, name="H" + (this.layerDom.high+1):string));
     }
     proc add(a: Activation) {
       ref currentLayer = this.layers[this.layerDom.last];
       currentLayer.activation = a;
     }

     proc compile(X:[], y:[]) {
       var inputDim = X.shape[1];
       if y.shape.size == 2 {
         this.outDim = y.shape[2];
       } else {
         this.outDim = 1;
       }
       this.batchSize = X.shape[1];
       var dataLayer = new Layer(units=X.shape[2], name="Data");
       dataLayer.wDom = {1..X.shape[1], 1..X.shape[2]};
       dataLayer.hDom = {1..X.shape[1], 1..X.shape[2]};
       dataLayer.h = X;
       this.layers.push_front(dataLayer);
       writeln(dataLayer);
       this.layers.push_back(new Layer(units=this.outDim, name="Yhat"));
       for l in this.layerDom.low+1..this.layerDom.high {
         ref lowerLayer = this.layers[l-1];
         ref currentLayer = this.layers[l];
         currentLayer.aDom = {1..this.batchSize, 1..currentLayer.units};
         currentLayer.hDom = {1..this.batchSize, 1..currentLayer.units};
         if !this.trained {
           currentLayer.wDom = {1..lowerLayer.units, 1..currentLayer.units};
           currentLayer.bDom = {1..currentLayer.units};  // will construct batchSize tall matrix later
           fillRandom(currentLayer.W);
           fillRandom(currentLayer.b);
           currentLayer.W = 0.25 * currentLayer.W;
           currentLayer.b = 0.25 * currentLayer.b;
         }
         writeln(currentLayer);
       }
     }
     proc fit(xTrain:[], yTrain:[], epochs: int, batchSize:int, lr: real=0.01) {
       this.lr = lr;
       this.compile(X=xTrain, y=yTrain);
       for i in 1..epochs {
         const o = this.feedForward(X=xTrain, y=yTrain);
         //writeln("at the top! Current output:\n ", o.h);
         this.layers[this.layerDom.high].error = this.loss.J(yHat=o.h, y=yTrain);
         if i % this.reportInterval == 0 {
           try! writeln("epoch: %5n norm error: %7.4dr".format(i, norm(this.layers[this.layerDom.high].error.T)));
         }
         this.backProp(X=xTrain, y=yTrain);
       }
       writeln("Done!  Current error:\n", this.layers[this.layerDom.high].h.T);
       this.trained = true;
     }
     proc feedForward(X:[], y:[]) {
       for l in this.layerDom.low+1..this.layerDom.high {
         ref lowerLayer = this.layers[l-1];
         ref currentLayer = this.layers[l];
         //try! this.printStep(upperLayer=currentLayer, lowerLayer=lowerLayer,direction="feedForward",step=l);
         var b:[1..this.batchSize, 1..currentLayer.units] real;
         for i in 1..this.batchSize {
           b[i,..] = currentLayer.b;
         }
         currentLayer.a = b.plus(lowerLayer.h.dot(currentLayer.W)); // Don't forget to add the bias
         currentLayer.h = currentLayer.activation.f(currentLayer.a);
       }
       return this.layers[this.layerDom.high];
     }
     /*
     Notice that under this schedule, the errors reach "up" and the gradients reach "down".
     The gradients depend on the errors.
      */
     proc backProp(X:[], y:[]) {
       var t:[1..this.batchSize, 1..this.outDim] real;
       for l in this.layerDom.low..this.layerDom.high-1 by -1 {
         ref upperLayer = this.layers[l+1];
         ref currentLayer = this.layers[l];
         //ref lowerLayer= this.layers[l-1];
         //try! this.printStep(upperLayer=currentLayer, lowerLayer=lowerLayer, direction="backProp",step=l);
         //try! this.printStep(upperLayer=upperLayer, lowerLayer=currentLayer, direction="backProp",step=l);
         currentLayer.error = currentLayer.h * (ones(currentLayer.h.domain) - currentLayer.h) * (upperLayer.error.dot(upperLayer.W.T));
         upperLayer.dW = currentLayer.h.T.dot(upperLayer.error);
         upperLayer.db = colSums(upperLayer.error);
         upperLayer.W_vel = this.momentum * upperLayer.W_vel - this.lr * upperLayer.dW;
         upperLayer.W = upperLayer.W.plus(upperLayer.W_vel);
         upperLayer.b_vel = this.momentum * upperLayer.b_vel - this.lr * upperLayer.db;
         upperLayer.b = upperLayer.b.plus(upperLayer.b_vel);

       }
     }

     proc printStep(upperLayer: Layer, lowerLayer: Layer, direction: string, step: int) throws {
       writeln(" * %s: %n".format(direction, step));
       writeln(upperLayer);
       writeln(lowerLayer);
     }

   }

   class Layer {
     var name: string,
         units: int,
         inputDim: int,
         activation: Activation,
         wDom: domain(2),
         bDom: domain(1),
         aDom: domain(2),
         hDom: domain(2),
         W:[wDom] real,
         dW:[wDom] real,
         W_vel:[wDom] real = 0.0,
         b:[bDom] real,
         db:[bDom] real,
         b_vel: [bDom] real = 0.0,
         a:[aDom] real,
         h:[hDom] real,
         g:[aDom] real,
         error: [hDom] real;


     proc init(name: string, units: int){
       this.name=name;
       this.units = units;
       this.activation = new Activation(name="sigmoid");
     }

     proc readWriteThis(f) throws {
       f <~> "%6s".format(this.name)
         <~> " W:" <~> this.W.shape
         <~> " h:" <~> this.h.shape
         <~> " b:" <~> this.b.shape
         <~> " a:" <~> this.a.shape;

     }
   }

   class Activation {
     var name: string;
     proc init(name: string) {
       this.name=name;
     }

     proc f(x: real) {
       if this.name == "relu" {
         return ramp(x);
       } else if this.name == "sigmoid" {
         return sigmoid(x);
       } else if this.name == "tanh" {
        return tanh(x);
       } else if this.name == "step" {
         return heaviside(x);
       } else {
         return 0;
       }
     }

     proc df(x:real) {
       if this.name == "relu" {
         return dramp(x);
       } else if this.name == "sigmoid" {
         return dsigmoid(x);
       } else if this.name == "tanh" {
         return dtanh(x);
       } else if this.name == "step" {
         return dheaviside(x);  //maybe I'll make this dsigmoid(x) for fun?
       } else {
         return 0;
       }
     }

     // Activation Functions
     proc ramp(x: real) {
       if x < 0 {
         return 0;
       } else {
         return x;
       }
     }

     proc sigmoid(x: real) {
       return (1/(1 + exp(-x)));
     }

     proc tanh(x: real) {
       return (exp(x) - exp(-x))/(exp(x) + exp(-x));
     }

     proc heaviside(x) {
       if x < 0 {
         return 0;
       } else {
         return 1;
       }
     }

     // Derivates of Activation Functions
     proc dsigmoid(x) {
       return sigmoid(x) * (1 - sigmoid(x));
     }

     proc dramp(x) {
       return heaviside(x);
     }

     proc dtanh(x) {
       return 1 - (tanh(x))**2;
     }

     proc dheaviside(x) {
       if x == 0 {
         return 10000000000000000;
       } else {
         return 0;
       }
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

  class Loss {
    var name: string;
    proc init(name: string="DEFAULT") {
      this.name = name;
    }
    proc J(yHat: [], y:[]) {
      var r: [yHat.domain] real;
      if this.name == "DEFAULT" {
        r = yHat - y;
      } else {
        r = yHat - y;
      }
      return r;
    }
  }

}
