typedef float float4 __attribute__((aligned(16),ext_vector_type(4)));
void E_4(float* restrict data0_4, float* restrict data1_4) {
  float4 val0 = (*((float4*)((data1_4+0))));
  *((float4*)((data0_4+0))) = (float4){(1.0f/__builtin_sqrtf((val0[0]+9.999999747378752e-06f))),(1.0f/__builtin_sqrtf((val0[1]+9.999999747378752e-06f))),(1.0f/__builtin_sqrtf((val0[2]+9.999999747378752e-06f))),(1.0f/__builtin_sqrtf((val0[3]+9.999999747378752e-06f)))};
}
