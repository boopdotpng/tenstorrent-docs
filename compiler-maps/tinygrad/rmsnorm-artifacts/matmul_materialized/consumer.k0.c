typedef float float4 __attribute__((aligned(16),ext_vector_type(4)));
void r_4_32_32_4(float* restrict data0_128, float* restrict data1_512, float* restrict data2_4096) {
  float buf0[1];
  for (int Lidx1 = 0; Lidx1 < 4; Lidx1++) {
    for (int Lidx2 = 0; Lidx2 < 32; Lidx2++) {
      *(buf0+0) = 0.0f;
      for (int Ridx0 = 0; Ridx0 < 32; Ridx0++) {
        int alu1 = ((Ridx0<<7)+Lidx2);
        float val0 = (*(data2_4096+(alu1+32)));
        float val1 = (*(data2_4096+(alu1+64)));
        float val2 = (*(data2_4096+(alu1+96)));
        float val3 = (*(data2_4096+alu1));
        float4 val4 = (*((float4*)((data1_512+((Ridx0<<2)+(Lidx1<<7))))));
        *(buf0+0) = ((*(buf0+0))+(val4[0]*val3)+(val4[1]*val0)+(val4[2]*val1)+(val4[3]*val2));
      }
      *(data0_128+((Lidx1<<5)+Lidx2)) = (*(buf0+0));
    }
  }
}
