/*
 A simple Graph object.  This code was originally in the Chapel source, which can be found here:
 https://github.com/chapel-lang/chapel/blob/master/test/studies/labelprop/Graph.chpl

 */

 module GraphUtils {
   use Core;

     //
     // VertexData: stores the neighbor list of a vertex.
     //
     /* private */
     record VertexData {
       type nodeIdType;
       param weighted; //hardcoded for now.
       type edgeWeightType;

       param initialFirstAvail;
       param initialLastAvail;

       //
       // We will represent the neighbor list as an array of nleType.
       // nle = Neighbor List Element.
       //

       type nleType = (nodeIdType, edgeWeightType);
       //type nleType = (nodeIdType,);
       var ndom = {initialFirstAvail..initialLastAvail};
       var neighborList: [ndom] nleType;
       var last = 0;

       var nid: int;
       //param nid = 1;  // TODO: Assign a vertex id
       var weight: real;

       proc numNeighbors()  return ndom.numIndices;
 /*
       var firstAvailNeighbor$: [vertex_domain] sync int = initialFirstAvail;

       // Both the vertex and firstAvail must be passed by reference.
       // TODO: possibly compute how many neighbors the vertex has, first.
       // Then allocate that big of a neighbor list right away.
       // That way there will be no need for a sync, just an atomic.
       G.Row[u].addEdgeOnVertex(u, v, w, firstAvailNeighbor$[u]);
 */
       // firstAvail$ must be passed by reference
       proc addEdgeOnVertex(to:nodeIdType, weight:edgeWeightType, firstAvail$: sync int) {
         on this do {
           // todo: the compiler should make these values local automatically!
           const /*u = from,*/ v = to, w = weight;
             // Lock and unlock should be within 'local', but currently
             // need to pull them out due to implementation.
             // lock the vertex
             const edgePos = firstAvail$;

           local {
             const prevNdomLen = ndom.high;
             if edgePos > prevNdomLen {
               // grow our arrays, by 2x
               // statistics: growCount += 1;
               ndom = {1..prevNdomLen * 2};
               // bounds checking below will ensure (edgePos <= ndom.high)
             }
             // store the edge
             if weighted {
               neighborList[edgePos] = (v, w);
             } else {
               neighborList[edgePos] = (v,);
             }
           }

             // release the lock
             firstAvail$ = edgePos + 1;
         } // on
       }

       // not parallel-safe
       proc tidyNeighbors(firstAvail$: sync int) {
         local {
           // no synchronization here
           var edgeCount = firstAvail$.readXX() - 1;
           RemoveDuplicates(1, edgeCount);
           // TODO: ideally if we don't save much memory, do not resize
           if edgeCount != ndom.numIndices {
             // statistics: shrinkCount += 1;
             ndom = 1..edgeCount;
           }
           // writeln("stats ", growCount, " ", shrinkCount, ".");
         }
       }
     } // record VertexData

     use BlockDist;

     // ------------------------------------------------------------------------
     // The data structures below are chosen to implement an irregular (sparse)
     // graph using rectangular domains and arrays.
     // Each node in the graph has a list of neighbors and a corresponding list
     // of (integer) weights for the implicit edges.
     // ------------------------------------------------------------------------


     /* store a graph
      */
     class Graph {
       type nodeIdType = int(64);
       param weighted = false;
       type edgeWeightType = int(64);

       const vertices; // generic type - domain of vertices
       //var vertices: domain(1); // generic type - domain of vertices

       param initialFirstAvail = 1;
       param initialLastAvail = 1;

       var   Row      : [vertices] VertexData(nodeIdType, weighted,
                                      edgeWeightType,
                                      initialFirstAvail, initialLastAvail);
       var num_edges = -1;

       /*
       proc init(vertices: domain) {
         writeln("  GOOD ONE, INIT?");
         this.vertices = vertices;
       }
        */

       /* iterate over all neighbor (ID, weight) pairs
          (actually returns an iterable rather than being
           an iterator).
        */
       proc NeighborPairs( v : index (vertices) ) {
         return Row (v).neighborList;
       }

       /* iterate over all neighbor IDs
        */
       iter Neighbors( v : index (vertices) ) {
         for nlElm in Row(v).neighborList do
           yield nlElm(1); // todo -- use nid
       }

       /* iterate over all neighbor IDs
        */
       iter Neighbors( v : index (vertices), param tag: iterKind)
       where tag == iterKind.leader {
         for block in Row(v).neighborList._value.these(tag) do
           yield block;
       }

       /* iterate over all neighbor IDs
        */
       iter Neighbors( v : index (vertices), param tag: iterKind, followThis)
       where tag == iterKind.follower {
         for nlElm in Row(v).neighborList._value.these(tag, followThis) do
           yield nElm(1);
       }

       /* iterate over all neighbor weights
        */
       iter edge_weight( v : index (vertices) ) {
         for nlElm in Row(v).neighborList do
           yield nlElm(2); // todo -- use VertexData.weight
       }

       /* iterate over all neighbor weights
        */
       iter edge_weight( v : index (vertices), param tag: iterKind)
       where tag == iterKind.leader {
         for block in Row(v).neighborList._value.these(tag) do
           yield block;
       }

       /* iterate over all neighbor weights
        */
       iter edge_weight( v : index (vertices), param tag: iterKind, followThis)
       where tag == iterKind.follower {
         for nlElm in Row(v).neighborList._value.these(tag, followThis) do
           yield nlElm(2); // todo -- use VertexData.weight
       }

       /* return the number of neighbors
        */
       proc   n_Neighbors (v : index (vertices) )
       {return Row (v).numNeighbors();}

       /*
        Returns and array of the degree for each vertex
        */
       proc degree() {
         var r: [Row.domain] real;
         for i in Row.domain {
           r[i] = n_Neighbors(i);
         }
         return r;
       }

     } // class Associative_Graph

     /* how to use Graph: e.g.
     const vertex_domain =
       if DISTRIBUTION_TYPE == "BLOCK" then
         {1..N_VERTICES} dmapped Block ( {1..N_VERTICES} )
       else
     {1..N_VERTICES} ;

     writeln("allocating Associative_Graph");
     var G = new Associative_Graph (vertex_domain);
     */

     /* Helps to construct a graph from row, column, value
        format.
     */
     proc buildUndirectedGraph(triples, param weighted:bool, vertices) where
       isRecordType(triples.eltType)
     {

       // sync version, one-pass, but leaves 0s in graph
       /*
       var r: triples.eltType;
       var G = new Graph(nodeIdType = r.to.type,
                         edgeWeightType = r.weight.type,
                         vertices = vertices);
       var firstAvailNeighbor$: [vertices] sync int = G.initialFirstAvail;
       forall trip in triples {
         var u = trip.from;
         var v = trip.to;
         var w = trip.weight;
         // Both the vertex and firstAvail must be passed by reference.
         // TODO: possibly compute how many neighbors the vertex has, first.
         // Then allocate that big of a neighbor list right away.
         // That way there will be no need for a sync, just an atomic.
         G.Row[u].addEdgeOnVertex(v, w, firstAvailNeighbor$[u]);
         G.Row[v].addEdgeOnVertex(u, w, firstAvailNeighbor$[v]);
       }*/

       // atomic version, tidier
       var r: triples.eltType;
       var G = new Graph(nodeIdType = r.to.type,
                         edgeWeightType = r.weight.type,
                         vertices = vertices,
                         initialLastAvail=0);
       var next$: [vertices] atomic int;

       forall x in next$ {
         next$.write(G.initialFirstAvail);
       }

       // Pass 1: count.
       forall trip in triples {
         var u = trip.from;
         var v = trip.to;
         var w = trip.weight;
         // edge from u to v will be represented in both u and v's edge
         // lists
         next$[u].add(1, memory_order_relaxed);
         next$[v].add(1, memory_order_relaxed);
       }
       // resize the edge lists
       forall v in vertices {
         var min = G.initialFirstAvail;
         var max = next$[v].read(memory_order_relaxed) - 1;
         G.Row[v].ndom = {min..max};
       }
       // reset all of the counters.
       forall x in next$ {
         next$.write(G.initialFirstAvail, memory_order_relaxed);
       }
       // Pass 2: populate.
       forall trip in triples {
         var u = trip.from;
         var v = trip.to;
         var w = trip.weight;
         // edge from u to v will be represented in both u and v's edge
         // lists
         var uslot = next$[u].fetchAdd(1, memory_order_relaxed);
         var vslot = next$[v].fetchAdd(1, memory_order_relaxed);
         G.Row[u].neighborList[uslot] = (v,);
         G.Row[v].neighborList[vslot] = (u,);
       }

       return G;
     }

     /*
      Take a general sparse matrix and turn it into a Graph. Mixed w/ this SO
        https://stackoverflow.com/questions/45846989/how-to-iterate-non-zeroes-in-a-sparse-matrix-in-chapel/46248469#46248469
      */
     proc buildFromSparseMatrix(A: [], param weighted:bool, param directed:bool) {
       //const n = max reduce A.shape;
       const n = A.shape[1];

       const vertices: domain(1) = {1..n};
       var G = new Graph(nodeIdType = int.type,
                         edgeWeightType = A.eltType,
                         vertices = vertices,
                         initialLastAvail=0);
       var next$: [vertices] atomic int;

       // Set number of edges per node, copying logic above but with a matrix
       if !directed {
         forall v in vertices {
           next$[v].write(G.initialFirstAvail);
           G.Row[v].nid = v;
         }
         // Increase the domain size at the right nodes
         for (u,v) in A.domain {
           var w = A[u,v];
           // edge from u to v will be represented in both u and v's edge
           // lists
           next$[u].add(1, memory_order_relaxed);
           next$[v].add(1, memory_order_relaxed);
         }
         // resize the edge lists
         forall v in vertices {
           var min = G.initialFirstAvail;
           var max = next$[v].read(memory_order_relaxed) - 1;
           G.Row[v].ndom = {min..max};
         }
         // reset all of the counters.
         forall x in next$ {
           next$.write(G.initialFirstAvail, memory_order_relaxed);
         }
         // Pass 2: populate.
         //forall trip in triples {
         forall (u,v) in A.domain {
           var w = A[u,v];
           // edge from u to v will be represented in both u and v's edge
           // lists
           var uslot = next$[u].fetchAdd(1, memory_order_relaxed);
           var vslot = next$[v].fetchAdd(1, memory_order_relaxed);
           G.Row[u].neighborList[uslot] = (v,w);
           G.Row[v].neighborList[vslot] = (u,w);
         }
       }

       // In this case just run along the rows, since no symmetry
       if directed {
         forall v in vertices {
           next$[v].write(G.initialFirstAvail);
           G.Row[v].nid = v;
           // There should be a way to bulk add, but I don't want to mess with it just yet.
           var t = 0;
           for c in A.domain.dimIter(2,v) do {
             t = t+1;
             next$[v].add(1, memory_order_relaxed);
             G.Row[v].ndom = {G.initialFirstAvail..t};
             G.Row[v].neighborList[t] = (c,A[v,c]);
           }
         }
       }
       return G;
     }

 }
