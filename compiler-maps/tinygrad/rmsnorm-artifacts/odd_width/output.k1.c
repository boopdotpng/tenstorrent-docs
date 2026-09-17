
void E_4_127(float* restrict data0_508, float* restrict data1_508, float* restrict data2_4, float* restrict data3_127) {
  for (int Lidx0 = 0; Lidx0 < 4; Lidx0++) {
    float val0 = (*(data2_4+Lidx0));
    for (int Lidx1 = 0; Lidx1 < 127; Lidx1++) {
      int alu0 = ((Lidx0*127)+Lidx1);
      float val1 = (*(data1_508+alu0));
      float val2 = (*(data3_127+Lidx1));
      *(data0_508+alu0) = ((val1/val0)*val2);
    }
  }
}
