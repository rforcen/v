// float128 c func helper
#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <limits.h>
#include <float.h>
#include <math.h>

typedef unsigned char uc16[16];

typedef struct _F128 { 
    union {
        long double value;
        uc16 data;
    };    
} F128;

// char <-> F128
F128 str2f128(const char *str) {
    long double value;
    char *endptr;
    
    errno = 0;
    value = strtold(str, &endptr);
    F128 ret = (F128){ .value = value };
    return (F128){ .value = value };
}

char* f128_2_str(uc16 data) {
    char *str = (char*)malloc(1024); // must free
    int result = snprintf(str, 1024, "%Le", *(long double*)(data));    

    return str;
}

// converters
void   f128_from_int(int i, uc16 res)     {    *((long double*)res) = (long double)(i);}
void   f128_from_f32(float f, uc16 res)   {    *((long double*)res) = (long double)(f);}
void   f128_from_f64(double d, uc16 res)  {    *((long double*)res) = (long double)(d);}
int    f128_to_int(uc16 data)              {    return (int)(*(long double*)(data));}
float  f128_to_f32(uc16 data)            {    return (float)(*(long double*)(data));}
double f128_to_f64(uc16 data)           {    return (double)(*(long double*)(data));}

// operators

void f128_add(uc16 data1, uc16 data2, uc16 res) {
    *((long double*)res) = *(long double*)(data1) + *(long double*)(data2);
}
void f128_sub(uc16 data1, uc16 data2, uc16 res) {
    *((long double*)res) = *(long double*)(data1) - *(long double*)(data2);
}
void f128_mul(uc16 data1, uc16 data2, uc16 res) {
    *((long double*)res) = *(long double*)(data1) * *(long double*)(data2);
}
void f128_div(uc16 data1, uc16 data2, uc16 res) {
    *((long double*)res) = *(long double*)(data1) / *(long double*)(data2);
}
void f128_neg(uc16 data, uc16 res) {
    *((long double*)res) = -*(long double*)(data);
}
// comp. opers.
bool f128_eq(uc16 data1, uc16 data2) {
    return *(long double*)(data1) == *(long double*)(data2);
}
bool f128_ne(uc16 data1, uc16 data2) {
    return *(long double*)(data1) != *(long double*)(data2);
}
bool f128_lt(uc16 data1, uc16 data2) {
    return *(long double*)(data1) < *(long double*)(data2);
}
bool f128_le(uc16 data1, uc16 data2) {
    return *(long double*)(data1) <= *(long double*)(data2);
}
bool f128_gt(uc16 data1, uc16 data2) {
    return *(long double*)(data1) > *(long double*)(data2);
}
bool f128_ge(uc16 data1, uc16 data2) {
    return *(long double*)(data1) >= *(long double*)(data2);
}
bool f128_is_nan(uc16 data) {
    return isnan(*(long double*)(data));
}
bool f128_is_inf(uc16 data) {
    return isinf(*(long double*)(data));
}
bool f128_is_zero(uc16 data) {
    return *(long double*)(data) == 0.0;
}
bool f128_is_pos(uc16 data) {
    return *(long double*)(data) > 0.0;
}
bool f128_is_neg(uc16 data) {
    return *(long double*)(data) < 0.0;
}
// funcs
void f128_sqrt(uc16 data, uc16 res) {
     *(long double*)res = sqrtl(*(long double*)(data));
}
void f128_sin(uc16 data, uc16 res) {
     *(long double*)res = sinl(*(long double*)(data));
}
void f128_cos(uc16 data, uc16 res) {
     *(long double*)res = cosl(*(long double*)(data));
}
void f128_tan(uc16 data, uc16 res) {
     *(long double*)res = tanl(*(long double*)(data));
}
void f128_asin(uc16 data, uc16 res) {
     *(long double*)res = asinl(*(long double*)(data));
}
void f128_acos(uc16 data, uc16 res) {
     *(long double*)res = acosl(*(long double*)(data));
}
void f128_atan(uc16 data, uc16 res) {
     *(long double*)res = atanl(*(long double*)(data));
}
void f128_atan2(uc16 data1, uc16 data2, uc16 res) {
     *(long double*)res = atan2l(*(long double*)(data1), *(long double*)(data2));
}
void f128_log(uc16 data, uc16 res) {
     *(long double*)res = logl(*(long double*)(data));
}
void f128_log10(uc16 data, uc16 res) {
     *(long double*)res = log10l(*(long double*)(data));
}
void f128_exp(uc16 data, uc16 res) {
     *(long double*)res = expl(*(long double*)(data));
}
void f128_pow(uc16 data1, uc16 data2, uc16 res) {
     *(long double*)res = powl(*(long double*)(data1), *(long double*)(data2));
}
void f128_ceil(uc16 data, uc16 res) {
     *(long double*)res = ceill(*(long double*)(data));
}
void f128_floor(uc16 data, uc16 res) {
     *(long double*)res = floorl(*(long double*)(data));
}
void f128_trunc(uc16 data, uc16 res) {
     *(long double*)res = truncl(*(long double*)(data));
}
void f128_round(uc16 data, uc16 res) {
     *(long double*)res = roundl(*(long double*)(data));
}
void f128_fabs(uc16 data, uc16 res) {
     *(long double*)res = fabsl(*(long double*)(data));
}
void f128_fmod(uc16 data1, uc16 data2, uc16 res) {
     *(long double*)res = fmodl(*(long double*)(data1), *(long double*)(data2));
}
void f128_modf(uc16 data, uc16 res1, uc16 res2) {
     *(long double*)res1 = modfl(*(long double*)(data), (long double*)(res2));
}
void f128_rand(uc16 res) {
    *(long double*)res = rand() / (long double)RAND_MAX;
}
void f128_seed() {
    srand(time(NULL));
}