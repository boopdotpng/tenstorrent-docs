typedef float float4 __attribute__((aligned(16),ext_vector_type(4)));
void E_4_32_4(float* restrict data0_512, float* restrict data1_512, float* restrict data2_4, float* restrict data3_128) {
  for (int Lidx0 = 0; Lidx0 < 4; Lidx0++) {
    float val0 = (*(data2_4+Lidx0));
    for (int Lidx1 = 0; Lidx1 < 32; Lidx1++) {
      int alu0 = (Lidx1<<2);
      int alu1 = ((Lidx0<<7)+alu0);
      float4 val1 = (*((float4*)((data1_512+alu1))));
      float4 val2 = (*((float4*)((data3_128+alu0))));
      *((float4*)((data0_512+alu1))) = (float4){((val1[0]/val0)*val2[0]),((val1[1]/val0)*val2[1]),((val1[2]/val0)*val2[2]),((val1[3]/val0)*val2[3])};
    }
  }
}
