typedef float float4 __attribute__((aligned(16),ext_vector_type(4)));
void E_128_4(float* restrict data0_512, float* restrict data1_512) {
  for (int Lidx0 = 0; Lidx0 < 128; Lidx0++) {
    int alu0 = (Lidx0<<2);
    float4 val0 = (*((float4*)((data1_512+alu0))));
    *((float4*)((data0_512+alu0))) = (float4){(val0[0]*val0[0]),(val0[1]*val0[1]),(val0[2]*val0[2]),(val0[3]*val0[3])};
  }
}
