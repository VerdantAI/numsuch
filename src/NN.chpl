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
         var g = this.loss.J(yHat=o.h, y=yTrain);
         writeln(g);
         this.backProp(X=xTrain, y=yTrain, g=g);
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
     proc backProp(X:[], y:[], g:[]) {
       var t:[1..this.batchSize, 1..this.outDim] real;
       t[..,1] = g;
       this.layers[this.layerDom.high].g = t;
       for l in this.layerDom.low+1..this.layerDom.high by -1 {
         ref currentLayer = this.layers[l];
         ref lowerLayer= this.layers[l-1];
         currentLayer.g = currentLayer.g * currentLayer.activation.df(currentLayer.a);

         // Update b
         // Update W

         try! this.printStep(upperLayer=currentLayer, lowerLayer=lowerLayer,direction="backProp",step=l);
         const tg = currentLayer.g.dot(currentLayer.W.T);
         writeln("tg.shape: ", tg.shape);
         writeln("ll.g.shape ", lowerLayer.g.shape);
         if l > this.layerDom.low+1 then lowerLayer.g = currentLayer.g.dot(currentLayer.W.T);
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
         b:[bDom] real,
         a:[aDom] real,
         h:[hDom] real,
         g:[aDom] real;


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
      if this.name == "DEFAULT" {
        return yHat - y;
      } else {
        return yHat - y;
      }
    }
  }

}
