# c interface to waterman convexhull

import wp, convexhull_ref, vmath

# c interfaces
# nim c -d:release --app:staticLib wmc.nim 

type
   cint = int32
   
proc watermanPoly*( # dynamic mem version
    radius    : float64,
    nfaces    : var cint, 
    nvertexes : var cint,
    faces     : var ptr UncheckedArray[cint],
    vertexes  : var ptr UncheckedArray[float64]) {.exportc.}=
   
   let (lfaces, lvertexes) = radius.waterman_poly.convexHull # do it!
   
   nvertexes = lvertexes.len.cint
   nfaces = lfaces.len.cint
   
   var cf=0 # size of returned faces 
   for face in lfaces: cf+=face.len+1
   
   # alloc mem for faces & vertexes
   faces = cast[ptr UncheckedArray[cint]](alloc(cf * sizeof(cint)))
   vertexes = cast[ptr UncheckedArray[float64]](alloc(3 * nvertexes * sizeof(float64)))
   
   for i,p in lvertexes: # vertexes = lvertexes
       vertexes[i*3+0] = p.x
       vertexes[i*3+1] = p.y
       vertexes[i*3+2] = p.z
   
   nfaces=0  # faces = lfaceLen, ixs... linear, must convert to [][]int
   for ixf, face in lfaces: 
       faces[nfaces]=face.len.cint
       nfaces.inc
       
       for ix in face:
            faces[nfaces]=ix.cint
            nfaces.inc
  
proc freeCH*(
    faces     : ptr UncheckedArray[cint],
    vertexes  : ptr UncheckedArray[float64]) {.exportc.}=
    
    dealloc(faces)
    dealloc(vertexes)
