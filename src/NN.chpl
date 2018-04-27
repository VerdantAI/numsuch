/*
 Another pass at the NN based on Alg. 6.3, 6.4 in Goodfellow, et. al. Chapter 6, approx p 204
 */

 module NN {
   use LinearAlgebra,
       Time,
       Random;

   class Sequential {
     var layerDom = {1..0},
         layers: [layerDom] Layer,
         batchSize: int,
         outDim: int,
         loss: Loss = new Loss(),
         trained: bool = false;

     proc init() { }

     proc add(d:Dense) {
       this.layers.push_back(new Layer(units=d.units, name="L" + (this.layerDom.high+1):string));
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
         currentLayer.wDom = {1..lowerLayer.units, 1..currentLayer.units};
         currentLayer.bDom = {1..currentLayer.units};  // will construct batchSize tall matrix later
         currentLayer.aDom = {1..this.batchSize, 1..currentLayer.units};
         currentLayer.hDom = {1..this.batchSize, 1..currentLayer.units};
         fillRandom(currentLayer.W);
         fillRandom(currentLayer.b);
         currentLayer.W = 0.25 * currentLayer.W;
         currentLayer.b = 0.25 * currentLayer.b;
         writeln(currentLayer);
       }
     }
     proc fit(xTrain:[], yTrain:[], epochs: int, batchSize:int, lr: real=0.01) {
       this.compile(X=xTrain, y=yTrain);
       for i in 1..epochs {
         const o = this.feedForward(X=xTrain, y=yTrain);
         writeln("at the top!");
         this.layers[this.layerDom.high].error = this.loss.J(yHat=o.h, y=yTrain);
         this.backProp(X=xTrain, y=yTrain);
       }
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
     proc backProp(X:[], y:[]) {
       var t:[1..this.batchSize, 1..this.outDim] real;
       for l in this.layerDom.low+1..this.layerDom.high by -1 {
         ref currentLayer = this.layers[l];
         ref lowerLayer= this.layers[l-1];
         //try! this.printStep(upperLayer=upperLayer, lowerLayer=currentLayer, direction="backProp",step=l);
         try! this.printStep(upperLayer=currentLayer, lowerLayer=lowerLayer, direction="backProp",step=l);
         currentLayer.dW = lowerLayer.h.T.dot(currentLayer.error);
         currentLayer.W = currentLayer.W.plus(currentLayer.dW);

         // For db I need column sums of the error
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
         b:[bDom] real,
         db:[bDom] real,
         a:[aDom] real,
         h:[hDom] real,
         g:[aDom] real,
         error: [hDom] real;


     proc init(name: string, units: int){
       this.name=name;
       this.units = units;
       this.activation = new Activation(name="DEFAULT");
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
       if name == "relu" {
         return sigmoid(x);
       } else if name == "logistic" {
         return exp(x);
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
