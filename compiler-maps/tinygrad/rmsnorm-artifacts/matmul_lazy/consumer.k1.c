typedef float float4 __attribute__((aligned(16),ext_vector_type(4)));
void r_4_32_32_4(float* restrict data0_128, float* restrict data1_512, float* restrict data2_4, float* restrict data3_128, float* restrict data4_4096) {
  float buf0[1];
  for (int Lidx1 = 0; Lidx1 < 4; Lidx1++) {
    float val0 = (*(data2_4+Lidx1));
    for (int Lidx2 = 0; Lidx2 < 32; Lidx2++) {
      *(buf0+0) = 0.0f;
      for (int Ridx0 = 0; Ridx0 < 32; Ridx0++) {
        int alu1 = ((Ridx0<<7)+Lidx2);
        float val1 = (*(data4_4096+(alu1+32)));
        float val2 = (*(data4_4096+(alu1+64)));
        float val3 = (*(data4_4096+(alu1+96)));
        float val4 = (*(data4_4096+alu1));
        int alu2 = (Ridx0<<2);
        float4 val5 = (*((float4*)((data1_512+(alu2+(Lidx1<<7))))));
        float4 val6 = (*((float4*)((data3_128+alu2))));
        *(buf0+0) = ((*(buf0+0))+(val5[0]*val6[0]*val4)+(val5[1]*val6[1]*val1)+(val5[2]*val6[2]*val2)+(val5[3]*val6[3]*val3));
      }
      *(data0_128+((Lidx1<<5)+Lidx2)) = ((*(buf0+0))/val0);
    }
  }
}
