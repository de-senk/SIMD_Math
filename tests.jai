#import "Basic";
#import "SIMD";
// #import "Math";
#import,file "./module.jai";
main :: () {
    print_remembers();
    test_simd_arrays_operators();
    test_simd_arrays_operators(float64);
    test_simd_arrays_operators(int); //kinda useless right? who would use integers nowdays?
    // test_simd_arrays_operators(u32);  maybe for RGBA? I dont care, I would do a different module for RGBA math.

    //after a lot of testing I realized that if you want to change the type of operation
    //you should change the default Matrix_RC type there, otherwise the code grows and becomes more illegible.
    test_matrix_rc_arrays_operators(Matrix_RC(1,1).type); //we use the default type as test case
    // test_matrix_rc_arrays_operators();
    // test_matrix_rc_arrays_operators(float64);
    // test_matrix_rc_arrays_operators(int);
    // test_matrix_rc_arrays_operators(u32);
}

print_remembers :: () {
    log("[remember] In simd its read from right to left, rightmost is 0 leftomst is 4 || 8 || 16");
};

broadcast_for_tests :: (a: *$T/SIMD_Array, $val: a.type) {
    insert_expansion :: ($count: int, val : $SIMD_type) -> string{
          the_code :=#string JAI
               a.*[%1] = %2;
            JAI
        sb: String_Builder;
        for it_index: 0..count-1{
            print_to_builder(*sb, the_code, it_index, val);
        }
        return builder_to_string(*sb);
    }
    #insert #run insert_expansion(a.count, val);
    // for i: 0..a.count-1 {
    //     a.*[i] = val;
    // }
}

broadcast_for_tests_interleave :: (a: *$T/SIMD_Array, $val: a.type, $step:= 1, $offset:= 0) {
    // for i: 0..a.count-1 {
    //     if i % (step) != 0 then continue;
    //     idx_to_use := i - offset;
    //     if idx_to_use > a.count-1 then continue;
    //     if idx_to_use < 0 then continue;
    //     a.*[idx_to_use] = val;
    // }

    insert_expansion :: ($count: int, val : $SIMD_type) -> string{
      the_code :=#string JAI
           a.*[%1] = %2;
        JAI
    sb: String_Builder;
    for i: 0..count-1{
        if i % (step) != 0 then continue;
        idx_to_use := i - offset;
        if idx_to_use > a.count-1 then continue;
        if idx_to_use < 0 then continue;
        print_to_builder(*sb, the_code, idx_to_use, val);
    }
    return builder_to_string(*sb);
}

    #insert #run insert_expansion(a.count, val);

}



test_simd_arrays_operators :: ($type: Type = float32) {
    log("\n[TEST] type==%",type);
    a: SIMD_Array(5, type);
    b: SIMD_Array(5, type);

    {
    //check indexings
    a[4] += 13;
    a[3] = 1;
    // a[-1] = 1; //#no_abc risk
    assert(a[4] == 13);
    assert(a[3] == 1);
    }

    {
    // log("\ncheck dot product");
    broadcast_for_tests(*b, 1);
    broadcast_for_tests(*a, 1);
    broadcast_for_tests_interleave(*a, -1, step=2);
    broadcast_for_tests_interleave(*b, -1, step=2, offset=1);
    // log("a: %1\nb: %2",a, b);
    r := dot(a,b);
    assert(r==-5, "dot(a,b)== %", r);
    // log("dot(a,b)==%",r);
    }

    #if type == float32 || type == float64
    {
    // log("\n check is_valid, TODO: meh,");
    c: SIMD_Array(5, type);
    assert(is_valid(c));
    //more than 7 zeros
    Inf := cast(type)0h7FFFFFFF_FFFFFFFF;
    /*
    FLOAT32_MIN        :: 0h00800000;
    FLOAT32_MAX        :: 0h7F7FFFFF;
    FLOAT32_INFINITY   :: 0h7F800000;
    FLOAT32_NAN        :: 0h7FBFFFFF;

    FLOAT64_MIN        :: 0h00100000_00000000;
    FLOAT64_MAX        :: 0h7FEFFFFF_FFFFFFFF;
    FLOAT64_INFINITY   :: 0h7FF00000_00000000;
    FLOAT64_NAN        :: 0h7FF7FFFF_FFFFFFFF;
    */
    c[4] = c[4]/Inf;//+NaN;
    c[3] = -c[4]/Inf;//-NaN;
    c[2] = Inf/c[2];
    c[1] = Inf/Inf;
    c[0] = -Inf/Inf;
    assert(!is_valid(c), "!%",c);
    }

    {
    // log("\n check biggest procs");
    a[4] = -13;
    a[2] = 5;
    biggest_component, idx :=  abs_biggest(a);
    most_positive, idx2 :=  biggest(a);
    assert(biggest_component==-13 && idx==4, "absoulte biggest is not -13 == % idx== %", biggest_component, idx);
    assert(most_positive==5 && idx2 == 2 , " biggest is not 13 == %, idx2==%", most_positive,idx2);
    }


}




test_matrix_rc_arrays_operators :: ($type: Type ) #no_abc {
    log("\n[TEST] type==%",type);
    a: Matrix_RC(4,4,type);
    b: Matrix_RC(4,4,type);


    {
    //set digonals
    a.coef[0][0] = 1;
    a.coef[1][1] = 2;
    a.coef[2][2] = 3;
    a.coef[3][3] = 4;
    a_is_converging, bad_row := converges(a);
    assert(a_is_converging, "doesnt converge->%", a);

    //test non strict convergence
    a.v[2][3] = 3;
    a_is_converging, bad_row = converges(a);
    assert(a_is_converging, "a bad row % converges->%",bad_row, a);
    a.v[2][3] = 4;
    a_is_converging, bad_row = converges(a);
    assert(!a_is_converging, "a bad row % converges->%",bad_row, a);

    //strict covnergence
    a.v[2][3] = 3;
    a_is_converging, bad_row = converges(a,strict=true);
    assert(!a_is_converging, "doesnt strictly converge->%", a);
    }

    {
    set_diagonals_broadcast(*a,0);
    assert(diagonals_are_zero(a), "diagonals_are_zero: %",a);
    set_diagonals_broadcast(*a,7);
    assert(!diagonals_are_zero(a), "diagonals_are_zero: %",a);
    }


    {
    //J: Jacobian, Jt: Jacobian_transposed, W: Effective Mass 1/(mass + Inertia from center of mass)
    //W is effective massfirst 6 are for Body 1, next 6 are for body 2
    W: Matrix_RC(12,12,type);
    set_diagonals_broadcast(*W, 1);

    J: Matrix_RC(3, 12, type); //idx:0 is normal, 1 is tangent1, 2 is tangent2
    #assert(J.type == type);
    broadcast_for_tests(*J.v[0], 2);
    broadcast_for_tests(*J.v[1], 5);
    broadcast_for_tests(*J.v[2], 1);
    broadcast_for_tests_interleave(*J.v[0], -1, step=2, offset=2);
    broadcast_for_tests_interleave(*J.v[1], -15, step=2, offset=1);
    broadcast_for_tests_interleave(*J.v[2], -1, step=2, offset=3);

    #assert(type_of(J).COL == 12);
    Jt := transpose(J);
    #assert(type_of(Jt).ROW == 12);
    #assert(Jt.type == type);
    W_Jt := W * Jt;
     #assert(type_of(W_Jt).ROW == 12);
    J_W_Jt :=  J * W * Jt;

    vels: SIMD_Array(12, J.type);
    broadcast_for_tests(*vels, 2);
    broadcast_for_tests_interleave(*vels, -1, step=2, offset=1);
    baumgarte: SIMD_Array(3, J.type);
    rhs :=  J * vels * -1 ;
    rhs[0] -= baumgarte[0];
    #assert(rhs.type == type);
    log("\n[LCP_Gauss_Seidel]");
    lambdas := LCP_Gauss_Seidel(J_W_Jt, rhs, iterations = 1);
    log("iterations = 1 lamdbas %", lambdas);
    lambdas = LCP_Gauss_Seidel(J_W_Jt, rhs, iterations = 2);
    log("iterations = 2 lamdbas %", lambdas);
    lambdas = LCP_Gauss_Seidel(J_W_Jt, rhs, iterations = 3);
    log("iterations = 3 lamdbas %", lambdas);
    lambdas = LCP_Gauss_Seidel(J_W_Jt, rhs, iterations = 4);
    log("iterations = 4 lamdbas %", lambdas);
    lambdas = LCP_Gauss_Seidel(J_W_Jt, rhs, iterations = 8);
    log("iterations = 8 lamdbas %", lambdas);
    lambdas = LCP_Gauss_Seidel(J_W_Jt, rhs, iterations = 16);
    log("iterations = 16 lamdbas %", lambdas);
    lambdas = LCP_Gauss_Seidel(J_W_Jt, rhs, iterations = 32);
    log("iterations = 32 lamdbas %", lambdas);
    lambdas = LCP_Gauss_Seidel(J_W_Jt, rhs, iterations = 64);
    log("iterations = 64 lamdbas %", lambdas);
    }
}