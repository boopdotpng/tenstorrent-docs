typedef float float4 __attribute__((aligned(16),ext_vector_type(4)));
void E_1024_4(float* restrict data0_4096, float* restrict data1_4096, float* restrict data2_1, float* restrict data3_4096) {
  float val0 = (*(data2_1+0));
  for (int Lidx0 = 0; Lidx0 < 1024; Lidx0++) {
    int alu0 = (Lidx0<<2);
    float4 val1 = (*((float4*)((data1_4096+alu0))));
    float4 val2 = (*((float4*)((data3_4096+alu0))));
    *((float4*)((data0_4096+alu0))) = (float4){((val1[0]/val0)*val2[0]),((val1[1]/val0)*val2[1]),((val1[2]/val0)*val2[2]),((val1[3]/val0)*val2[3])};
  }
}
