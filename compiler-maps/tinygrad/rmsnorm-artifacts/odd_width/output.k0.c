typedef float float4 __attribute__((aligned(16),ext_vector_type(4)));
void r_4_127(float* restrict data0_4, float* restrict data1_508) {
  float buf0[4];
  *(buf0+0) = 0.0f;
  *(buf0+1) = 0.0f;
  *(buf0+2) = 0.0f;
  *(buf0+3) = 0.0f;
  for (int Ridx0 = 0; Ridx0 < 127; Ridx0++) {
    float val0 = (*(data1_508+(Ridx0+127)));
    float val1 = (*(data1_508+(Ridx0+254)));
    float val2 = (*(data1_508+(Ridx0+381)));
    float val3 = (*(data1_508+Ridx0));
    *(buf0+0) = ((*(buf0+0))+(val3*val3));
    *(buf0+1) = ((*(buf0+1))+(val0*val0));
    *(buf0+2) = ((*(buf0+2))+(val1*val1));
    *(buf0+3) = ((*(buf0+3))+(val2*val2));
  }
  *((float4*)((data0_4+0))) = (float4){__builtin_sqrtf((((*(buf0+0))*0.007874015718698502f)+9.999999747378752e-06f)),__builtin_sqrtf((((*(buf0+1))*0.007874015718698502f)+9.999999747378752e-06f)),__builtin_sqrtf((((*(buf0+2))*0.007874015718698502f)+9.999999747378752e-06f)),__builtin_sqrtf((((*(buf0+3))*0.007874015718698502f)+9.999999747378752e-06f))};
}
