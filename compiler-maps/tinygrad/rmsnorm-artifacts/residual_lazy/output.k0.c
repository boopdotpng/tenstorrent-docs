typedef float float4 __attribute__((aligned(16),ext_vector_type(4)));
void r_4_32_4(float* restrict data0_4, float* restrict data1_512, float* restrict data2_512) {
  float buf0[1];
  for (int Lidx1 = 0; Lidx1 < 4; Lidx1++) {
    *(buf0+0) = 0.0f;
    for (int Ridx0 = 0; Ridx0 < 32; Ridx0++) {
      int alu1 = ((Ridx0<<2)+(Lidx1<<7));
      float4 val0 = (*((float4*)((data1_512+alu1))));
      float4 val1 = (*((float4*)((data2_512+alu1))));
      float alu2 = (val0[0]+val1[0]);
      float alu3 = (val0[1]+val1[1]);
      float alu4 = (val0[2]+val1[2]);
      float alu5 = (val0[3]+val1[3]);
      *(buf0+0) = ((*(buf0+0))+(alu2*alu2)+(alu3*alu3)+(alu4*alu4)+(alu5*alu5));
    }
    *(data0_4+Lidx1) = __builtin_sqrtf((((*(buf0+0))*0.0078125f)+9.999999747378752e-06f));
  }
}
