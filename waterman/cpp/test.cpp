#include "QuickHull3D.h"
#include "Waterman.h"
#include <cstdio>

// int t01() {
//   WatermanPoly wp;

//   int i = 0;
//   auto points = wp.genPoly(10);
//   puts("wp:");
//   for (auto v : points)
//     printf("%.1f%c", v, (i++ % 3 == 2) ? '\n' : ' ');

//   puts("faces:");
//   QuickHull3D qh(points);
//   auto verts = qh.getVertices();
//   for (auto &faces : qh.getFaces()) {
//     for (auto i : faces) {
//       printf("%d ", i);
//       if (i >= verts.size()) {
//         puts("face index out of range");
//         exit(1);
//       }
//     }
//     printf("\n");
//   }
//   puts("vertexes");
//   i=0;
//   for (auto v:verts)
// 	printf("%d: %f %f %f\n", i++, v->x, v->y, v->z);

//   return 0;
// }

void t02() {
  
  int i = 0;
  auto points =  genPoly(100);
  printf("%ld\n",points.size()/3);

    QuickHull3D qh(points);
  auto verts = qh.getVertices();
  auto faces = qh.getFaces();
  printf("faces:%ld\n",faces.size());
  printf("verts:%ld\n",verts.size());  
}

int main() { // g++ test.cpp -o test -lwaterman -L. && ./test
  t02();
}