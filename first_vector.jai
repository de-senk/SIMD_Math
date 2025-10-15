

#import "Compiler";
#import "Basic";
#import "Process";
#import "File";

#import "Metaprogram_Plugins";

OUTPUT_EXECUTABLE_NAME :: "tests_vector";
OUTPUT_EXECUTABLE_NAME_WITH_EXYENSION :: "tests_vector.exe";
OUTPUT_BUILD_DIR :: "./";
FILE_ENTRY_POINT :: "./tests.jai";
// FOR_CODEX :: true;

#run {
    set_build_options_dc(.{do_output = false});
    current_w := get_current_workspace();
    w := compiler_create_workspace("Target Programm");
    options := get_build_options(w);
    copy_commonly_propagated_fields(get_build_options(), *options);
    options.output_executable_name = OUTPUT_EXECUTABLE_NAME;
    options.output_path = OUTPUT_BUILD_DIR;

    // set_optimization(*options,.VERY_OPTIMIZED, true); //to force vectorizations
        options.llvm_options.command_line = string.[
            OUTPUT_EXECUTABLE_NAME_WITH_EXYENSION,                  // your .exe name (can be any string as far as i can tell)
            // "-version",                    // display LLVM version info
            // "--help-list-hidden",          // show advanced LLVM help
            "--pass-remarks=vector",            // dump info about all optimizations
            // "--pass-remarks-missed=vector",    // dump info about missed optimizations
            "--pass-remarks-analysis=vector",  // dump analysis
            // "-debug-pass=Arguments",       // Various LLVM pass reports that work
            // "-debug-pass=Structure",       // Various LLVM pass reports that work
            // "-debug-pass=Executions",      // Various LLVM pass reports that work
            // "-debug-pass=Details",         // Various LLVM pass reports that work
        ];

    set_build_options(options, w);
    add_build_file(FILE_ENTRY_POINT,w); //compilin starts here on another thread process

}