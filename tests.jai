#import "Basic";
#import "SIMD";
#import,file "./module.jai";
main :: () {
    print_remembers();
    rename_me_test_1();
    rename_me_test_1(float64);
    rename_me_test_1(int); //kinda useless right? who would use integers nowdays?
    // rename_me_test_1(u32);  maybe for RGBA? I dont care, I would do a different module for RGBA math.
}

print_remembers :: () {
log("[remember] In simd its read from right to left, rightmost is 0 leftomst is 4 || 8 || 16");
};
broadcast_for_tests :: (a: *$T/SIMD_Array, val: a.type) {
    for i: 0..a.count-1 a.*[i] = val;
}

broadcast_for_tests_interleave :: (a: *$T/SIMD_Array, val: a.type, $step:= 1, $offset:= 0) {
    for i: 0..a.count-1 {
        if i % (step) != 0 then continue;
        idx_to_use := i - offset;
        if idx_to_use > a.count-1 then continue;
        if idx_to_use < 0 then continue;
        a.*[idx_to_use] = val;
    }
}

rename_me_test_1 :: ($type: Type = float32) #no_abc {
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