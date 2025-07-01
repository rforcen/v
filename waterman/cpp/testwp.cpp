#include "Waterman.h"
#include <stdio.h>

int main() {
    auto p=genPoly(10);
    printf("%ld\n",p.size());

    int i=0;
    for (auto v:p) {
        printf("%.0f ",v);
        i++;
        if (i%3==0) printf("\n");
    }
    return 0;    
}
