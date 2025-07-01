/*
 gcc -Wno-discarded-qualifiers  -o tch tch.c libconvexhull_ref.a
*/
#include <stdio.h>
#include <stdlib.h>




void wp() {
	void NimMain();
	void watermanPoly(double radius, int *nfaces, int* nvertexes, int *faces, double *vertexes);
	
	NimMain();
	
	int nfaces=100000, nvertexes=100000;
	int *faces;
	double *vertexes;
	double radius=450;
	
	faces = calloc(100000, sizeof(int));
	vertexes = calloc(100000, sizeof(double));
	
	watermanPoly(radius, &nfaces, &nvertexes, faces, vertexes);
	
	printf("waterman poly rad:%f, nfaces: %d, nvertexes:%d\n", radius, nfaces, nvertexes);
	
	realloc(faces, nfaces*sizeof(int));
	realloc(vertexes, nvertexes * sizeof(double) * 3);
	
	for (int i=0; i<nfaces; i++) printf("%d ", faces[i]);
	for (int i=0; i<nvertexes; i++) printf("(%.1f, %.1f, %.1f), ", vertexes[i*3+0],vertexes[i*3+1],vertexes[i*3+2]);
	
	free(faces);
	free(vertexes);
	
	puts("end");
}
	


int main() {
  wp();
}
