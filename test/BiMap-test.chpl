use NumSuch;
var bm = new BiMap();
bm.add("bob");
bm.add("chuck");
bm.add("bob");
for k in bm.keys {
  writeln("Key: ", k, "\tID: ", bm.ids[k], "\tIndex: "
  , bm.idx[bm.ids[k]], "\tGet(string): ", bm.get(k)
  , "\tGet(int): ", bm.get(bm.ids[k])
  );
}

bm.add('ethel', 78);
for k in bm.keys {
  writeln("Key: ", k, "\tID: ", bm.ids[k], "\tIndex: "
  , bm.idx[bm.ids[k]], "\tGet(string): ", bm.get(k)
  , "\tGet(int): ", bm.get(bm.ids[k])
  );
}

bm.add('frank', 3);
for k in bm.keys {
  writeln("Key: ", k, "\tID: ", bm.ids[k], "\tIndex: "
  , bm.idx[bm.ids[k]], "\tGet(string): ", bm.get(k)
  , "\tGet(int): ", bm.get(bm.ids[k])
  );
}
