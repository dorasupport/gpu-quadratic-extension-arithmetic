#include <cstdio>
#include <cstring>
#include <cassert>

#include "fixnum/warp_fixnum.cu"
#include "array/fixnum_array.h"
#include "functions/modexp.cu"
#include "functions/multi_modexp.cu"
#include "modnum/modnum_monty_redc.cu"
#include "modnum/modnum_monty_cios.cu"

using namespace std;
using namespace cuFIXNUM;

namespace MNT_G{
template< typename fixnum >
class mnt4_g1 {
public:
__device__ void dump(fixnum n, int size) {
#if 0
	for (int i = 0; i < size; i++) {
		printf("DUMP [%d] %x\n", i, fixnum::get(n, i));
	}
#endif
	printf("dump [%d]=\%x\n", threadIdx.x, fixnum::get(n, threadIdx.x));
}

static __device__ void pq_plus(fixnum mod, fixnum x1, fixnum y1, fixnum z1, fixnum x2, fixnum y2, fixnum z2, fixnum &x3, fixnum &y3, fixnum &z3) {
    if (fixnum::is_zero(x1) && fixnum::is_zero(z1)) {
        x3 = x2;
        y3 = y2;
        z3 = z2;
        return;
    }
    if (fixnum::is_zero(x2) && fixnum::is_zero(z2)) {
        x3 = x1;
        y3 = y1;
        z3 = z1;
        return;
    }
    typedef modnum_monty_cios<fixnum> modnum;
    modnum m(mod);
    fixnum y1z2, x1z2, z1z2, y2z1, x2z1;

    // y1z2
    m.mul(y1z2, y1, z2);

    // x1z2
    m.mul(x1z2, x1, z2);

    // z1z2
    m.mul(z1z2, z1, z2);

    // y2z1
    m.mul(y2z1, y2, z1);

    // x2z1
    m.mul(x2z1, x2, z1);

    fixnum u;
    // u = Y2Z1-Y1Z2
    m.sub(u, y2z1, y1z2);
    //fixnum::sub(u, y2z1, y1z2);

    fixnum uu;
    // uu = u*u
    m.mul(uu, u, u);

    fixnum v;
    // v = X2Z1-X1Z2
    m.sub(v, x2z1, x1z2);
    //fixnum::sub(v, x2z1, x1z2);

    fixnum vv;
    // vv = v*v
    m.mul(vv, v, v);

    fixnum vvv;
    // vvv = v*vv
    m.mul(vvv, v, vv);

    fixnum R;
    // R = vv * X1Z2
    m.mul(R, vv, x1z2);

    fixnum A;
    // A = uu * Z1Z2 - vvv - 2R
    m.mul(A, uu, z1z2);
    m.sub(A, A, vvv);
    m.sub(A, A, R);
    m.sub(A, A, R);

    // x3 = v*A
    m.mul(x3, v, A);

    // y3 = u*(R-A)-vvv*Y1Z2
    fixnum temp;
    m.sub(temp, R, A);
    m.mul(temp, u, temp);
    fixnum temp2;
    m.mul(temp2, vvv, y1z2);
    m.sub(y3, temp, temp2);

    // z3 = vvv*Z1Z2
    m.mul(z3, vvv, z1z2);
}

static __device__ void p_double(fixnum mod, fixnum a, fixnum x1, fixnum y1, fixnum z1, fixnum &x3, fixnum &y3, fixnum &z3) {
    if (fixnum::is_zero(x1) && fixnum::is_zero(z1)) {
        x3 = x1;
        y3 = y1;
        z3 = z1;
        return;
    }
    typedef modnum_monty_cios<fixnum> modnum;
    modnum m(mod);

    fixnum temp, temp2;

    fixnum XX;
    // XX = X1*X1
    m.mul(XX, x1, x1);

    fixnum ZZ;
    // ZZ = Z1*Z1
    m.mul(ZZ, z1, z1);

    fixnum w;
    // w = a*ZZ+3*XX    a = 2
    m.add(temp, ZZ, ZZ);
    m.add(temp2, XX, XX);
    m.add(temp2, temp2, XX);
    m.add(w, temp, temp2);

    fixnum s;
    // s = 2*Y1*Z1
    m.mul(temp, y1, z1);
    m.add(s, temp, temp);

    fixnum ss;
    // ss = s*s
    m.mul(ss, s, s);

    fixnum sss;
    // sss = s * ss
    m.mul(sss, s, ss);

    fixnum R;
    // R = y1 * s
    m.mul(R, y1, s);

    fixnum RR;
    // RR = R * R
    m.mul(RR, R, R);

    fixnum B;
    // B = (X1+R)2-XX-RR
    m.add(temp, x1, R);
    m.mul(temp2, temp, temp);
    m.sub(temp, temp2, XX);
    m.sub(B, temp, RR);

    fixnum h;
    // h = w*2-2*B
    m.mul(temp, w, w);
    m.add(temp2, B, B);
    m.sub(h, temp, temp2);

    // X3 = h * s
    m.mul(x3, h, s);

    // Y3 = w*(B-h)-2*RR
    m.sub(temp, B, h);
    m.add(temp2, RR, RR);
    m.mul(temp, w, temp);
    m.sub(y3, temp, temp2);

    //  Z3 = sss
    z3 = sss;
}

};
}
