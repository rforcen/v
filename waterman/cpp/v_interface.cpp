// c interface

#include "Waterman.h"
#include "QuickHull3D.h"

extern "C" {

void watermanPoly(double radius, int *_nfaces, int *_nvertexes, int **_faces, double **_vertexes) {
  QuickHull3D hull(genPoly(radius));

  auto faces = hull.getFaces();  // faces & vertexes
  auto coords = hull.getScaledVertex();

  *_nfaces = 0;  // count # item in face + len(1)
  for (auto face:faces) {
    *_nfaces += face.size() + 1;
  }
  *_nvertexes = coords.size();

  // alloc faces/vertexes
  *_faces = (int*)malloc(*_nfaces * sizeof(int));
  *_vertexes = (double*)malloc(coords.size() * sizeof(double));

  int iface = 0;  // line up faces
  for (auto face : faces) {
    (*_faces)[iface++] = (int)face.size();
    std::copy(face.begin(), face.end(), (*_faces) + iface);
    iface += face.size();
  }

  // copy vertexes
  std::copy(coords.begin(), coords.end(), *_vertexes);
}
void freeCH(int *_faces, double *_vertexes) {
  free(_faces);
  free(_vertexes);
}
}
