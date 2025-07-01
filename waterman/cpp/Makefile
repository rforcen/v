# ConvexHull -> libconvexhull.a
sources=Face.cpp FaceList.cpp HalfEdge.cpp Point3d.cpp QuickHull3D.cpp  Vector3d.cpp Vertex.cpp VertexList.cpp Waterman.cpp v_interface.cpp
objs=Face.o FaceList.o HalfEdge.o Point3d.o QuickHull3D.o Vector3d.o Vertex.o VertexList.o Waterman.o v_interface.o
includes=Face.h FaceList.h HalfEdge.h Point3d.h QuickHull3D.h Vector3d.h Vertex.h VertexList.h Waterman.h

CPP=g++
STDVER=-std=c++17

.SILENT: lib 
lib: $(sources) $(includes)
	$(CPP) $(STDVER) -c -O3 $(sources)
	rm -f libwaterman.a
	ar rsc libwaterman.a $(objs)
	rm -f $(objs)
	nm libwaterman.a | grep watermanPoly
	nm libwaterman.a | grep freeCH	

test: $(sources) test.cpp 
	$(CPP)  test.cpp -o test libwaterman.a
	
.SILENT: clean
clean:
	rm *o
