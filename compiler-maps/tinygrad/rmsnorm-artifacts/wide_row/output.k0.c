typedef float float4 __attribute__((aligned(16),ext_vector_type(4)));
void r_1024_4(float* restrict data0_1, float* restrict data1_4096) {
  float buf0[1];
  *(buf0+0) = 0.0f;
  for (int Ridx0 = 0; Ridx0 < 1024; Ridx0++) {
    float4 val0 = (*((float4*)((data1_4096+(Ridx0<<2)))));
    *(buf0+0) = ((*(buf0+0))+(val0[0]*val0[0])+(val0[1]*val0[1])+(val0[2]*val0[2])+(val0[3]*val0[3]));
  }
  *(data0_1+0) = __builtin_sqrtf((((*(buf0+0))*0.000244140625f)+9.999999747378752e-06f));
}
