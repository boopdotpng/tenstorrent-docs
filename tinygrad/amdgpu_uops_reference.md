# Tinygrad UOps Reference for TT Renderer

Generated: `2026-02-28 14:50:57` | Device: `AMD` | Commit: `e3003631f`

## How to read

Each line: `IDX OP DTYPE [src_indices] =arg`

These are **linearized** UOps — the final form `render()` receives.
All inputs are pre-realized empty tensors to show clean load/compute/store patterns.

| Category | Ops |
|----------|-----|
| Structure | PARAM SPECIAL RANGE END BARRIER IF ENDIF DEFINE_LOCAL DEFINE_REG SINK |
| Memory | INDEX LOAD STORE |
| ALU | ADD MUL SUB NEG SHL SHR AND OR XOR CMPLT CMPNE CMPEQ IDIV MOD MAX WHERE MULACC |
| Math | EXP2 LOG2 SIN SQRT RECIPROCAL TRUNC |
| Type | CAST BITCAST VECTORIZE GEP CONST |
| TC | WMMA |

## Elementwise binary

**add** — `a + b`
#### `E_16_4`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: PARAM=3 SINK=1 SPECIAL=1
compute:   ADD=4 CAST=3 CONST=2 GEP=8 INDEX=3 LOAD=2 SHL=1 STORE=1 VECTORIZE=1
```
    0 PARAM              float.ptr(64)                                   =0
    1 PARAM              float.ptr(64)                                   =1
    2 PARAM              float.ptr(64)                                   =2
    3 CONST              int                                             =16
    4 SPECIAL            int                          [3]                'lidx0'
    5 CONST              int                                             =2
    6 SHL                int                          [4,5]             
    7 INDEX              float.ptr(64)                [1,6]             
    8 CAST               float.vec(4).ptr(64)         [7]               
    9 LOAD               float.vec(4)                 [8]               
   10 INDEX              float.ptr(64)                [2,6]             
   11 CAST               float.vec(4).ptr(64)         [10]              
   12 LOAD               float.vec(4)                 [11]              
   13 GEP                float                        [9]                (0,)
   14 GEP                float                        [12]               (0,)
   15 GEP                float                        [9]                (1,)
   16 GEP                float                        [12]               (1,)
   17 GEP                float                        [9]                (2,)
   18 GEP                float                        [12]               (2,)
   19 GEP                float                        [9]                (3,)
   20 GEP                float                        [12]               (3,)
   21 ADD                float                        [13,14]           
   22 ADD                float                        [15,16]           
   23 ADD                float                        [17,18]           
   24 ADD                float                        [19,20]           
   25 VECTORIZE          float.vec(4)                 [21,22,23,24]     
   26 INDEX              float.ptr(64)                [0,6]             
   27 CAST               float.vec(4).ptr(64)         [26]              
   28 STORE              void                         [27,25]           
   29 SINK               void                         [28]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m16\x1b[0m\x1b[90m_\x1b[0m\x1b[33m4\x1b
```

**mul** — `a * b`
#### `E_16_4n1`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: PARAM=3 SINK=1 SPECIAL=1
compute:   CAST=3 CONST=2 GEP=8 INDEX=3 LOAD=2 MUL=4 SHL=1 STORE=1 VECTORIZE=1
```
    0 PARAM              float.ptr(64)                                   =0
    1 PARAM              float.ptr(64)                                   =1
    2 PARAM              float.ptr(64)                                   =2
    3 CONST              int                                             =16
    4 SPECIAL            int                          [3]                'lidx0'
    5 CONST              int                                             =2
    6 SHL                int                          [4,5]             
    7 INDEX              float.ptr(64)                [1,6]             
    8 CAST               float.vec(4).ptr(64)         [7]               
    9 LOAD               float.vec(4)                 [8]               
   10 INDEX              float.ptr(64)                [2,6]             
   11 CAST               float.vec(4).ptr(64)         [10]              
   12 LOAD               float.vec(4)                 [11]              
   13 GEP                float                        [9]                (0,)
   14 GEP                float                        [12]               (0,)
   15 GEP                float                        [9]                (1,)
   16 GEP                float                        [12]               (1,)
   17 GEP                float                        [9]                (2,)
   18 GEP                float                        [12]               (2,)
   19 GEP                float                        [9]                (3,)
   20 GEP                float                        [12]               (3,)
   21 MUL                float                        [13,14]           
   22 MUL                float                        [15,16]           
   23 MUL                float                        [17,18]           
   24 MUL                float                        [19,20]           
   25 VECTORIZE          float.vec(4)                 [21,22,23,24]     
   26 INDEX              float.ptr(64)                [0,6]             
   27 CAST               float.vec(4).ptr(64)         [26]              
   28 STORE              void                         [27,25]           
   29 SINK               void                         [28]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m16\x1b[0m\x1b[90m_\x1b[0m\x1b[33m4\x1b
```

**sub** — `a - b`
#### `E_16_4n2`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: PARAM=3 SINK=1 SPECIAL=1
compute:   CAST=3 CONST=2 GEP=8 INDEX=3 LOAD=2 SHL=1 STORE=1 SUB=4 VECTORIZE=1
```
    0 PARAM              float.ptr(64)                                   =0
    1 PARAM              float.ptr(64)                                   =1
    2 PARAM              float.ptr(64)                                   =2
    3 CONST              int                                             =16
    4 SPECIAL            int                          [3]                'lidx0'
    5 CONST              int                                             =2
    6 SHL                int                          [4,5]             
    7 INDEX              float.ptr(64)                [1,6]             
    8 CAST               float.vec(4).ptr(64)         [7]               
    9 LOAD               float.vec(4)                 [8]               
   10 INDEX              float.ptr(64)                [2,6]             
   11 CAST               float.vec(4).ptr(64)         [10]              
   12 LOAD               float.vec(4)                 [11]              
   13 GEP                float                        [9]                (0,)
   14 GEP                float                        [12]               (0,)
   15 GEP                float                        [9]                (1,)
   16 GEP                float                        [12]               (1,)
   17 GEP                float                        [9]                (2,)
   18 GEP                float                        [12]               (2,)
   19 GEP                float                        [9]                (3,)
   20 GEP                float                        [12]               (3,)
   21 SUB                float                        [13,14]           
   22 SUB                float                        [15,16]           
   23 SUB                float                        [17,18]           
   24 SUB                float                        [19,20]           
   25 VECTORIZE          float.vec(4)                 [21,22,23,24]     
   26 INDEX              float.ptr(64)                [0,6]             
   27 CAST               float.vec(4).ptr(64)         [26]              
   28 STORE              void                         [27,25]           
   29 SINK               void                         [28]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m16\x1b[0m\x1b[90m_\x1b[0m\x1b[33m4\x1b
```

**div** — `a / b`
#### `E_16_4n3`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: PARAM=3 SINK=1 SPECIAL=1
compute:   CAST=3 CONST=2 GEP=8 INDEX=3 LOAD=2 MUL=4 RECIPROCAL=4 SHL=1 STORE=1 VECTORIZE=1
```
    0 PARAM              float.ptr(64)                                   =0
    1 PARAM              float.ptr(64)                                   =1
    2 PARAM              float.ptr(64)                                   =2
    3 CONST              int                                             =16
    4 SPECIAL            int                          [3]                'lidx0'
    5 CONST              int                                             =2
    6 SHL                int                          [4,5]             
    7 INDEX              float.ptr(64)                [1,6]             
    8 CAST               float.vec(4).ptr(64)         [7]               
    9 LOAD               float.vec(4)                 [8]               
   10 INDEX              float.ptr(64)                [2,6]             
   11 CAST               float.vec(4).ptr(64)         [10]              
   12 LOAD               float.vec(4)                 [11]              
   13 GEP                float                        [9]                (0,)
   14 GEP                float                        [12]               (0,)
   15 GEP                float                        [9]                (1,)
   16 GEP                float                        [12]               (1,)
   17 GEP                float                        [9]                (2,)
   18 GEP                float                        [12]               (2,)
   19 GEP                float                        [9]                (3,)
   20 GEP                float                        [12]               (3,)
   21 RECIPROCAL         float                        [14]              
   22 RECIPROCAL         float                        [16]              
   23 RECIPROCAL         float                        [18]              
   24 RECIPROCAL         float                        [20]              
   25 MUL                float                        [13,21]           
   26 MUL                float                        [15,22]           
   27 MUL                float                        [17,23]           
   28 MUL                float                        [19,24]           
   29 VECTORIZE          float.vec(4)                 [25,26,27,28]     
   30 INDEX              float.ptr(64)                [0,6]             
   31 CAST               float.vec(4).ptr(64)         [30]              
   32 STORE              void                         [31,29]           
   33 SINK               void                         [32]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m16\x1b[0m\x1b[90m_\x1b[0m\x1b[33m4\x1b
```

**max** — `maximum(a, b)`
#### `E_16_4n4`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: PARAM=3 SINK=1 SPECIAL=1
compute:   CAST=3 CMPLT=4 CONST=2 GEP=8 INDEX=3 LOAD=2 SHL=1 STORE=1 VECTORIZE=1 WHERE=4
```
    0 PARAM              float.ptr(64)                                   =0
    1 PARAM              float.ptr(64)                                   =1
    2 PARAM              float.ptr(64)                                   =2
    3 CONST              int                                             =16
    4 SPECIAL            int                          [3]                'lidx0'
    5 CONST              int                                             =2
    6 SHL                int                          [4,5]             
    7 INDEX              float.ptr(64)                [1,6]             
    8 CAST               float.vec(4).ptr(64)         [7]               
    9 LOAD               float.vec(4)                 [8]               
   10 INDEX              float.ptr(64)                [2,6]             
   11 CAST               float.vec(4).ptr(64)         [10]              
   12 LOAD               float.vec(4)                 [11]              
   13 GEP                float                        [9]                (0,)
   14 GEP                float                        [12]               (0,)
   15 GEP                float                        [9]                (1,)
   16 GEP                float                        [12]               (1,)
   17 GEP                float                        [9]                (2,)
   18 GEP                float                        [12]               (2,)
   19 GEP                float                        [9]                (3,)
   20 GEP                float                        [12]               (3,)
   21 CMPLT              bool                         [13,14]           
   22 CMPLT              bool                         [15,16]           
   23 CMPLT              bool                         [17,18]           
   24 CMPLT              bool                         [19,20]           
   25 WHERE              float                        [21,14,13]        
   26 WHERE              float                        [22,16,15]        
   27 WHERE              float                        [23,18,17]        
   28 WHERE              float                        [24,20,19]        
   29 VECTORIZE          float.vec(4)                 [25,26,27,28]     
   30 INDEX              float.ptr(64)                [0,6]             
   31 CAST               float.vec(4).ptr(64)         [30]              
   32 STORE              void                         [31,29]           
   33 SINK               void                         [32]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m16\x1b[0m\x1b[90m_\x1b[0m\x1b[33m4\x1b
```

**cmplt** — `(a < b).float()`
#### `E_16_4n5`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: PARAM=3 SINK=1 SPECIAL=1
compute:   CAST=7 CMPLT=4 CONST=2 GEP=8 INDEX=3 LOAD=2 SHL=1 STORE=1 VECTORIZE=1
```
    0 PARAM              float.ptr(64)                                   =0
    1 PARAM              float.ptr(64)                                   =1
    2 PARAM              float.ptr(64)                                   =2
    3 CONST              int                                             =16
    4 SPECIAL            int                          [3]                'lidx0'
    5 CONST              int                                             =2
    6 SHL                int                          [4,5]             
    7 INDEX              float.ptr(64)                [1,6]             
    8 CAST               float.vec(4).ptr(64)         [7]               
    9 LOAD               float.vec(4)                 [8]               
   10 INDEX              float.ptr(64)                [2,6]             
   11 CAST               float.vec(4).ptr(64)         [10]              
   12 LOAD               float.vec(4)                 [11]              
   13 GEP                float                        [9]                (0,)
   14 GEP                float                        [12]               (0,)
   15 GEP                float                        [9]                (1,)
   16 GEP                float                        [12]               (1,)
   17 GEP                float                        [9]                (2,)
   18 GEP                float                        [12]               (2,)
   19 GEP                float                        [9]                (3,)
   20 GEP                float                        [12]               (3,)
   21 CMPLT              bool                         [13,14]           
   22 CAST               float                        [21]              
   23 CMPLT              bool                         [15,16]           
   24 CAST               float                        [23]              
   25 CMPLT              bool                         [17,18]           
   26 CAST               float                        [25]              
   27 CMPLT              bool                         [19,20]           
   28 CAST               float                        [27]              
   29 VECTORIZE          float.vec(4)                 [22,24,26,28]     
   30 INDEX              float.ptr(64)                [0,6]             
   31 CAST               float.vec(4).ptr(64)         [30]              
   32 STORE              void                         [31,29]           
   33 SINK               void                         [32]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m16\x1b[0m\x1b[90m_\x1b[0m\x1b[33m4\x1b
```

---

## Elementwise unary

**neg** — `-a`
#### `E_16_4n6`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: PARAM=2 SINK=1 SPECIAL=1
compute:   CAST=2 CONST=2 GEP=4 INDEX=2 LOAD=1 NEG=4 SHL=1 STORE=1 VECTORIZE=1
```
    0 PARAM              float.ptr(64)                                   =0
    1 PARAM              float.ptr(64)                                   =1
    2 CONST              int                                             =16
    3 SPECIAL            int                          [2]                'lidx0'
    4 CONST              int                                             =2
    5 SHL                int                          [3,4]             
    6 INDEX              float.ptr(64)                [1,5]             
    7 CAST               float.vec(4).ptr(64)         [6]               
    8 LOAD               float.vec(4)                 [7]               
    9 GEP                float                        [8]                (0,)
   10 GEP                float                        [8]                (1,)
   11 GEP                float                        [8]                (2,)
   12 GEP                float                        [8]                (3,)
   13 NEG                float                        [9]               
   14 NEG                float                        [10]              
   15 NEG                float                        [11]              
   16 NEG                float                        [12]              
   17 VECTORIZE          float.vec(4)                 [13,14,15,16]     
   18 INDEX              float.ptr(64)                [0,5]             
   19 CAST               float.vec(4).ptr(64)         [18]              
   20 STORE              void                         [19,17]           
   21 SINK               void                         [20]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m16\x1b[0m\x1b[90m_\x1b[0m\x1b[33m4\x1b
```

**exp2** — `a.exp2()`
#### `E_16_4n7`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: PARAM=2 SINK=1 SPECIAL=1
compute:   CAST=2 CONST=2 EXP2=4 GEP=4 INDEX=2 LOAD=1 SHL=1 STORE=1 VECTORIZE=1
```
    0 PARAM              float.ptr(64)                                   =0
    1 PARAM              float.ptr(64)                                   =1
    2 CONST              int                                             =16
    3 SPECIAL            int                          [2]                'lidx0'
    4 CONST              int                                             =2
    5 SHL                int                          [3,4]             
    6 INDEX              float.ptr(64)                [1,5]             
    7 CAST               float.vec(4).ptr(64)         [6]               
    8 LOAD               float.vec(4)                 [7]               
    9 GEP                float                        [8]                (0,)
   10 GEP                float                        [8]                (1,)
   11 GEP                float                        [8]                (2,)
   12 GEP                float                        [8]                (3,)
   13 EXP2               float                        [9]               
   14 EXP2               float                        [10]              
   15 EXP2               float                        [11]              
   16 EXP2               float                        [12]              
   17 VECTORIZE          float.vec(4)                 [13,14,15,16]     
   18 INDEX              float.ptr(64)                [0,5]             
   19 CAST               float.vec(4).ptr(64)         [18]              
   20 STORE              void                         [19,17]           
   21 SINK               void                         [20]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m16\x1b[0m\x1b[90m_\x1b[0m\x1b[33m4\x1b
```

**log2** — `a.log2()`
#### `E_16_4n8`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: PARAM=2 SINK=1 SPECIAL=1
compute:   CAST=2 CONST=2 GEP=4 INDEX=2 LOAD=1 LOG2=4 SHL=1 STORE=1 VECTORIZE=1
```
    0 PARAM              float.ptr(64)                                   =0
    1 PARAM              float.ptr(64)                                   =1
    2 CONST              int                                             =16
    3 SPECIAL            int                          [2]                'lidx0'
    4 CONST              int                                             =2
    5 SHL                int                          [3,4]             
    6 INDEX              float.ptr(64)                [1,5]             
    7 CAST               float.vec(4).ptr(64)         [6]               
    8 LOAD               float.vec(4)                 [7]               
    9 GEP                float                        [8]                (0,)
   10 GEP                float                        [8]                (1,)
   11 GEP                float                        [8]                (2,)
   12 GEP                float                        [8]                (3,)
   13 LOG2               float                        [9]               
   14 LOG2               float                        [10]              
   15 LOG2               float                        [11]              
   16 LOG2               float                        [12]              
   17 VECTORIZE          float.vec(4)                 [13,14,15,16]     
   18 INDEX              float.ptr(64)                [0,5]             
   19 CAST               float.vec(4).ptr(64)         [18]              
   20 STORE              void                         [19,17]           
   21 SINK               void                         [20]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m16\x1b[0m\x1b[90m_\x1b[0m\x1b[33m4\x1b
```

**sin** — `a.sin()`
#### `E_16_4n9`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: PARAM=2 SINK=1 SPECIAL=1
compute:   CAST=2 CONST=2 GEP=4 INDEX=2 LOAD=1 SHL=1 SIN=4 STORE=1 VECTORIZE=1
```
    0 PARAM              float.ptr(64)                                   =0
    1 PARAM              float.ptr(64)                                   =1
    2 CONST              int                                             =16
    3 SPECIAL            int                          [2]                'lidx0'
    4 CONST              int                                             =2
    5 SHL                int                          [3,4]             
    6 INDEX              float.ptr(64)                [1,5]             
    7 CAST               float.vec(4).ptr(64)         [6]               
    8 LOAD               float.vec(4)                 [7]               
    9 GEP                float                        [8]                (0,)
   10 GEP                float                        [8]                (1,)
   11 GEP                float                        [8]                (2,)
   12 GEP                float                        [8]                (3,)
   13 SIN                float                        [9]               
   14 SIN                float                        [10]              
   15 SIN                float                        [11]              
   16 SIN                float                        [12]              
   17 VECTORIZE          float.vec(4)                 [13,14,15,16]     
   18 INDEX              float.ptr(64)                [0,5]             
   19 CAST               float.vec(4).ptr(64)         [18]              
   20 STORE              void                         [19,17]           
   21 SINK               void                         [20]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m16\x1b[0m\x1b[90m_\x1b[0m\x1b[33m4\x1b
```

**sqrt** — `a.sqrt()`
#### `E_16_4n10`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: PARAM=2 SINK=1 SPECIAL=1
compute:   CAST=2 CONST=2 GEP=4 INDEX=2 LOAD=1 SHL=1 SQRT=4 STORE=1 VECTORIZE=1
```
    0 PARAM              float.ptr(64)                                   =0
    1 PARAM              float.ptr(64)                                   =1
    2 CONST              int                                             =16
    3 SPECIAL            int                          [2]                'lidx0'
    4 CONST              int                                             =2
    5 SHL                int                          [3,4]             
    6 INDEX              float.ptr(64)                [1,5]             
    7 CAST               float.vec(4).ptr(64)         [6]               
    8 LOAD               float.vec(4)                 [7]               
    9 GEP                float                        [8]                (0,)
   10 GEP                float                        [8]                (1,)
   11 GEP                float                        [8]                (2,)
   12 GEP                float                        [8]                (3,)
   13 SQRT               float                        [9]               
   14 SQRT               float                        [10]              
   15 SQRT               float                        [11]              
   16 SQRT               float                        [12]              
   17 VECTORIZE          float.vec(4)                 [13,14,15,16]     
   18 INDEX              float.ptr(64)                [0,5]             
   19 CAST               float.vec(4).ptr(64)         [18]              
   20 STORE              void                         [19,17]           
   21 SINK               void                         [20]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m16\x1b[0m\x1b[90m_\x1b[0m\x1b[33m4\x1b
```

**reciprocal** — `a.reciprocal()`
#### `E_16_4n11`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: PARAM=2 SINK=1 SPECIAL=1
compute:   CAST=2 CONST=2 GEP=4 INDEX=2 LOAD=1 RECIPROCAL=4 SHL=1 STORE=1 VECTORIZE=1
```
    0 PARAM              float.ptr(64)                                   =0
    1 PARAM              float.ptr(64)                                   =1
    2 CONST              int                                             =16
    3 SPECIAL            int                          [2]                'lidx0'
    4 CONST              int                                             =2
    5 SHL                int                          [3,4]             
    6 INDEX              float.ptr(64)                [1,5]             
    7 CAST               float.vec(4).ptr(64)         [6]               
    8 LOAD               float.vec(4)                 [7]               
    9 GEP                float                        [8]                (0,)
   10 GEP                float                        [8]                (1,)
   11 GEP                float                        [8]                (2,)
   12 GEP                float                        [8]                (3,)
   13 RECIPROCAL         float                        [9]               
   14 RECIPROCAL         float                        [10]              
   15 RECIPROCAL         float                        [11]              
   16 RECIPROCAL         float                        [12]              
   17 VECTORIZE          float.vec(4)                 [13,14,15,16]     
   18 INDEX              float.ptr(64)                [0,5]             
   19 CAST               float.vec(4).ptr(64)         [18]              
   20 STORE              void                         [19,17]           
   21 SINK               void                         [20]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m16\x1b[0m\x1b[90m_\x1b[0m\x1b[33m4\x1b
```

---

## Elementwise ternary

**where** — `cond.where(a, b)`
#### `E_16_4n12`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: PARAM=5 SINK=1 SPECIAL=1
compute:   CAST=5 CMPLT=4 CONST=2 GEP=16 INDEX=5 LOAD=4 SHL=1 STORE=1 VECTORIZE=1 WHERE=4
```
    0 PARAM              float.ptr(64)                                   =0
    1 PARAM              float.ptr(64)                                   =1
    2 PARAM              float.ptr(64)                                   =2
    3 PARAM              float.ptr(64)                                   =3
    4 PARAM              float.ptr(64)                                   =4
    5 CONST              int                                             =16
    6 SPECIAL            int                          [5]                'lidx0'
    7 CONST              int                                             =2
    8 SHL                int                          [6,7]             
    9 INDEX              float.ptr(64)                [1,8]             
   10 CAST               float.vec(4).ptr(64)         [9]               
   11 LOAD               float.vec(4)                 [10]              
   12 INDEX              float.ptr(64)                [2,8]             
   13 CAST               float.vec(4).ptr(64)         [12]              
   14 LOAD               float.vec(4)                 [13]              
   15 INDEX              float.ptr(64)                [3,8]             
   16 CAST               float.vec(4).ptr(64)         [15]              
   17 LOAD               float.vec(4)                 [16]              
   18 INDEX              float.ptr(64)                [4,8]             
   19 CAST               float.vec(4).ptr(64)         [18]              
   20 LOAD               float.vec(4)                 [19]              
   21 GEP                float                        [11]               (0,)
   22 GEP                float                        [14]               (0,)
   23 GEP                float                        [17]               (0,)
   24 GEP                float                        [20]               (0,)
   25 GEP                float                        [11]               (1,)
   26 GEP                float                        [14]               (1,)
   27 GEP                float                        [17]               (1,)
   28 GEP                float                        [20]               (1,)
   29 GEP                float                        [11]               (2,)
   30 GEP                float                        [14]               (2,)
   31 GEP                float                        [17]               (2,)
   32 GEP                float                        [20]               (2,)
   33 GEP                float                        [11]               (3,)
   34 GEP                float                        [14]               (3,)
   35 GEP                float                        [17]               (3,)
   36 GEP                float                        [20]               (3,)
   37 CMPLT              bool                         [21,22]           
   38 CMPLT              bool                         [25,26]           
   39 CMPLT              bool                         [29,30]           
   40 CMPLT              bool                         [33,34]           
   41 WHERE              float                        [37,23,24]        
   42 WHERE              float                        [38,27,28]        
   43 WHERE              float                        [39,31,32]        
   44 WHERE              float                        [40,35,36]        
   45 VECTORIZE          float.vec(4)                 [41,42,43,44]     
   46 INDEX              float.ptr(64)                [0,8]             
   47 CAST               float.vec(4).ptr(64)         [46]              
   48 STORE              void                         [47,45]           
   49 SINK               void                         [48]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m16\x1b[0m\x1b[90m_\x1b[0m\x1b[33m4\x1b
```

---

## Reduce

**sum_1d** — `a.sum()`
#### `r_16_16`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: AFTER=5 BARRIER=1 DEFINE_LOCAL=1 DEFINE_REG=2 END=2 ENDIF=1 IF=1 PARAM=2 RANGE=2 SINK=1 SPECIAL=1
compute:   ADD=3 CMPEQ=1 CONST=4 INDEX=10 LOAD=6 SHL=1 STORE=6
```
    0 PARAM              float.ptr(1)                                    =0
    1 PARAM              float.ptr(256)                                  =1
    2 DEFINE_LOCAL       float.ptr(16, AddrSpace.LOCAL)                    =0
    3 DEFINE_REG         float.ptr(1, AddrSpace.REG)                     =0
    4 DEFINE_REG         float.ptr(1, AddrSpace.REG)                     =1
    5 CONST              int                                             =16
    6 SPECIAL            int                          [5]                'lidx0'
    7 CONST              int                                             =0
    8 INDEX              float.ptr(1, AddrSpace.REG)  [3,7]             
    9 CONST              int                                             =4
   10 SHL                int                          [6,9]             
   11 CONST              float                                           =0.0
   12 STORE              void                         [8,11]            
   13 RANGE              int                          [5]                (0, AxisType.REDUCE)
   14 AFTER              float.ptr(1, AddrSpace.REG)  [3,12,13]         
   15 INDEX              float.ptr(1, AddrSpace.REG)  [14,7]            
   16 LOAD               float                        [15]              
   17 ADD                int                          [10,13]           
   18 INDEX              float.ptr(256)               [1,17]            
   19 LOAD               float                        [18]              
   20 ADD                float                        [16,19]           
   21 STORE              void                         [8,20]            
   22 END                void                         [21,13]           
   23 AFTER              float.ptr(1, AddrSpace.REG)  [3,22]            
   24 INDEX              float.ptr(1, AddrSpace.REG)  [23,7]            
   25 LOAD               float                        [24]              
   26 INDEX              float.ptr(16, AddrSpace.LOCAL) [2,6]             
   27 STORE              void                         [26,25]           
   28 BARRIER            void                         [27]              
   29 AFTER              float.ptr(16, AddrSpace.LOCAL) [2,28]            
   30 INDEX              float.ptr(1, AddrSpace.REG)  [4,7]             
   31 STORE              void                         [30,11]           
   32 RANGE              int                          [5,22]             (101, AxisType.REDUCE)
   33 AFTER              float.ptr(1, AddrSpace.REG)  [4,31,32]         
   34 INDEX              float.ptr(1, AddrSpace.REG)  [33,7]            
   35 LOAD               float                        [34]              
   36 INDEX              float.ptr(16, AddrSpace.LOCAL) [29,32]           
   37 LOAD               float                        [36]              
   38 ADD                float                        [35,37]           
   39 STORE              void                         [30,38]           
   40 END                void                         [39,32]           
   41 AFTER              float.ptr(1, AddrSpace.REG)  [4,40]            
   42 INDEX              float.ptr(1, AddrSpace.REG)  [41,7]            
   43 LOAD               float                        [42]              
   44 CMPEQ              bool                         [6,7]             
   45 INDEX              float.ptr(1)                 [0,7,44]          
   46 IF                 void                         [44,45]           
   47 STORE              void                         [45,43]           
   48 ENDIF              void                         [46]              
   49 SINK               void                         [47]               KernelInfo(name='r\x1b[90m_\x1b[0m\x1b[91m16\x1b[0m\x1b[90m_\x1b[0m\x1b[31m16\x1
```

**sum_axis0** — `a.sum(axis=0)`
#### `r_16_16n1`  gs=[16, 1, 1] ls=[16, 1, 1]
structure: AFTER=3 BARRIER=1 DEFINE_LOCAL=1 DEFINE_REG=1 END=1 ENDIF=1 IF=1 PARAM=2 RANGE=1 SINK=1 SPECIAL=2
compute:   ADD=2 CMPEQ=1 CONST=4 INDEX=7 LOAD=4 SHL=1 STORE=4
```
    0 PARAM              float.ptr(16)                                   =0
    1 PARAM              float.ptr(256)                                  =1
    2 DEFINE_LOCAL       float.ptr(16, AddrSpace.LOCAL)                    =0
    3 DEFINE_REG         float.ptr(1, AddrSpace.REG)                     =0
    4 CONST              int                                             =16
    5 SPECIAL            int                          [4]                'gidx0'
    6 SPECIAL            int                          [4]                'lidx0'
    7 CONST              int                                             =4
    8 SHL                int                          [6,7]             
    9 ADD                int                          [5,8]             
   10 INDEX              float.ptr(256)               [1,9]             
   11 LOAD               float                        [10]              
   12 INDEX              float.ptr(16, AddrSpace.LOCAL) [2,6]             
   13 STORE              void                         [12,11]           
   14 BARRIER            void                         [13]              
   15 AFTER              float.ptr(16, AddrSpace.LOCAL) [2,14]            
   16 CONST              int                                             =0
   17 INDEX              float.ptr(1, AddrSpace.REG)  [3,16]            
   18 CONST              float                                           =0.0
   19 STORE              void                         [17,18]           
   20 RANGE              int                          [4]                (102, AxisType.REDUCE)
   21 AFTER              float.ptr(1, AddrSpace.REG)  [3,19,20]         
   22 INDEX              float.ptr(1, AddrSpace.REG)  [21,16]           
   23 LOAD               float                        [22]              
   24 INDEX              float.ptr(16, AddrSpace.LOCAL) [15,20]           
   25 LOAD               float                        [24]              
   26 ADD                float                        [23,25]           
   27 STORE              void                         [17,26]           
   28 END                void                         [27,20]           
   29 AFTER              float.ptr(1, AddrSpace.REG)  [3,28]            
   30 INDEX              float.ptr(1, AddrSpace.REG)  [29,16]           
   31 LOAD               float                        [30]              
   32 CMPEQ              bool                         [6,16]            
   33 INDEX              float.ptr(16)                [0,5,32]          
   34 IF                 void                         [32,33]           
   35 STORE              void                         [33,31]           
   36 ENDIF              void                         [34]              
   37 SINK               void                         [35]               KernelInfo(name='r\x1b[90m_\x1b[0m\x1b[34m16\x1b[0m\x1b[90m_\x1b[0m\x1b[91m16\x1
```

**sum_axis1** — `a.sum(axis=1)`
#### `r_16_16n2`  gs=[16, 1, 1] ls=[16, 1, 1]
structure: AFTER=3 BARRIER=1 DEFINE_LOCAL=1 DEFINE_REG=1 END=1 ENDIF=1 IF=1 PARAM=2 RANGE=1 SINK=1 SPECIAL=2
compute:   ADD=2 CMPEQ=1 CONST=4 INDEX=7 LOAD=4 SHL=1 STORE=4
```
    0 PARAM              float.ptr(16)                                   =0
    1 PARAM              float.ptr(256)                                  =1
    2 DEFINE_LOCAL       float.ptr(16, AddrSpace.LOCAL)                    =0
    3 DEFINE_REG         float.ptr(1, AddrSpace.REG)                     =0
    4 CONST              int                                             =16
    5 SPECIAL            int                          [4]                'gidx0'
    6 SPECIAL            int                          [4]                'lidx0'
    7 CONST              int                                             =4
    8 SHL                int                          [5,7]             
    9 ADD                int                          [6,8]             
   10 INDEX              float.ptr(256)               [1,9]             
   11 LOAD               float                        [10]              
   12 INDEX              float.ptr(16, AddrSpace.LOCAL) [2,6]             
   13 STORE              void                         [12,11]           
   14 BARRIER            void                         [13]              
   15 AFTER              float.ptr(16, AddrSpace.LOCAL) [2,14]            
   16 CONST              int                                             =0
   17 INDEX              float.ptr(1, AddrSpace.REG)  [3,16]            
   18 CONST              float                                           =0.0
   19 STORE              void                         [17,18]           
   20 RANGE              int                          [4]                (102, AxisType.REDUCE)
   21 AFTER              float.ptr(1, AddrSpace.REG)  [3,19,20]         
   22 INDEX              float.ptr(1, AddrSpace.REG)  [21,16]           
   23 LOAD               float                        [22]              
   24 INDEX              float.ptr(16, AddrSpace.LOCAL) [15,20]           
   25 LOAD               float                        [24]              
   26 ADD                float                        [23,25]           
   27 STORE              void                         [17,26]           
   28 END                void                         [27,20]           
   29 AFTER              float.ptr(1, AddrSpace.REG)  [3,28]            
   30 INDEX              float.ptr(1, AddrSpace.REG)  [29,16]           
   31 LOAD               float                        [30]              
   32 CMPEQ              bool                         [6,16]            
   33 INDEX              float.ptr(16)                [0,5,32]          
   34 IF                 void                         [32,33]           
   35 STORE              void                         [33,31]           
   36 ENDIF              void                         [34]              
   37 SINK               void                         [35]               KernelInfo(name='r\x1b[90m_\x1b[0m\x1b[34m16\x1b[0m\x1b[90m_\x1b[0m\x1b[91m16\x1
```

**max_1d** — `a.max()`
#### `r_16_16n3`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: AFTER=5 BARRIER=1 DEFINE_LOCAL=1 DEFINE_REG=2 END=2 ENDIF=1 IF=1 PARAM=2 RANGE=2 SINK=1 SPECIAL=1
compute:   ADD=1 CMPEQ=1 CMPLT=2 CONST=4 INDEX=10 LOAD=6 SHL=1 STORE=6 WHERE=2
```
    0 PARAM              float.ptr(1)                                    =0
    1 PARAM              float.ptr(256)                                  =1
    2 DEFINE_LOCAL       float.ptr(16, AddrSpace.LOCAL)                    =0
    3 DEFINE_REG         float.ptr(1, AddrSpace.REG)                     =0
    4 DEFINE_REG         float.ptr(1, AddrSpace.REG)                     =1
    5 CONST              int                                             =16
    6 SPECIAL            int                          [5]                'lidx0'
    7 CONST              int                                             =0
    8 INDEX              float.ptr(1, AddrSpace.REG)  [3,7]             
    9 CONST              int                                             =4
   10 SHL                int                          [6,9]             
   11 CONST              float                                           =-inf
   12 STORE              void                         [8,11]            
   13 RANGE              int                          [5]                (0, AxisType.REDUCE)
   14 AFTER              float.ptr(1, AddrSpace.REG)  [3,12,13]         
   15 INDEX              float.ptr(1, AddrSpace.REG)  [14,7]            
   16 LOAD               float                        [15]              
   17 ADD                int                          [10,13]           
   18 INDEX              float.ptr(256)               [1,17]            
   19 LOAD               float                        [18]              
   20 CMPLT              bool                         [16,19]           
   21 WHERE              float                        [20,19,16]        
   22 STORE              void                         [8,21]            
   23 END                void                         [22,13]           
   24 AFTER              float.ptr(1, AddrSpace.REG)  [3,23]            
   25 INDEX              float.ptr(1, AddrSpace.REG)  [24,7]            
   26 LOAD               float                        [25]              
   27 INDEX              float.ptr(16, AddrSpace.LOCAL) [2,6]             
   28 STORE              void                         [27,26]           
   29 BARRIER            void                         [28]              
   30 AFTER              float.ptr(16, AddrSpace.LOCAL) [2,29]            
   31 INDEX              float.ptr(1, AddrSpace.REG)  [4,7]             
   32 STORE              void                         [31,11]           
   33 RANGE              int                          [5,23]             (101, AxisType.REDUCE)
   34 AFTER              float.ptr(1, AddrSpace.REG)  [4,32,33]         
   35 INDEX              float.ptr(1, AddrSpace.REG)  [34,7]            
   36 LOAD               float                        [35]              
   37 INDEX              float.ptr(16, AddrSpace.LOCAL) [30,33]           
   38 LOAD               float                        [37]              
   39 CMPLT              bool                         [36,38]           
   40 WHERE              float                        [39,38,36]        
   41 STORE              void                         [31,40]           
   42 END                void                         [41,33]           
   43 AFTER              float.ptr(1, AddrSpace.REG)  [4,42]            
   44 INDEX              float.ptr(1, AddrSpace.REG)  [43,7]            
   45 LOAD               float                        [44]              
   46 CMPEQ              bool                         [6,7]             
   47 INDEX              float.ptr(1)                 [0,7,46]          
   48 IF                 void                         [46,47]           
   49 STORE              void                         [47,45]           
   50 ENDIF              void                         [48]              
   51 SINK               void                         [49]               KernelInfo(name='r\x1b[90m_\x1b[0m\x1b[91m16\x1b[0m\x1b[90m_\x1b[0m\x1b[31m16\x1
```

**mean** — `a.mean(axis=1)`
#### `r_16_16n4`  gs=[16, 1, 1] ls=[16, 1, 1]
structure: AFTER=3 BARRIER=1 DEFINE_LOCAL=1 DEFINE_REG=1 END=1 ENDIF=1 IF=1 PARAM=2 RANGE=1 SINK=1 SPECIAL=2
compute:   ADD=2 CMPEQ=1 CONST=5 INDEX=7 LOAD=4 MUL=1 SHL=1 STORE=4
```
    0 PARAM              float.ptr(16)                                   =0
    1 PARAM              float.ptr(256)                                  =1
    2 DEFINE_LOCAL       float.ptr(16, AddrSpace.LOCAL)                    =0
    3 DEFINE_REG         float.ptr(1, AddrSpace.REG)                     =0
    4 CONST              int                                             =16
    5 SPECIAL            int                          [4]                'gidx0'
    6 SPECIAL            int                          [4]                'lidx0'
    7 CONST              int                                             =4
    8 SHL                int                          [5,7]             
    9 ADD                int                          [6,8]             
   10 INDEX              float.ptr(256)               [1,9]             
   11 LOAD               float                        [10]              
   12 INDEX              float.ptr(16, AddrSpace.LOCAL) [2,6]             
   13 STORE              void                         [12,11]           
   14 BARRIER            void                         [13]              
   15 AFTER              float.ptr(16, AddrSpace.LOCAL) [2,14]            
   16 CONST              int                                             =0
   17 INDEX              float.ptr(1, AddrSpace.REG)  [3,16]            
   18 CONST              float                                           =0.0
   19 STORE              void                         [17,18]           
   20 RANGE              int                          [4]                (102, AxisType.REDUCE)
   21 AFTER              float.ptr(1, AddrSpace.REG)  [3,19,20]         
   22 INDEX              float.ptr(1, AddrSpace.REG)  [21,16]           
   23 LOAD               float                        [22]              
   24 INDEX              float.ptr(16, AddrSpace.LOCAL) [15,20]           
   25 LOAD               float                        [24]              
   26 ADD                float                        [23,25]           
   27 STORE              void                         [17,26]           
   28 END                void                         [27,20]           
   29 AFTER              float.ptr(1, AddrSpace.REG)  [3,28]            
   30 INDEX              float.ptr(1, AddrSpace.REG)  [29,16]           
   31 LOAD               float                        [30]              
   32 CMPEQ              bool                         [6,16]            
   33 INDEX              float.ptr(16)                [0,5,32]          
   34 CONST              float                                           =0.0625
   35 MUL                float                        [31,34]           
   36 IF                 void                         [32,33]           
   37 STORE              void                         [33,35]           
   38 ENDIF              void                         [36]              
   39 SINK               void                         [37]               KernelInfo(name='r\x1b[90m_\x1b[0m\x1b[34m16\x1b[0m\x1b[90m_\x1b[0m\x1b[91m16\x1
```

---

## Matmul

**matmul_16** — `A@B (16x16)`
#### `r_16_16_16`  gs=[16, 16, 1] ls=[16, 1, 1]
structure: AFTER=3 BARRIER=1 DEFINE_LOCAL=1 DEFINE_REG=1 END=1 ENDIF=1 IF=1 PARAM=3 RANGE=1 SINK=1 SPECIAL=3
compute:   ADD=4 CMPEQ=1 CONST=4 INDEX=8 LOAD=5 MUL=1 SHL=2 STORE=4
```
    0 PARAM              float.ptr(256)                                  =0
    1 PARAM              float.ptr(256)                                  =1
    2 PARAM              float.ptr(256)                                  =2
    3 DEFINE_LOCAL       float.ptr(16, AddrSpace.LOCAL)                    =0
    4 DEFINE_REG         float.ptr(1, AddrSpace.REG)                     =0
    5 CONST              int                                             =16
    6 SPECIAL            int                          [5]                'gidx1'
    7 SPECIAL            int                          [5]                'lidx0'
    8 CONST              int                                             =4
    9 SHL                int                          [6,8]             
   10 ADD                int                          [7,9]             
   11 INDEX              float.ptr(256)               [1,10]            
   12 LOAD               float                        [11]              
   13 SPECIAL            int                          [5]                'gidx0'
   14 SHL                int                          [7,8]             
   15 ADD                int                          [13,14]           
   16 INDEX              float.ptr(256)               [2,15]            
   17 LOAD               float                        [16]              
   18 INDEX              float.ptr(16, AddrSpace.LOCAL) [3,7]             
   19 MUL                float                        [12,17]           
   20 STORE              void                         [18,19]           
   21 BARRIER            void                         [20]              
   22 AFTER              float.ptr(16, AddrSpace.LOCAL) [3,21]            
   23 CONST              int                                             =0
   24 INDEX              float.ptr(1, AddrSpace.REG)  [4,23]            
   25 CONST              float                                           =0.0
   26 STORE              void                         [24,25]           
   27 RANGE              int                          [5]                (103, AxisType.REDUCE)
   28 AFTER              float.ptr(1, AddrSpace.REG)  [4,26,27]         
   29 INDEX              float.ptr(1, AddrSpace.REG)  [28,23]           
   30 LOAD               float                        [29]              
   31 INDEX              float.ptr(16, AddrSpace.LOCAL) [22,27]           
   32 LOAD               float                        [31]              
   33 ADD                float                        [30,32]           
   34 STORE              void                         [24,33]           
   35 END                void                         [34,27]           
   36 AFTER              float.ptr(1, AddrSpace.REG)  [4,35]            
   37 INDEX              float.ptr(1, AddrSpace.REG)  [36,23]           
   38 LOAD               float                        [37]              
   39 ADD                int                          [13,9]            
   40 CMPEQ              bool                         [7,23]            
   41 INDEX              float.ptr(256)               [0,39,40]         
   42 IF                 void                         [40,41]           
   43 STORE              void                         [41,38]           
   44 ENDIF              void                         [42]              
   45 SINK               void                         [43]               KernelInfo(name='r\x1b[90m_\x1b[0m\x1b[34m16\x1b[0m\x1b[90m_\x1b[0m\x1b[34m16\x1
```

**matmul_64** — `A@B (64x64)`
#### `r_2_8_16_4_4_16_4`  gs=[2, 1, 1] ls=[8, 16, 1]
structure: AFTER=2 DEFINE_REG=1 END=1 GROUP=2 PARAM=3 RANGE=1 SINK=1 SPECIAL=3
compute:   ADD=77 CAST=12 CONST=21 GEP=32 INDEX=60 LOAD=40 MUL=64 SHL=5 STORE=36 VECTORIZE=4
```
    0 PARAM              float.ptr(4096)                                 =0
    1 PARAM              float.ptr(4096)                                 =1
    2 PARAM              float.ptr(4096)                                 =2
    3 DEFINE_REG         float.ptr(16, AddrSpace.REG)                    =0
    4 CONST              int                                             =2
    5 SPECIAL            int                          [4]                'gidx0'
    6 CONST              int                                             =8
    7 SPECIAL            int                          [6]                'lidx0'
    8 CONST              int                                             =16
    9 SPECIAL            int                          [8]                'lidx1'
   10 CONST              int                                             =0
   11 INDEX              float.ptr(16, AddrSpace.REG) [3,10]            
   12 CONST              int                                             =1
   13 INDEX              float.ptr(16, AddrSpace.REG) [3,12]            
   14 INDEX              float.ptr(16, AddrSpace.REG) [3,4]             
   15 CONST              int                                             =3
   16 INDEX              float.ptr(16, AddrSpace.REG) [3,15]            
   17 CONST              int                                             =4
   18 INDEX              float.ptr(16, AddrSpace.REG) [3,17]            
   19 CONST              int                                             =5
   20 INDEX              float.ptr(16, AddrSpace.REG) [3,19]            
   21 CONST              int                                             =6
   22 INDEX              float.ptr(16, AddrSpace.REG) [3,21]            
   23 CONST              int                                             =7
   24 INDEX              float.ptr(16, AddrSpace.REG) [3,23]            
   25 INDEX              float.ptr(16, AddrSpace.REG) [3,6]             
   26 CONST              int                                             =9
   27 INDEX              float.ptr(16, AddrSpace.REG) [3,26]            
   28 CONST              int                                             =10
   29 INDEX              float.ptr(16, AddrSpace.REG) [3,28]            
   30 CONST              int                                             =11
   31 INDEX              float.ptr(16, AddrSpace.REG) [3,30]            
   32 CONST              int                                             =12
   33 INDEX              float.ptr(16, AddrSpace.REG) [3,32]            
   34 CONST              int                                             =13
   35 INDEX              float.ptr(16, AddrSpace.REG) [3,34]            
   36 CONST              int                                             =14
   37 INDEX              float.ptr(16, AddrSpace.REG) [3,36]            
   38 CONST              int                                             =15
   39 INDEX              float.ptr(16, AddrSpace.REG) [3,38]            
   40 SHL                int                          [5,30]            
   41 SHL                int                          [7,6]             
   42 ADD                int                          [40,41]           
   43 SHL                int                          [9,4]             
   44 CONST              float                                           =0.0
   45 CONST              int                                             =64
   46 CONST              int                                             =128
   47 CONST              int                                             =192
   48 STORE              void                         [11,44]           
   49 STORE              void                         [13,44]           
   50 STORE              void                         [14,44]           
   51 STORE              void                         [16,44]           
   52 STORE              void                         [18,44]           
   53 STORE              void                         [20,44]           
   54 STORE              void                         [22,44]           
   55 STORE              void                         [24,44]           
   56 STORE              void                         [25,44]           
   57 STORE              void                         [27,44]           
   58 STORE              void                         [29,44]           
   59 STORE              void                         [31,44]           
   60 STORE              void                         [33,44]           
   61 STORE              void                         [35,44]           
   62 STORE              void                         [37,44]           
   63 STORE              void                         [39,44]           
   64 RANGE              int                          [8]                (0, AxisType.REDUCE)
   65 AFTER              float.ptr(16, AddrSpace.REG) [3,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64]
   66 INDEX              float.ptr(16, AddrSpace.REG) [65,10]           
   67 LOAD               float                        [66]              
   68 INDEX              float.ptr(16, AddrSpace.REG) [65,12]           
   69 LOAD               float                        [68]              
   70 INDEX              float.ptr(16, AddrSpace.REG) [65,4]            
   71 LOAD               float                        [70]              
   72 INDEX              float.ptr(16, AddrSpace.REG) [65,15]           
   73 LOAD               float                        [72]              
   74 INDEX              float.ptr(16, AddrSpace.REG) [65,17]           
   75 LOAD               float                        [74]              
   76 INDEX              float.ptr(16, AddrSpace.REG) [65,19]           
   77 LOAD               float                        [76]              
   78 INDEX              float.ptr(16, AddrSpace.REG) [65,21]           
   79 LOAD               float                        [78]              
   80 INDEX              float.ptr(16, AddrSpace.REG) [65,23]           
   81 LOAD               float                        [80]              
   82 INDEX              float.ptr(16, AddrSpace.REG) [65,6]            
   83 LOAD               float                        [82]              
   84 INDEX              float.ptr(16, AddrSpace.REG) [65,26]           
   85 LOAD               float                        [84]              
   86 INDEX              float.ptr(16, AddrSpace.REG) [65,28]           
   87 LOAD               float                        [86]              
   88 INDEX              float.ptr(16, AddrSpace.REG) [65,30]           
   89 LOAD               float                        [88]              
   90 INDEX              float.ptr(16, AddrSpace.REG) [65,32]           
   91 LOAD               float                        [90]              
   92 INDEX              float.ptr(16, AddrSpace.REG) [65,34]           
   93 LOAD               float                        [92]              
   94 INDEX              float.ptr(16, AddrSpace.REG) [65,36]           
   95 LOAD               float                        [94]              
   96 INDEX              float.ptr(16, AddrSpace.REG) [65,38]           
   97 LOAD               float                        [96]              
   98 SHL                int                          [64,4]            
   99 ADD                int                          [42,98]           
  100 ADD                int                          [99,45]           
  101 INDEX              float.ptr(4096)              [1,100]           
  102 CAST               float.vec(4).ptr(4096)       [101]             
  103 LOAD               float.vec(4)                 [102]             
  104 ADD                int                          [99,46]           
  105 INDEX              float.ptr(4096)              [1,104]           
  106 CAST               float.vec(4).ptr(4096)       [105]             
  107 LOAD               float.vec(4)                 [106]             
  108 ADD                int                          [99,47]           
  109 INDEX              float.ptr(4096)              [1,108]           
  110 CAST               float.vec(4).ptr(4096)       [109]             
  111 LOAD               float.vec(4)                 [110]             
  112 INDEX              float.ptr(4096)              [1,99]            
  113 CAST               float.vec(4).ptr(4096)       [112]             
  114 LOAD               float.vec(4)                 [113]             
  115 SHL                int                          [64,6]            
  116 ADD                int                          [43,115]          
  117 ADD                int                          [116,45]          
  118 INDEX              float.ptr(4096)              [2,117]           
  119 CAST               float.vec(4).ptr(4096)       [118]             
  120 LOAD               float.vec(4)                 [119]             
  121 ADD                int                          [116,46]          
  122 INDEX              float.ptr(4096)              [2,121]           
  123 CAST               float.vec(4).ptr(4096)       [122]             
  124 LOAD               float.vec(4)                 [123]             
  125 ADD                int                          [116,47]          
  126 INDEX              float.ptr(4096)              [2,125]           
  127 CAST               float.vec(4).ptr(4096)       [126]             
  128 LOAD               float.vec(4)                 [127]             
  129 INDEX              float.ptr(4096)              [2,116]           
  130 CAST               float.vec(4).ptr(4096)       [129]             
  131 LOAD               float.vec(4)                 [130]             
  132 GEP                float                        [103]              (0,)
  133 GEP                float                        [107]              (0,)
  134 GEP                float                        [111]              (0,)
  135 GEP                float                        [114]              (0,)
  136 GEP                float                        [120]              (0,)
  137 GEP                float                        [124]              (0,)
  138 GEP                float                        [128]              (0,)
  139 GEP                float                        [131]              (0,)
  140 GEP                float                        [103]              (1,)
  141 GEP                float                        [107]              (1,)
  142 GEP                float                        [111]              (1,)
  143 GEP                float                        [114]              (1,)
  144 GEP                float                        [120]              (1,)
  145 GEP                float                        [124]              (1,)
  146 GEP                float                        [128]              (1,)
  147 GEP                float                        [131]              (1,)
  148 GEP                float                        [103]              (2,)
  149 GEP                float                        [107]              (2,)
  150 GEP                float                        [111]              (2,)
  151 GEP                float                        [114]              (2,)
  152 GEP                float                        [120]              (2,)
  153 GEP                float                        [124]              (2,)
  154 GEP                float                        [128]              (2,)
  155 GEP                float                        [131]              (2,)
  156 GEP                float                        [103]              (3,)
  157 GEP                float                        [107]              (3,)
  158 GEP                float                        [111]              (3,)
  159 GEP                float                        [114]              (3,)
  160 GEP                float                        [120]              (3,)
  161 GEP                float                        [124]              (3,)
  162 GEP                float                        [128]              (3,)
  163 GEP                float                        [131]              (3,)
  164 MUL                float                        [135,139]         
  165 ADD                float                        [67,164]          
  166 MUL                float                        [132,139]         
  167 ADD                float                        [69,166]          
  168 MUL                float                        [133,139]         
  169 ADD                float                        [71,168]          
  170 MUL                float                        [134,139]         
  171 ADD                float                        [73,170]          
  172 MUL                float                        [135,147]         
  173 ADD                float                        [75,172]          
  174 MUL                float                        [132,147]         
  175 ADD                float                        [77,174]          
  176 MUL                float                        [133,147]         
  177 ADD                float                        [79,176]          
  178 MUL                float                        [134,147]         
  179 ADD                float                        [81,178]          
  180 MUL                float                        [135,155]         
  181 ADD                float                        [83,180]          
  182 MUL                float                        [132,155]         
  183 ADD                float                        [85,182]          
  184 MUL                float                        [133,155]         
  185 ADD                float                        [87,184]          
  186 MUL                float                        [134,155]         
  187 ADD                float                        [89,186]          
  188 MUL                float                        [135,163]         
  189 ADD                float                        [91,188]          
  190 MUL                float                        [132,163]         
  191 ADD                float                        [93,190]          
  192 MUL                float                        [133,163]         
  193 ADD                float                        [95,192]          
  194 MUL                float                        [134,163]         
  195 ADD                float                        [97,194]          
  196 MUL                float                        [143,136]         
  197 ADD                float                        [165,196]         
  198 MUL                float                        [140,136]         
  199 ADD                float                        [167,198]         
  200 MUL                float                        [141,136]         
  201 ADD                float                        [169,200]         
  202 MUL                float                        [142,136]         
  203 ADD                float                        [171,202]         
  204 MUL                float                        [143,144]         
  205 ADD                float                        [173,204]         
  206 MUL                float                        [140,144]         
  207 ADD                float                        [175,206]         
  208 MUL                float                        [141,144]         
  209 ADD                float                        [177,208]         
  210 MUL                float                        [142,144]         
  211 ADD                float                        [179,210]         
  212 MUL                float                        [143,152]         
  213 ADD                float                        [181,212]         
  214 MUL                float                        [140,152]         
  215 ADD                float                        [183,214]         
  216 MUL                float                        [141,152]         
  217 ADD                float                        [185,216]         
  218 MUL                float                        [142,152]         
  219 ADD                float                        [187,218]         
  220 MUL                float                        [143,160]         
  221 ADD                float                        [189,220]         
  222 MUL                float                        [140,160]         
  223 ADD                float                        [191,222]         
  224 MUL                float                        [141,160]         
  225 ADD                float                        [193,224]         
  226 MUL                float                        [142,160]         
  227 ADD                float                        [195,226]         
  228 MUL                float                        [151,137]         
  229 ADD                float                        [197,228]         
  230 MUL                float                        [148,137]         
  231 ADD                float                        [199,230]         
  232 MUL                float                        [149,137]         
  233 ADD                float                        [201,232]         
  234 MUL                float                        [150,137]         
  235 ADD                float                        [203,234]         
  236 MUL                float                        [151,145]         
  237 ADD                float                        [205,236]         
  238 MUL                float                        [148,145]         
  239 ADD                float                        [207,238]         
  240 MUL                float                        [149,145]         
  241 ADD                float                        [209,240]         
  242 MUL                float                        [150,145]         
  243 ADD                float                        [211,242]         
  244 MUL                float                        [151,153]         
  245 ADD                float                        [213,244]         
  246 MUL                float                        [148,153]         
  247 ADD                float                        [215,246]         
  248 MUL                float                        [149,153]         
  249 ADD                float                        [217,248]         
  250 MUL                float                        [150,153]         
  251 ADD                float                        [219,250]         
  252 MUL                float                        [151,161]         
  253 ADD                float                        [221,252]         
  254 MUL                float                        [148,161]         
  255 ADD                float                        [223,254]         
  256 MUL                float                        [149,161]         
  257 ADD                float                        [225,256]         
  258 MUL                float                        [150,161]         
  259 ADD                float                        [227,258]         
  260 MUL                float                        [159,138]         
  261 ADD                float                        [229,260]         
  262 MUL                float                        [156,138]         
  263 ADD                float                        [231,262]         
  264 MUL                float                        [157,138]         
  265 ADD                float                        [233,264]         
  266 MUL                float                        [158,138]         
  267 ADD                float                        [235,266]         
  268 MUL                float                        [159,146]         
  269 ADD                float                        [237,268]         
  270 MUL                float                        [156,146]         
  271 ADD                float                        [239,270]         
  272 MUL                float                        [157,146]         
  273 ADD                float                        [241,272]         
  274 MUL                float                        [158,146]         
  275 ADD                float                        [243,274]         
  276 MUL                float                        [159,154]         
  277 ADD                float                        [245,276]         
  278 MUL                float                        [156,154]         
  279 ADD                float                        [247,278]         
  280 MUL                float                        [157,154]         
  281 ADD                float                        [249,280]         
  282 MUL                float                        [158,154]         
  283 ADD                float                        [251,282]         
  284 MUL                float                        [159,162]         
  285 ADD                float                        [253,284]         
  286 MUL                float                        [156,162]         
  287 ADD                float                        [255,286]         
  288 MUL                float                        [157,162]         
  289 ADD                float                        [257,288]         
  290 MUL                float                        [158,162]         
  291 ADD                float                        [259,290]         
  292 STORE              void                         [11,261]          
  293 STORE              void                         [13,263]          
  294 STORE              void                         [14,265]          
  295 STORE              void                         [16,267]          
  296 STORE              void                         [18,269]          
  297 STORE              void                         [20,271]          
  298 STORE              void                         [22,273]          
  299 STORE              void                         [24,275]          
  300 STORE              void                         [25,277]          
  301 STORE              void                         [27,279]          
  302 STORE              void                         [29,281]          
  303 STORE              void                         [31,283]          
  304 STORE              void                         [33,285]          
  305 STORE              void                         [35,287]          
  306 STORE              void                         [37,289]          
  307 STORE              void                         [39,291]          
  308 GROUP              void                         [292,293,294,295,296,297,298,299,300,301,302,303,304,305,306,307]
  309 END                void                         [308,64]          
  310 AFTER              float.ptr(16, AddrSpace.REG) [3,309]           
  311 INDEX              float.ptr(16, AddrSpace.REG) [310,10]          
  312 LOAD               float                        [311]             
  313 INDEX              float.ptr(16, AddrSpace.REG) [310,12]          
  314 LOAD               float                        [313]             
  315 INDEX              float.ptr(16, AddrSpace.REG) [310,4]           
  316 LOAD               float                        [315]             
  317 INDEX              float.ptr(16, AddrSpace.REG) [310,15]          
  318 LOAD               float                        [317]             
  319 INDEX              float.ptr(16, AddrSpace.REG) [310,17]          
  320 LOAD               float                        [319]             
  321 INDEX              float.ptr(16, AddrSpace.REG) [310,19]          
  322 LOAD               float                        [321]             
  323 INDEX              float.ptr(16, AddrSpace.REG) [310,21]          
  324 LOAD               float                        [323]             
  325 INDEX              float.ptr(16, AddrSpace.REG) [310,23]          
  326 LOAD               float                        [325]             
  327 INDEX              float.ptr(16, AddrSpace.REG) [310,6]           
  328 LOAD               float                        [327]             
  329 INDEX              float.ptr(16, AddrSpace.REG) [310,26]          
  330 LOAD               float                        [329]             
  331 INDEX              float.ptr(16, AddrSpace.REG) [310,28]          
  332 LOAD               float                        [331]             
  333 INDEX              float.ptr(16, AddrSpace.REG) [310,30]          
  334 LOAD               float                        [333]             
  335 INDEX              float.ptr(16, AddrSpace.REG) [310,32]          
  336 LOAD               float                        [335]             
  337 INDEX              float.ptr(16, AddrSpace.REG) [310,34]          
  338 LOAD               float                        [337]             
  339 INDEX              float.ptr(16, AddrSpace.REG) [310,36]          
  340 LOAD               float                        [339]             
  341 INDEX              float.ptr(16, AddrSpace.REG) [310,38]          
  342 LOAD               float                        [341]             
  343 VECTORIZE          float.vec(4)                 [312,320,328,336] 
  344 VECTORIZE          float.vec(4)                 [314,322,330,338] 
  345 VECTORIZE          float.vec(4)                 [316,324,332,340] 
  346 VECTORIZE          float.vec(4)                 [318,326,334,342] 
  347 ADD                int                          [42,43]           
  348 INDEX              float.ptr(4096)              [0,347]           
  349 ADD                int                          [347,45]          
  350 INDEX              float.ptr(4096)              [0,349]           
  351 ADD                int                          [347,46]          
  352 INDEX              float.ptr(4096)              [0,351]           
  353 ADD                int                          [347,47]          
  354 INDEX              float.ptr(4096)              [0,353]           
  355 CAST               float.vec(4).ptr(4096)       [350]             
  356 CAST               float.vec(4).ptr(4096)       [352]             
  357 CAST               float.vec(4).ptr(4096)       [354]             
  358 CAST               float.vec(4).ptr(4096)       [348]             
  359 STORE              void                         [355,344]         
  360 STORE              void                         [356,345]         
  361 STORE              void                         [357,346]         
  362 STORE              void                         [358,343]         
  363 GROUP              void                         [362,359,360,361] 
  364 SINK               void                         [363]              KernelInfo(name='r\x1b[90m_\x1b[0m\x1b[34m2\x1b[0m\x1b[90m_\x1b[0m\x1b[36m8\x1b[
```

**matvec** — `A@v (64x64@64)`
#### `r_64_16_4`  gs=[64, 1, 1] ls=[16, 1, 1]
structure: AFTER=5 BARRIER=1 DEFINE_LOCAL=1 DEFINE_REG=2 END=2 ENDIF=1 IF=1 PARAM=3 RANGE=2 SINK=1 SPECIAL=2
compute:   ADD=4 CMPEQ=1 CONST=7 INDEX=11 LOAD=7 MUL=1 SHL=2 STORE=6
```
    0 PARAM              float.ptr(64)                                   =0
    1 PARAM              float.ptr(4096)                                 =1
    2 PARAM              float.ptr(64)                                   =2
    3 DEFINE_LOCAL       float.ptr(16, AddrSpace.LOCAL)                    =0
    4 DEFINE_REG         float.ptr(1, AddrSpace.REG)                     =0
    5 DEFINE_REG         float.ptr(1, AddrSpace.REG)                     =1
    6 CONST              int                                             =64
    7 SPECIAL            int                          [6]                'gidx0'
    8 CONST              int                                             =16
    9 SPECIAL            int                          [8]                'lidx0'
   10 CONST              int                                             =0
   11 INDEX              float.ptr(1, AddrSpace.REG)  [4,10]            
   12 CONST              int                                             =6
   13 SHL                int                          [7,12]            
   14 CONST              int                                             =2
   15 SHL                int                          [9,14]            
   16 CONST              float                                           =0.0
   17 CONST              int                                             =4
   18 STORE              void                         [11,16]           
   19 RANGE              int                          [17]               (0, AxisType.REDUCE)
   20 AFTER              float.ptr(1, AddrSpace.REG)  [4,18,19]         
   21 INDEX              float.ptr(1, AddrSpace.REG)  [20,10]           
   22 LOAD               float                        [21]              
   23 ADD                int                          [15,19]           
   24 ADD                int                          [23,13]           
   25 INDEX              float.ptr(4096)              [1,24]            
   26 LOAD               float                        [25]              
   27 INDEX              float.ptr(64)                [2,23]            
   28 LOAD               float                        [27]              
   29 MUL                float                        [26,28]           
   30 ADD                float                        [22,29]           
   31 STORE              void                         [11,30]           
   32 END                void                         [31,19]           
   33 AFTER              float.ptr(1, AddrSpace.REG)  [4,32]            
   34 INDEX              float.ptr(1, AddrSpace.REG)  [33,10]           
   35 LOAD               float                        [34]              
   36 INDEX              float.ptr(16, AddrSpace.LOCAL) [3,9]             
   37 STORE              void                         [36,35]           
   38 BARRIER            void                         [37]              
   39 AFTER              float.ptr(16, AddrSpace.LOCAL) [3,38]            
   40 INDEX              float.ptr(1, AddrSpace.REG)  [5,10]            
   41 STORE              void                         [40,16]           
   42 RANGE              int                          [8,32]             (102, AxisType.REDUCE)
   43 AFTER              float.ptr(1, AddrSpace.REG)  [5,41,42]         
   44 INDEX              float.ptr(1, AddrSpace.REG)  [43,10]           
   45 LOAD               float                        [44]              
   46 INDEX              float.ptr(16, AddrSpace.LOCAL) [39,42]           
   47 LOAD               float                        [46]              
   48 ADD                float                        [45,47]           
   49 STORE              void                         [40,48]           
   50 END                void                         [49,42]           
   51 AFTER              float.ptr(1, AddrSpace.REG)  [5,50]            
   52 INDEX              float.ptr(1, AddrSpace.REG)  [51,10]           
   53 LOAD               float                        [52]              
   54 CMPEQ              bool                         [9,10]            
   55 INDEX              float.ptr(64)                [0,7,54]          
   56 IF                 void                         [54,55]           
   57 STORE              void                         [55,53]           
   58 ENDIF              void                         [56]              
   59 SINK               void                         [57]               KernelInfo(name='r\x1b[90m_\x1b[0m\x1b[34m64\x1b[0m\x1b[90m_\x1b[0m\x1b[91m16\x1
```

---

## Cast

**f32_to_f16** — `a.half()`
#### `E_16_4n13`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: PARAM=2 SINK=1 SPECIAL=1
compute:   CAST=6 CONST=2 GEP=4 INDEX=2 LOAD=1 SHL=1 STORE=1 VECTORIZE=1
```
    0 PARAM              half.ptr(64)                                    =0
    1 PARAM              float.ptr(64)                                   =1
    2 CONST              int                                             =16
    3 SPECIAL            int                          [2]                'lidx0'
    4 CONST              int                                             =2
    5 SHL                int                          [3,4]             
    6 INDEX              float.ptr(64)                [1,5]             
    7 CAST               float.vec(4).ptr(64)         [6]               
    8 LOAD               float.vec(4)                 [7]               
    9 GEP                float                        [8]                (0,)
   10 GEP                float                        [8]                (1,)
   11 GEP                float                        [8]                (2,)
   12 GEP                float                        [8]                (3,)
   13 CAST               half                         [9]               
   14 CAST               half                         [10]              
   15 CAST               half                         [11]              
   16 CAST               half                         [12]              
   17 VECTORIZE          half.vec(4)                  [13,14,15,16]     
   18 INDEX              half.ptr(64)                 [0,5]             
   19 CAST               half.vec(4).ptr(64)          [18]              
   20 STORE              void                         [19,17]           
   21 SINK               void                         [20]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m16\x1b[0m\x1b[90m_\x1b[0m\x1b[33m4\x1b
```

**f16_to_f32** — `a.float()`
#### `E_16_4n14`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: PARAM=2 SINK=1 SPECIAL=1
compute:   CAST=6 CONST=2 GEP=4 INDEX=2 LOAD=1 SHL=1 STORE=1 VECTORIZE=1
```
    0 PARAM              float.ptr(64)                                   =0
    1 PARAM              half.ptr(64)                                    =1
    2 CONST              int                                             =16
    3 SPECIAL            int                          [2]                'lidx0'
    4 CONST              int                                             =2
    5 SHL                int                          [3,4]             
    6 INDEX              half.ptr(64)                 [1,5]             
    7 CAST               half.vec(4).ptr(64)          [6]               
    8 LOAD               half.vec(4)                  [7]               
    9 GEP                half                         [8]                (0,)
   10 GEP                half                         [8]                (1,)
   11 GEP                half                         [8]                (2,)
   12 GEP                half                         [8]                (3,)
   13 CAST               float                        [9]               
   14 CAST               float                        [10]              
   15 CAST               float                        [11]              
   16 CAST               float                        [12]              
   17 VECTORIZE          float.vec(4)                 [13,14,15,16]     
   18 INDEX              float.ptr(64)                [0,5]             
   19 CAST               float.vec(4).ptr(64)         [18]              
   20 STORE              void                         [19,17]           
   21 SINK               void                         [20]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m16\x1b[0m\x1b[90m_\x1b[0m\x1b[33m4\x1b
```

**f32_to_int** — `a.int()`
#### `E_16_4n15`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: GROUP=1 PARAM=2 SINK=1 SPECIAL=1
compute:   ADD=3 CAST=5 CONST=4 GEP=4 INDEX=5 LOAD=1 SHL=1 STORE=4
```
    0 PARAM              int.ptr(64)                                     =0
    1 PARAM              float.ptr(64)                                   =1
    2 CONST              int                                             =16
    3 SPECIAL            int                          [2]                'lidx0'
    4 CONST              int                                             =2
    5 SHL                int                          [3,4]             
    6 INDEX              float.ptr(64)                [1,5]             
    7 CAST               float.vec(4).ptr(64)         [6]               
    8 LOAD               float.vec(4)                 [7]               
    9 GEP                float                        [8]                (0,)
   10 GEP                float                        [8]                (1,)
   11 GEP                float                        [8]                (2,)
   12 GEP                float                        [8]                (3,)
   13 CONST              int                                             =1
   14 ADD                int                          [5,13]            
   15 INDEX              int.ptr(64)                  [0,14]            
   16 ADD                int                          [5,4]             
   17 INDEX              int.ptr(64)                  [0,16]            
   18 CONST              int                                             =3
   19 ADD                int                          [5,18]            
   20 INDEX              int.ptr(64)                  [0,19]            
   21 INDEX              int.ptr(64)                  [0,5]             
   22 CAST               int                          [9]               
   23 CAST               int                          [10]              
   24 CAST               int                          [11]              
   25 CAST               int                          [12]              
   26 STORE              void                         [15,23]           
   27 STORE              void                         [17,24]           
   28 STORE              void                         [20,25]           
   29 STORE              void                         [21,22]           
   30 GROUP              void                         [29,26,27,28]     
   31 SINK               void                         [30]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m16\x1b[0m\x1b[90m_\x1b[0m\x1b[33m4\x1b
```

**int_to_f32** — `a.float()`
#### `E_16_4n16`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: PARAM=2 SINK=1 SPECIAL=1
compute:   ADD=3 CAST=5 CONST=4 INDEX=5 LOAD=4 SHL=1 STORE=1 VECTORIZE=1
```
    0 PARAM              float.ptr(64)                                   =0
    1 PARAM              int.ptr(64)                                     =1
    2 CONST              int                                             =16
    3 SPECIAL            int                          [2]                'lidx0'
    4 CONST              int                                             =2
    5 SHL                int                          [3,4]             
    6 CONST              int                                             =1
    7 ADD                int                          [5,6]             
    8 INDEX              int.ptr(64)                  [1,7]             
    9 LOAD               int                          [8]               
   10 ADD                int                          [5,4]             
   11 INDEX              int.ptr(64)                  [1,10]            
   12 LOAD               int                          [11]              
   13 CONST              int                                             =3
   14 ADD                int                          [5,13]            
   15 INDEX              int.ptr(64)                  [1,14]            
   16 LOAD               int                          [15]              
   17 INDEX              int.ptr(64)                  [1,5]             
   18 LOAD               int                          [17]              
   19 CAST               float                        [9]               
   20 CAST               float                        [12]              
   21 CAST               float                        [16]              
   22 CAST               float                        [18]              
   23 VECTORIZE          float.vec(4)                 [22,19,20,21]     
   24 INDEX              float.ptr(64)                [0,5]             
   25 CAST               float.vec(4).ptr(64)         [24]              
   26 STORE              void                         [25,23]           
   27 SINK               void                         [26]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m16\x1b[0m\x1b[90m_\x1b[0m\x1b[33m4\x1b
```

---

## Broadcast

**scalar_add** — `a + 1.0`
#### `E_16_4n17`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: PARAM=2 SINK=1 SPECIAL=1
compute:   ADD=4 CAST=2 CONST=3 GEP=4 INDEX=2 LOAD=1 SHL=1 STORE=1 VECTORIZE=1
```
    0 PARAM              float.ptr(64)                                   =0
    1 PARAM              float.ptr(64)                                   =1
    2 CONST              int                                             =16
    3 SPECIAL            int                          [2]                'lidx0'
    4 CONST              int                                             =2
    5 SHL                int                          [3,4]             
    6 INDEX              float.ptr(64)                [1,5]             
    7 CAST               float.vec(4).ptr(64)         [6]               
    8 LOAD               float.vec(4)                 [7]               
    9 GEP                float                        [8]                (0,)
   10 GEP                float                        [8]                (1,)
   11 GEP                float                        [8]                (2,)
   12 GEP                float                        [8]                (3,)
   13 CONST              float                                           =1.0
   14 ADD                float                        [9,13]            
   15 ADD                float                        [10,13]           
   16 ADD                float                        [11,13]           
   17 ADD                float                        [12,13]           
   18 VECTORIZE          float.vec(4)                 [14,15,16,17]     
   19 INDEX              float.ptr(64)                [0,5]             
   20 CAST               float.vec(4).ptr(64)         [19]              
   21 STORE              void                         [20,18]           
   22 SINK               void                         [21]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m16\x1b[0m\x1b[90m_\x1b[0m\x1b[33m4\x1b
```

**row_add** — `a + row`
#### `E_4_4_4`  gs=[1, 1, 1] ls=[4, 4, 1]
structure: PARAM=3 SINK=1 SPECIAL=2
compute:   ADD=5 CAST=3 CONST=2 GEP=8 INDEX=3 LOAD=2 SHL=2 STORE=1 VECTORIZE=1
```
    0 PARAM              float.ptr(64)                                   =0
    1 PARAM              float.ptr(64)                                   =1
    2 PARAM              float.ptr(16)                                   =2
    3 CONST              int                                             =4
    4 SPECIAL            int                          [3]                'lidx0'
    5 SPECIAL            int                          [3]                'lidx1'
    6 SHL                int                          [4,3]             
    7 CONST              int                                             =2
    8 SHL                int                          [5,7]             
    9 ADD                int                          [6,8]             
   10 INDEX              float.ptr(64)                [1,9]             
   11 CAST               float.vec(4).ptr(64)         [10]              
   12 LOAD               float.vec(4)                 [11]              
   13 INDEX              float.ptr(16)                [2,8]             
   14 CAST               float.vec(4).ptr(16)         [13]              
   15 LOAD               float.vec(4)                 [14]              
   16 GEP                float                        [12]               (0,)
   17 GEP                float                        [15]               (0,)
   18 GEP                float                        [12]               (1,)
   19 GEP                float                        [15]               (1,)
   20 GEP                float                        [12]               (2,)
   21 GEP                float                        [15]               (2,)
   22 GEP                float                        [12]               (3,)
   23 GEP                float                        [15]               (3,)
   24 ADD                float                        [16,17]           
   25 ADD                float                        [18,19]           
   26 ADD                float                        [20,21]           
   27 ADD                float                        [22,23]           
   28 VECTORIZE          float.vec(4)                 [24,25,26,27]     
   29 INDEX              float.ptr(64)                [0,9]             
   30 CAST               float.vec(4).ptr(64)         [29]              
   31 STORE              void                         [30,28]           
   32 SINK               void                         [31]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m4\x1b[0m\x1b[90m_\x1b[0m\x1b[36m4\x1b[
```

**col_add** — `a + col`
#### `E_4_4_4n1`  gs=[1, 1, 1] ls=[4, 4, 1]
structure: PARAM=3 SINK=1 SPECIAL=2
compute:   ADD=5 CAST=2 CONST=2 GEP=4 INDEX=3 LOAD=2 SHL=2 STORE=1 VECTORIZE=1
```
    0 PARAM              float.ptr(64)                                   =0
    1 PARAM              float.ptr(64)                                   =1
    2 PARAM              float.ptr(4)                                    =2
    3 CONST              int                                             =4
    4 SPECIAL            int                          [3]                'lidx0'
    5 INDEX              float.ptr(4)                 [2,4]             
    6 LOAD               float                        [5]               
    7 SPECIAL            int                          [3]                'lidx1'
    8 SHL                int                          [4,3]             
    9 CONST              int                                             =2
   10 SHL                int                          [7,9]             
   11 ADD                int                          [8,10]            
   12 INDEX              float.ptr(64)                [1,11]            
   13 CAST               float.vec(4).ptr(64)         [12]              
   14 LOAD               float.vec(4)                 [13]              
   15 GEP                float                        [14]               (0,)
   16 GEP                float                        [14]               (1,)
   17 GEP                float                        [14]               (2,)
   18 GEP                float                        [14]               (3,)
   19 ADD                float                        [15,6]            
   20 ADD                float                        [16,6]            
   21 ADD                float                        [17,6]            
   22 ADD                float                        [18,6]            
   23 VECTORIZE          float.vec(4)                 [19,20,21,22]     
   24 INDEX              float.ptr(64)                [0,11]            
   25 CAST               float.vec(4).ptr(64)         [24]              
   26 STORE              void                         [25,23]           
   27 SINK               void                         [26]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m4\x1b[0m\x1b[90m_\x1b[0m\x1b[36m4\x1b[
```

---

## Fused

**relu** — `a.relu()`
#### `E_16_4n18`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: PARAM=2 SINK=1 SPECIAL=1
compute:   CAST=2 CMPLT=4 CONST=3 GEP=4 INDEX=2 LOAD=1 SHL=1 STORE=1 VECTORIZE=1 WHERE=4
```
    0 PARAM              float.ptr(64)                                   =0
    1 PARAM              float.ptr(64)                                   =1
    2 CONST              int                                             =16
    3 SPECIAL            int                          [2]                'lidx0'
    4 CONST              int                                             =2
    5 SHL                int                          [3,4]             
    6 INDEX              float.ptr(64)                [1,5]             
    7 CAST               float.vec(4).ptr(64)         [6]               
    8 LOAD               float.vec(4)                 [7]               
    9 GEP                float                        [8]                (0,)
   10 GEP                float                        [8]                (1,)
   11 GEP                float                        [8]                (2,)
   12 GEP                float                        [8]                (3,)
   13 CONST              float                                           =0.0
   14 CMPLT              bool                         [13,9]            
   15 CMPLT              bool                         [13,10]           
   16 CMPLT              bool                         [13,11]           
   17 CMPLT              bool                         [13,12]           
   18 WHERE              float                        [14,9,13]         
   19 WHERE              float                        [15,10,13]        
   20 WHERE              float                        [16,11,13]        
   21 WHERE              float                        [17,12,13]        
   22 VECTORIZE          float.vec(4)                 [18,19,20,21]     
   23 INDEX              float.ptr(64)                [0,5]             
   24 CAST               float.vec(4).ptr(64)         [23]              
   25 STORE              void                         [24,22]           
   26 SINK               void                         [25]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m16\x1b[0m\x1b[90m_\x1b[0m\x1b[33m4\x1b
```

**gelu** — `a.gelu()`
#### `E_16_4n19`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: PARAM=2 SINK=1 SPECIAL=1
compute:   ADD=8 CAST=2 CONST=5 EXP2=4 GEP=4 INDEX=2 LOAD=1 MUL=20 RECIPROCAL=4 SHL=1 STORE=1 VECTORIZE=1
```
    0 PARAM              float.ptr(64)                                   =0
    1 PARAM              float.ptr(64)                                   =1
    2 CONST              int                                             =16
    3 SPECIAL            int                          [2]                'lidx0'
    4 CONST              int                                             =2
    5 SHL                int                          [3,4]             
    6 INDEX              float.ptr(64)                [1,5]             
    7 CAST               float.vec(4).ptr(64)         [6]               
    8 LOAD               float.vec(4)                 [7]               
    9 GEP                float                        [8]                (0,)
   10 GEP                float                        [8]                (1,)
   11 GEP                float                        [8]                (2,)
   12 GEP                float                        [8]                (3,)
   13 MUL                float                        [9,9]             
   14 MUL                float                        [13,9]            
   15 CONST              float                                           =0.044715
   16 MUL                float                        [15,14]           
   17 ADD                float                        [9,16]            
   18 CONST              float                                           =-2.302208198144325
   19 MUL                float                        [17,18]           
   20 EXP2               float                        [19]              
   21 MUL                float                        [10,10]           
   22 MUL                float                        [21,10]           
   23 MUL                float                        [15,22]           
   24 ADD                float                        [10,23]           
   25 MUL                float                        [24,18]           
   26 EXP2               float                        [25]              
   27 MUL                float                        [11,11]           
   28 MUL                float                        [27,11]           
   29 MUL                float                        [15,28]           
   30 ADD                float                        [11,29]           
   31 MUL                float                        [30,18]           
   32 EXP2               float                        [31]              
   33 MUL                float                        [12,12]           
   34 MUL                float                        [33,12]           
   35 MUL                float                        [15,34]           
   36 ADD                float                        [12,35]           
   37 MUL                float                        [36,18]           
   38 EXP2               float                        [37]              
   39 CONST              float                                           =1.0
   40 ADD                float                        [39,20]           
   41 RECIPROCAL         float                        [40]              
   42 ADD                float                        [39,26]           
   43 RECIPROCAL         float                        [42]              
   44 ADD                float                        [39,32]           
   45 RECIPROCAL         float                        [44]              
   46 ADD                float                        [39,38]           
   47 RECIPROCAL         float                        [46]              
   48 MUL                float                        [41,9]            
   49 MUL                float                        [43,10]           
   50 MUL                float                        [45,11]           
   51 MUL                float                        [47,12]           
   52 VECTORIZE          float.vec(4)                 [48,49,50,51]     
   53 INDEX              float.ptr(64)                [0,5]             
   54 CAST               float.vec(4).ptr(64)         [53]              
   55 STORE              void                         [54,52]           
   56 SINK               void                         [55]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m16\x1b[0m\x1b[90m_\x1b[0m\x1b[33m4\x1b
```

**softmax** — `a.softmax()`
#### `r_4_16_4`  gs=[4, 1, 1] ls=[16, 1, 1]
structure: AFTER=5 BARRIER=1 DEFINE_LOCAL=1 DEFINE_REG=2 END=2 ENDIF=1 IF=1 PARAM=2 RANGE=2 SINK=1 SPECIAL=2
compute:   ADD=2 CMPEQ=1 CMPLT=2 CONST=6 INDEX=10 LOAD=6 SHL=2 STORE=6 WHERE=2
```
    0 PARAM              float.ptr(4)                                    =0
    1 PARAM              float.ptr(256)                                  =1
    2 DEFINE_LOCAL       float.ptr(16, AddrSpace.LOCAL)                    =0
    3 DEFINE_REG         float.ptr(1, AddrSpace.REG)                     =0
    4 DEFINE_REG         float.ptr(1, AddrSpace.REG)                     =1
    5 CONST              int                                             =4
    6 SPECIAL            int                          [5]                'gidx0'
    7 CONST              int                                             =16
    8 SPECIAL            int                          [7]                'lidx0'
    9 CONST              int                                             =0
   10 INDEX              float.ptr(1, AddrSpace.REG)  [3,9]             
   11 CONST              int                                             =6
   12 SHL                int                          [6,11]            
   13 CONST              int                                             =2
   14 SHL                int                          [8,13]            
   15 CONST              float                                           =-inf
   16 STORE              void                         [10,15]           
   17 RANGE              int                          [5]                (0, AxisType.REDUCE)
   18 AFTER              float.ptr(1, AddrSpace.REG)  [3,16,17]         
   19 INDEX              float.ptr(1, AddrSpace.REG)  [18,9]            
   20 LOAD               float                        [19]              
   21 ADD                int                          [14,17]           
   22 ADD                int                          [21,12]           
   23 INDEX              float.ptr(256)               [1,22]            
   24 LOAD               float                        [23]              
   25 CMPLT              bool                         [20,24]           
   26 WHERE              float                        [25,24,20]        
   27 STORE              void                         [10,26]           
   28 END                void                         [27,17]           
   29 AFTER              float.ptr(1, AddrSpace.REG)  [3,28]            
   30 INDEX              float.ptr(1, AddrSpace.REG)  [29,9]            
   31 LOAD               float                        [30]              
   32 INDEX              float.ptr(16, AddrSpace.LOCAL) [2,8]             
   33 STORE              void                         [32,31]           
   34 BARRIER            void                         [33]              
   35 AFTER              float.ptr(16, AddrSpace.LOCAL) [2,34]            
   36 INDEX              float.ptr(1, AddrSpace.REG)  [4,9]             
   37 STORE              void                         [36,15]           
   38 RANGE              int                          [7,28]             (102, AxisType.REDUCE)
   39 AFTER              float.ptr(1, AddrSpace.REG)  [4,37,38]         
   40 INDEX              float.ptr(1, AddrSpace.REG)  [39,9]            
   41 LOAD               float                        [40]              
   42 INDEX              float.ptr(16, AddrSpace.LOCAL) [35,38]           
   43 LOAD               float                        [42]              
   44 CMPLT              bool                         [41,43]           
   45 WHERE              float                        [44,43,41]        
   46 STORE              void                         [36,45]           
   47 END                void                         [46,38]           
   48 AFTER              float.ptr(1, AddrSpace.REG)  [4,47]            
   49 INDEX              float.ptr(1, AddrSpace.REG)  [48,9]            
   50 LOAD               float                        [49]              
   51 CMPEQ              bool                         [8,9]             
   52 INDEX              float.ptr(4)                 [0,6,51]          
   53 IF                 void                         [51,52]           
   54 STORE              void                         [52,50]           
   55 ENDIF              void                         [53]              
   56 SINK               void                         [54]               KernelInfo(name='r\x1b[90m_\x1b[0m\x1b[34m4\x1b[0m\x1b[90m_\x1b[0m\x1b[91m16\x1b
```
#### `r_4_16_4n1`  gs=[4, 1, 1] ls=[16, 1, 1]
structure: AFTER=5 BARRIER=1 DEFINE_LOCAL=1 DEFINE_REG=2 END=2 ENDIF=1 IF=1 PARAM=3 RANGE=2 SINK=1 SPECIAL=2
compute:   ADD=4 CMPEQ=1 CONST=7 EXP2=1 INDEX=11 LOAD=7 MUL=1 SHL=2 STORE=6 SUB=1
```
    0 PARAM              float.ptr(4)                                    =0
    1 PARAM              float.ptr(256)                                  =1
    2 PARAM              float.ptr(4)                                    =2
    3 DEFINE_LOCAL       float.ptr(16, AddrSpace.LOCAL)                    =0
    4 DEFINE_REG         float.ptr(1, AddrSpace.REG)                     =0
    5 DEFINE_REG         float.ptr(1, AddrSpace.REG)                     =1
    6 CONST              int                                             =4
    7 SPECIAL            int                          [6]                'gidx0'
    8 INDEX              float.ptr(4)                 [2,7]             
    9 LOAD               float                        [8]               
   10 CONST              int                                             =16
   11 SPECIAL            int                          [10]               'lidx0'
   12 CONST              int                                             =0
   13 INDEX              float.ptr(1, AddrSpace.REG)  [4,12]            
   14 CONST              int                                             =6
   15 SHL                int                          [7,14]            
   16 CONST              int                                             =2
   17 SHL                int                          [11,16]           
   18 CONST              float                                           =0.0
   19 CONST              float                                           =1.4426950408889634
   20 STORE              void                         [13,18]           
   21 RANGE              int                          [6]                (0, AxisType.REDUCE)
   22 AFTER              float.ptr(1, AddrSpace.REG)  [4,20,21]         
   23 INDEX              float.ptr(1, AddrSpace.REG)  [22,12]           
   24 LOAD               float                        [23]              
   25 ADD                int                          [17,21]           
   26 ADD                int                          [25,15]           
   27 INDEX              float.ptr(256)               [1,26]            
   28 LOAD               float                        [27]              
   29 SUB                float                        [28,9]            
   30 MUL                float                        [29,19]           
   31 EXP2               float                        [30]              
   32 ADD                float                        [24,31]           
   33 STORE              void                         [13,32]           
   34 END                void                         [33,21]           
   35 AFTER              float.ptr(1, AddrSpace.REG)  [4,34]            
   36 INDEX              float.ptr(1, AddrSpace.REG)  [35,12]           
   37 LOAD               float                        [36]              
   38 INDEX              float.ptr(16, AddrSpace.LOCAL) [3,11]            
   39 STORE              void                         [38,37]           
   40 BARRIER            void                         [39]              
   41 AFTER              float.ptr(16, AddrSpace.LOCAL) [3,40]            
   42 INDEX              float.ptr(1, AddrSpace.REG)  [5,12]            
   43 STORE              void                         [42,18]           
   44 RANGE              int                          [10,34]            (102, AxisType.REDUCE)
   45 AFTER              float.ptr(1, AddrSpace.REG)  [5,43,44]         
   46 INDEX              float.ptr(1, AddrSpace.REG)  [45,12]           
   47 LOAD               float                        [46]              
   48 INDEX              float.ptr(16, AddrSpace.LOCAL) [41,44]           
   49 LOAD               float                        [48]              
   50 ADD                float                        [47,49]           
   51 STORE              void                         [42,50]           
   52 END                void                         [51,44]           
   53 AFTER              float.ptr(1, AddrSpace.REG)  [5,52]            
   54 INDEX              float.ptr(1, AddrSpace.REG)  [53,12]           
   55 LOAD               float                        [54]              
   56 CMPEQ              bool                         [11,12]           
   57 INDEX              float.ptr(4)                 [0,7,56]          
   58 IF                 void                         [56,57]           
   59 STORE              void                         [57,55]           
   60 ENDIF              void                         [58]              
   61 SINK               void                         [59]               KernelInfo(name='r\x1b[90m_\x1b[0m\x1b[34m4\x1b[0m\x1b[90m_\x1b[0m\x1b[91m16\x1b
```
#### `E_4_16_4`  gs=[1, 1, 1] ls=[4, 16, 1]
structure: PARAM=4 SINK=1 SPECIAL=2
compute:   ADD=1 CAST=2 CONST=5 EXP2=4 GEP=4 INDEX=4 LOAD=3 MUL=8 RECIPROCAL=1 SHL=2 STORE=1 SUB=4 VECTORIZE=1
```
    0 PARAM              float.ptr(256)                                  =0
    1 PARAM              float.ptr(256)                                  =1
    2 PARAM              float.ptr(4)                                    =2
    3 PARAM              float.ptr(4)                                    =3
    4 CONST              int                                             =4
    5 SPECIAL            int                          [4]                'lidx0'
    6 INDEX              float.ptr(4)                 [2,5]             
    7 LOAD               float                        [6]               
    8 INDEX              float.ptr(4)                 [3,5]             
    9 LOAD               float                        [8]               
   10 CONST              int                                             =16
   11 SPECIAL            int                          [10]               'lidx1'
   12 CONST              int                                             =6
   13 SHL                int                          [5,12]            
   14 CONST              int                                             =2
   15 SHL                int                          [11,14]           
   16 ADD                int                          [13,15]           
   17 INDEX              float.ptr(256)               [1,16]            
   18 CAST               float.vec(4).ptr(256)        [17]              
   19 LOAD               float.vec(4)                 [18]              
   20 GEP                float                        [19]               (0,)
   21 GEP                float                        [19]               (1,)
   22 GEP                float                        [19]               (2,)
   23 GEP                float                        [19]               (3,)
   24 SUB                float                        [20,7]            
   25 CONST              float                                           =1.4426950408889634
   26 MUL                float                        [24,25]           
   27 EXP2               float                        [26]              
   28 SUB                float                        [21,7]            
   29 MUL                float                        [28,25]           
   30 EXP2               float                        [29]              
   31 SUB                float                        [22,7]            
   32 MUL                float                        [31,25]           
   33 EXP2               float                        [32]              
   34 SUB                float                        [23,7]            
   35 MUL                float                        [34,25]           
   36 EXP2               float                        [35]              
   37 RECIPROCAL         float                        [9]               
   38 MUL                float                        [27,37]           
   39 MUL                float                        [30,37]           
   40 MUL                float                        [33,37]           
   41 MUL                float                        [36,37]           
   42 VECTORIZE          float.vec(4)                 [38,39,40,41]     
   43 INDEX              float.ptr(256)               [0,16]            
   44 CAST               float.vec(4).ptr(256)        [43]              
   45 STORE              void                         [44,42]           
   46 SINK               void                         [45]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m4\x1b[0m\x1b[90m_\x1b[0m\x1b[36m16\x1b
```

**layernorm** — `a.layernorm()`
#### `r_4_16_4n2`  gs=[4, 1, 1] ls=[16, 1, 1]
structure: AFTER=5 BARRIER=1 DEFINE_LOCAL=1 DEFINE_REG=2 END=2 ENDIF=1 IF=1 PARAM=2 RANGE=2 SINK=1 SPECIAL=2
compute:   ADD=4 CMPEQ=1 CONST=7 INDEX=10 LOAD=6 MUL=1 SHL=2 STORE=6
```
    0 PARAM              float.ptr(4)                                    =0
    1 PARAM              float.ptr(256)                                  =1
    2 DEFINE_LOCAL       float.ptr(16, AddrSpace.LOCAL)                    =0
    3 DEFINE_REG         float.ptr(1, AddrSpace.REG)                     =0
    4 DEFINE_REG         float.ptr(1, AddrSpace.REG)                     =1
    5 CONST              int                                             =4
    6 SPECIAL            int                          [5]                'gidx0'
    7 CONST              int                                             =16
    8 SPECIAL            int                          [7]                'lidx0'
    9 CONST              int                                             =0
   10 INDEX              float.ptr(1, AddrSpace.REG)  [3,9]             
   11 CONST              int                                             =6
   12 SHL                int                          [6,11]            
   13 CONST              int                                             =2
   14 SHL                int                          [8,13]            
   15 CONST              float                                           =0.0
   16 STORE              void                         [10,15]           
   17 RANGE              int                          [5]                (0, AxisType.REDUCE)
   18 AFTER              float.ptr(1, AddrSpace.REG)  [3,16,17]         
   19 INDEX              float.ptr(1, AddrSpace.REG)  [18,9]            
   20 LOAD               float                        [19]              
   21 ADD                int                          [14,17]           
   22 ADD                int                          [21,12]           
   23 INDEX              float.ptr(256)               [1,22]            
   24 LOAD               float                        [23]              
   25 ADD                float                        [20,24]           
   26 STORE              void                         [10,25]           
   27 END                void                         [26,17]           
   28 AFTER              float.ptr(1, AddrSpace.REG)  [3,27]            
   29 INDEX              float.ptr(1, AddrSpace.REG)  [28,9]            
   30 LOAD               float                        [29]              
   31 INDEX              float.ptr(16, AddrSpace.LOCAL) [2,8]             
   32 STORE              void                         [31,30]           
   33 BARRIER            void                         [32]              
   34 AFTER              float.ptr(16, AddrSpace.LOCAL) [2,33]            
   35 INDEX              float.ptr(1, AddrSpace.REG)  [4,9]             
   36 STORE              void                         [35,15]           
   37 RANGE              int                          [7,27]             (102, AxisType.REDUCE)
   38 AFTER              float.ptr(1, AddrSpace.REG)  [4,36,37]         
   39 INDEX              float.ptr(1, AddrSpace.REG)  [38,9]            
   40 LOAD               float                        [39]              
   41 INDEX              float.ptr(16, AddrSpace.LOCAL) [34,37]           
   42 LOAD               float                        [41]              
   43 ADD                float                        [40,42]           
   44 STORE              void                         [35,43]           
   45 END                void                         [44,37]           
   46 AFTER              float.ptr(1, AddrSpace.REG)  [4,45]            
   47 INDEX              float.ptr(1, AddrSpace.REG)  [46,9]            
   48 LOAD               float                        [47]              
   49 CMPEQ              bool                         [8,9]             
   50 INDEX              float.ptr(4)                 [0,6,49]          
   51 CONST              float                                           =0.015625
   52 MUL                float                        [48,51]           
   53 IF                 void                         [49,50]           
   54 STORE              void                         [50,52]           
   55 ENDIF              void                         [53]              
   56 SINK               void                         [54]               KernelInfo(name='r\x1b[90m_\x1b[0m\x1b[34m4\x1b[0m\x1b[90m_\x1b[0m\x1b[91m16\x1b
```
#### `r_4_16_4n3`  gs=[4, 1, 1] ls=[16, 1, 1]
structure: AFTER=5 BARRIER=1 DEFINE_LOCAL=1 DEFINE_REG=2 END=2 ENDIF=1 IF=1 PARAM=3 RANGE=2 SINK=1 SPECIAL=2
compute:   ADD=5 CMPEQ=1 CONST=8 INDEX=11 LOAD=7 MUL=2 RECIPROCAL=1 SHL=2 SQRT=1 STORE=6 SUB=1
```
    0 PARAM              float.ptr(4)                                    =0
    1 PARAM              float.ptr(256)                                  =1
    2 PARAM              float.ptr(4)                                    =2
    3 DEFINE_LOCAL       float.ptr(16, AddrSpace.LOCAL)                    =0
    4 DEFINE_REG         float.ptr(1, AddrSpace.REG)                     =0
    5 DEFINE_REG         float.ptr(1, AddrSpace.REG)                     =1
    6 CONST              int                                             =4
    7 SPECIAL            int                          [6]                'gidx0'
    8 INDEX              float.ptr(4)                 [2,7]             
    9 LOAD               float                        [8]               
   10 CONST              int                                             =16
   11 SPECIAL            int                          [10]               'lidx0'
   12 CONST              int                                             =0
   13 INDEX              float.ptr(1, AddrSpace.REG)  [4,12]            
   14 CONST              int                                             =6
   15 SHL                int                          [7,14]            
   16 CONST              int                                             =2
   17 SHL                int                          [11,16]           
   18 CONST              float                                           =0.0
   19 STORE              void                         [13,18]           
   20 RANGE              int                          [6]                (0, AxisType.REDUCE)
   21 AFTER              float.ptr(1, AddrSpace.REG)  [4,19,20]         
   22 INDEX              float.ptr(1, AddrSpace.REG)  [21,12]           
   23 LOAD               float                        [22]              
   24 ADD                int                          [17,20]           
   25 ADD                int                          [24,15]           
   26 INDEX              float.ptr(256)               [1,25]            
   27 LOAD               float                        [26]              
   28 SUB                float                        [27,9]            
   29 MUL                float                        [28,28]           
   30 ADD                float                        [23,29]           
   31 STORE              void                         [13,30]           
   32 END                void                         [31,20]           
   33 AFTER              float.ptr(1, AddrSpace.REG)  [4,32]            
   34 INDEX              float.ptr(1, AddrSpace.REG)  [33,12]           
   35 LOAD               float                        [34]              
   36 INDEX              float.ptr(16, AddrSpace.LOCAL) [3,11]            
   37 STORE              void                         [36,35]           
   38 BARRIER            void                         [37]              
   39 AFTER              float.ptr(16, AddrSpace.LOCAL) [3,38]            
   40 INDEX              float.ptr(1, AddrSpace.REG)  [5,12]            
   41 STORE              void                         [40,18]           
   42 RANGE              int                          [10,32]            (102, AxisType.REDUCE)
   43 AFTER              float.ptr(1, AddrSpace.REG)  [5,41,42]         
   44 INDEX              float.ptr(1, AddrSpace.REG)  [43,12]           
   45 LOAD               float                        [44]              
   46 INDEX              float.ptr(16, AddrSpace.LOCAL) [39,42]           
   47 LOAD               float                        [46]              
   48 ADD                float                        [45,47]           
   49 STORE              void                         [40,48]           
   50 END                void                         [49,42]           
   51 AFTER              float.ptr(1, AddrSpace.REG)  [5,50]            
   52 INDEX              float.ptr(1, AddrSpace.REG)  [51,12]           
   53 LOAD               float                        [52]              
   54 CMPEQ              bool                         [11,12]           
   55 INDEX              float.ptr(4)                 [0,7,54]          
   56 CONST              float                                           =0.015625
   57 MUL                float                        [53,56]           
   58 CONST              float                                           =1e-05
   59 ADD                float                        [57,58]           
   60 SQRT               float                        [59]              
   61 RECIPROCAL         float                        [60]              
   62 IF                 void                         [54,55]           
   63 STORE              void                         [55,61]           
   64 ENDIF              void                         [62]              
   65 SINK               void                         [63]               KernelInfo(name='r\x1b[90m_\x1b[0m\x1b[34m4\x1b[0m\x1b[90m_\x1b[0m\x1b[91m16\x1b
```
#### `E_4_16_4n1`  gs=[1, 1, 1] ls=[4, 16, 1]
structure: PARAM=4 SINK=1 SPECIAL=2
compute:   ADD=1 CAST=2 CONST=4 GEP=4 INDEX=4 LOAD=3 MUL=4 SHL=2 STORE=1 SUB=4 VECTORIZE=1
```
    0 PARAM              float.ptr(256)                                  =0
    1 PARAM              float.ptr(256)                                  =1
    2 PARAM              float.ptr(4)                                    =2
    3 PARAM              float.ptr(4)                                    =3
    4 CONST              int                                             =4
    5 SPECIAL            int                          [4]                'lidx0'
    6 INDEX              float.ptr(4)                 [2,5]             
    7 LOAD               float                        [6]               
    8 INDEX              float.ptr(4)                 [3,5]             
    9 LOAD               float                        [8]               
   10 CONST              int                                             =16
   11 SPECIAL            int                          [10]               'lidx1'
   12 CONST              int                                             =6
   13 SHL                int                          [5,12]            
   14 CONST              int                                             =2
   15 SHL                int                          [11,14]           
   16 ADD                int                          [13,15]           
   17 INDEX              float.ptr(256)               [1,16]            
   18 CAST               float.vec(4).ptr(256)        [17]              
   19 LOAD               float.vec(4)                 [18]              
   20 GEP                float                        [19]               (0,)
   21 GEP                float                        [19]               (1,)
   22 GEP                float                        [19]               (2,)
   23 GEP                float                        [19]               (3,)
   24 SUB                float                        [20,7]            
   25 MUL                float                        [24,9]            
   26 SUB                float                        [21,7]            
   27 MUL                float                        [26,9]            
   28 SUB                float                        [22,7]            
   29 MUL                float                        [28,9]            
   30 SUB                float                        [23,7]            
   31 MUL                float                        [30,9]            
   32 VECTORIZE          float.vec(4)                 [25,27,29,31]     
   33 INDEX              float.ptr(256)               [0,16]            
   34 CAST               float.vec(4).ptr(256)        [33]              
   35 STORE              void                         [34,32]           
   36 SINK               void                         [35]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m4\x1b[0m\x1b[90m_\x1b[0m\x1b[36m16\x1b
```

**muladd** — `(a*b)+c`
#### `E_16_4n20`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: PARAM=4 SINK=1 SPECIAL=1
compute:   ADD=4 CAST=4 CONST=2 GEP=12 INDEX=4 LOAD=3 MUL=4 SHL=1 STORE=1 VECTORIZE=1
```
    0 PARAM              float.ptr(64)                                   =0
    1 PARAM              float.ptr(64)                                   =1
    2 PARAM              float.ptr(64)                                   =2
    3 PARAM              float.ptr(64)                                   =3
    4 CONST              int                                             =16
    5 SPECIAL            int                          [4]                'lidx0'
    6 CONST              int                                             =2
    7 SHL                int                          [5,6]             
    8 INDEX              float.ptr(64)                [1,7]             
    9 CAST               float.vec(4).ptr(64)         [8]               
   10 LOAD               float.vec(4)                 [9]               
   11 INDEX              float.ptr(64)                [2,7]             
   12 CAST               float.vec(4).ptr(64)         [11]              
   13 LOAD               float.vec(4)                 [12]              
   14 INDEX              float.ptr(64)                [3,7]             
   15 CAST               float.vec(4).ptr(64)         [14]              
   16 LOAD               float.vec(4)                 [15]              
   17 GEP                float                        [10]               (0,)
   18 GEP                float                        [13]               (0,)
   19 GEP                float                        [16]               (0,)
   20 GEP                float                        [10]               (1,)
   21 GEP                float                        [13]               (1,)
   22 GEP                float                        [16]               (1,)
   23 GEP                float                        [10]               (2,)
   24 GEP                float                        [13]               (2,)
   25 GEP                float                        [16]               (2,)
   26 GEP                float                        [10]               (3,)
   27 GEP                float                        [13]               (3,)
   28 GEP                float                        [16]               (3,)
   29 MUL                float                        [17,18]           
   30 ADD                float                        [29,19]           
   31 MUL                float                        [20,21]           
   32 ADD                float                        [31,22]           
   33 MUL                float                        [23,24]           
   34 ADD                float                        [33,25]           
   35 MUL                float                        [26,27]           
   36 ADD                float                        [35,28]           
   37 VECTORIZE          float.vec(4)                 [30,32,34,36]     
   38 INDEX              float.ptr(64)                [0,7]             
   39 CAST               float.vec(4).ptr(64)         [38]              
   40 STORE              void                         [39,37]           
   41 SINK               void                         [40]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m16\x1b[0m\x1b[90m_\x1b[0m\x1b[33m4\x1b
```

---

## Movement

**permute** — `a.permute(1,0).contiguous()`
#### `E_16_4n21`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: PARAM=2 SINK=1 SPECIAL=1
compute:   ADD=3 CAST=1 CONST=4 INDEX=5 LOAD=4 SHL=1 STORE=1 VECTORIZE=1
```
    0 PARAM              float.ptr(64)                                   =0
    1 PARAM              float.ptr(64)                                   =1
    2 CONST              int                                             =16
    3 SPECIAL            int                          [2]                'lidx0'
    4 INDEX              float.ptr(64)                [1,3]             
    5 LOAD               float                        [4]               
    6 ADD                int                          [3,2]             
    7 INDEX              float.ptr(64)                [1,6]             
    8 LOAD               float                        [7]               
    9 CONST              int                                             =32
   10 ADD                int                          [3,9]             
   11 INDEX              float.ptr(64)                [1,10]            
   12 LOAD               float                        [11]              
   13 CONST              int                                             =48
   14 ADD                int                          [3,13]            
   15 INDEX              float.ptr(64)                [1,14]            
   16 LOAD               float                        [15]              
   17 VECTORIZE          float.vec(4)                 [5,8,12,16]       
   18 CONST              int                                             =2
   19 SHL                int                          [3,18]            
   20 INDEX              float.ptr(64)                [0,19]            
   21 CAST               float.vec(4).ptr(64)         [20]              
   22 STORE              void                         [21,17]           
   23 SINK               void                         [22]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m16\x1b[0m\x1b[90m_\x1b[0m\x1b[33m4\x1b
```

**reshape** — `a.reshape(64).contiguous()`
(constant folded — no kernels)

---

## Multi-input

**add3** — `a+b+c`
#### `E_16_4n22`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: PARAM=4 SINK=1 SPECIAL=1
compute:   ADD=8 CAST=4 CONST=2 GEP=12 INDEX=4 LOAD=3 SHL=1 STORE=1 VECTORIZE=1
```
    0 PARAM              float.ptr(64)                                   =0
    1 PARAM              float.ptr(64)                                   =1
    2 PARAM              float.ptr(64)                                   =2
    3 PARAM              float.ptr(64)                                   =3
    4 CONST              int                                             =16
    5 SPECIAL            int                          [4]                'lidx0'
    6 CONST              int                                             =2
    7 SHL                int                          [5,6]             
    8 INDEX              float.ptr(64)                [1,7]             
    9 CAST               float.vec(4).ptr(64)         [8]               
   10 LOAD               float.vec(4)                 [9]               
   11 INDEX              float.ptr(64)                [2,7]             
   12 CAST               float.vec(4).ptr(64)         [11]              
   13 LOAD               float.vec(4)                 [12]              
   14 INDEX              float.ptr(64)                [3,7]             
   15 CAST               float.vec(4).ptr(64)         [14]              
   16 LOAD               float.vec(4)                 [15]              
   17 GEP                float                        [10]               (0,)
   18 GEP                float                        [13]               (0,)
   19 GEP                float                        [16]               (0,)
   20 GEP                float                        [10]               (1,)
   21 GEP                float                        [13]               (1,)
   22 GEP                float                        [16]               (1,)
   23 GEP                float                        [10]               (2,)
   24 GEP                float                        [13]               (2,)
   25 GEP                float                        [16]               (2,)
   26 GEP                float                        [10]               (3,)
   27 GEP                float                        [13]               (3,)
   28 GEP                float                        [16]               (3,)
   29 ADD                float                        [17,18]           
   30 ADD                float                        [20,21]           
   31 ADD                float                        [23,24]           
   32 ADD                float                        [26,27]           
   33 ADD                float                        [29,19]           
   34 ADD                float                        [30,22]           
   35 ADD                float                        [31,25]           
   36 ADD                float                        [32,28]           
   37 VECTORIZE          float.vec(4)                 [33,34,35,36]     
   38 INDEX              float.ptr(64)                [0,7]             
   39 CAST               float.vec(4).ptr(64)         [38]              
   40 STORE              void                         [39,37]           
   41 SINK               void                         [40]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m16\x1b[0m\x1b[90m_\x1b[0m\x1b[33m4\x1b
```

**wsum4** — `a*.25+b*.25+c*.25+d*.25`
#### `E_16_4n23`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: PARAM=5 SINK=1 SPECIAL=1
compute:   ADD=12 CAST=5 CONST=3 GEP=16 INDEX=5 LOAD=4 MUL=16 SHL=1 STORE=1 VECTORIZE=1
```
    0 PARAM              float.ptr(64)                                   =0
    1 PARAM              float.ptr(64)                                   =1
    2 PARAM              float.ptr(64)                                   =2
    3 PARAM              float.ptr(64)                                   =3
    4 PARAM              float.ptr(64)                                   =4
    5 CONST              int                                             =16
    6 SPECIAL            int                          [5]                'lidx0'
    7 CONST              int                                             =2
    8 SHL                int                          [6,7]             
    9 INDEX              float.ptr(64)                [1,8]             
   10 CAST               float.vec(4).ptr(64)         [9]               
   11 LOAD               float.vec(4)                 [10]              
   12 INDEX              float.ptr(64)                [2,8]             
   13 CAST               float.vec(4).ptr(64)         [12]              
   14 LOAD               float.vec(4)                 [13]              
   15 INDEX              float.ptr(64)                [3,8]             
   16 CAST               float.vec(4).ptr(64)         [15]              
   17 LOAD               float.vec(4)                 [16]              
   18 INDEX              float.ptr(64)                [4,8]             
   19 CAST               float.vec(4).ptr(64)         [18]              
   20 LOAD               float.vec(4)                 [19]              
   21 GEP                float                        [11]               (0,)
   22 GEP                float                        [14]               (0,)
   23 GEP                float                        [17]               (0,)
   24 GEP                float                        [20]               (0,)
   25 GEP                float                        [11]               (1,)
   26 GEP                float                        [14]               (1,)
   27 GEP                float                        [17]               (1,)
   28 GEP                float                        [20]               (1,)
   29 GEP                float                        [11]               (2,)
   30 GEP                float                        [14]               (2,)
   31 GEP                float                        [17]               (2,)
   32 GEP                float                        [20]               (2,)
   33 GEP                float                        [11]               (3,)
   34 GEP                float                        [14]               (3,)
   35 GEP                float                        [17]               (3,)
   36 GEP                float                        [20]               (3,)
   37 CONST              float                                           =0.25
   38 MUL                float                        [21,37]           
   39 MUL                float                        [22,37]           
   40 ADD                float                        [38,39]           
   41 MUL                float                        [23,37]           
   42 ADD                float                        [40,41]           
   43 MUL                float                        [24,37]           
   44 ADD                float                        [42,43]           
   45 MUL                float                        [25,37]           
   46 MUL                float                        [26,37]           
   47 ADD                float                        [45,46]           
   48 MUL                float                        [27,37]           
   49 ADD                float                        [47,48]           
   50 MUL                float                        [28,37]           
   51 ADD                float                        [49,50]           
   52 MUL                float                        [29,37]           
   53 MUL                float                        [30,37]           
   54 ADD                float                        [52,53]           
   55 MUL                float                        [31,37]           
   56 ADD                float                        [54,55]           
   57 MUL                float                        [32,37]           
   58 ADD                float                        [56,57]           
   59 MUL                float                        [33,37]           
   60 MUL                float                        [34,37]           
   61 ADD                float                        [59,60]           
   62 MUL                float                        [35,37]           
   63 ADD                float                        [61,62]           
   64 MUL                float                        [36,37]           
   65 ADD                float                        [63,64]           
   66 VECTORIZE          float.vec(4)                 [44,51,58,65]     
   67 INDEX              float.ptr(64)                [0,8]             
   68 CAST               float.vec(4).ptr(64)         [67]              
   69 STORE              void                         [68,66]           
   70 SINK               void                         [69]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m16\x1b[0m\x1b[90m_\x1b[0m\x1b[33m4\x1b
```

---

## Indexing

**arange** — `arange(64).float()`
#### `E_16_4n24`  gs=[1, 1, 1] ls=[16, 1, 1]
structure: PARAM=1 SINK=1 SPECIAL=1
compute:   ADD=3 CAST=5 CONST=4 INDEX=1 SHL=1 STORE=1 VECTORIZE=1
```
    0 PARAM              float.ptr(64)                                   =0
    1 CONST              int                                             =16
    2 SPECIAL            int                          [1]                'lidx0'
    3 CONST              int                                             =2
    4 SHL                int                          [2,3]             
    5 CONST              int                                             =1
    6 ADD                int                          [4,5]             
    7 CAST               float                        [6]               
    8 ADD                int                          [4,3]             
    9 CAST               float                        [8]               
   10 CONST              int                                             =3
   11 ADD                int                          [4,10]            
   12 CAST               float                        [11]              
   13 CAST               float                        [4]               
   14 VECTORIZE          float.vec(4)                 [13,7,9,12]       
   15 INDEX              float.ptr(64)                [0,4]             
   16 CAST               float.vec(4).ptr(64)         [15]              
   17 STORE              void                         [16,14]           
   18 SINK               void                         [17]               KernelInfo(name='E\x1b[90m_\x1b[0m\x1b[36m16\x1b[0m\x1b[90m_\x1b[0m\x1b[33m4\x1b
```

---

## Appendix: What ops reach the renderer

Decomposition is gated by `renderer.code_for_op`. Ops NOT in that dict get
decomposed into primitives before `render()` is called.

**Always present**: SINK PARAM DEFINE_VAR DEFINE_LOCAL DEFINE_REG SPECIAL RANGE END BARRIER INDEX LOAD STORE CONST CAST BITCAST GEP VECTORIZE IF ENDIF

**ALU (if in code_for_op)**: ADD MUL SUB NEG SHL SHR AND OR XOR MOD IDIV CMPLT CMPNE CMPEQ WHERE SQRT RECIPROCAL TRUNC EXP2 LOG2 SIN

**Optional (renderer must opt-in)**: MAX MULACC FDIV THREEFRY POW

**Special**: WMMA (tensor core matmul-accumulate)