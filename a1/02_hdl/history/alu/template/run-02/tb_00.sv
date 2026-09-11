`timescale 1ns/1ps

module alu_tb;

    // DUT interface signals
    logic [31:0] A;
    logic [31:0] B;
    logic [2:0]  ALUSelect;
    logic        SubArith;
    logic [31:0] ALUResult;
    logic [31:0] Sum;

    // Scoreboard counters required by prompt
    integer passed;
    integer failed;
    integer total;
    integer fail_prints;

    // Instantiate DUT using named ports
    alu dut (
        .A(A),
        .B(B),
        .ALUSelect(ALUSelect),
        .SubArith(SubArith),
        .ALUResult(ALUResult),
        .Sum(Sum)
    );

    // Reference model for Sum output, defined for all input combinations
    function automatic logic [31:0] exp_sum(
        input logic [31:0] a,
        input logic [31:0] b,
        input logic        subarith
    );
        begin
            if (subarith)
                exp_sum = a - b;
            else
                exp_sum = a + b;
        end
    endfunction

    // Reference model for ALUResult only on defined operation encodings.
    // valid=1 means the specification defines ALUResult for this encoding.
    task automatic exp_alu(
        input  logic [31:0] a,
        input  logic [31:0] b,
        input  logic [2:0]  sel,
        input  logic        subarith,
        output logic [31:0] result,
        output logic        valid
    );
        begin
            valid  = 1'b1;
            result = 32'h00000000;
            case (sel)
                3'b000: begin
                    if (subarith) result = a - b;
                    else          result = a + b;
                end
                3'b001: begin
                    if (!subarith) result = a << b[4:0];
                    else           valid  = 1'b0;
                end
                3'b010: begin
                    if (subarith) result = ($signed(a) < $signed(b)) ? 32'h00000001 : 32'h00000000;
                    else          valid  = 1'b0;
                end
                3'b011: begin
                    if (subarith) result = (a < b) ? 32'h00000001 : 32'h00000000;
                    else          valid  = 1'b0;
                end
                3'b100: begin
                    if (!subarith) result = a ^ b;
                    else           valid  = 1'b0;
                end
                3'b101: begin
                    if (subarith) result = $signed(a) >>> b[4:0];
                    else          result = a >> b[4:0];
                end
                3'b110: begin
                    if (!subarith) result = a | b;
                    else           valid  = 1'b0;
                end
                3'b111: begin
                    if (!subarith) result = a & b;
                    else           valid  = 1'b0;
                end
                default: begin
                    valid = 1'b0;
                end
            endcase
        end
    endtask

    // Bounded failure reporting: first eight only
    task automatic report_fail(
        input [8*32-1:0] label,
        input logic [31:0] actual,
        input logic [31:0] expected
    );
        begin
            if (fail_prints < 8) begin
                $display("FAIL %0s A=%h B=%h ALUSelect=%b SubArith=%b actual=%h expected=%h",
                         label, A, B, ALUSelect, SubArith, actual, expected);
            end
            fail_prints = fail_prints + 1;
        end
    endtask

    task automatic check_eq(
        input [8*32-1:0] label,
        input logic [31:0] actual,
        input logic [31:0] expected
    );
        begin
            total = total + 1;
            if (actual === expected) begin
                passed = passed + 1;
            end
            else begin
                failed = failed + 1;
                report_fail(label, actual, expected);
            end
        end
    endtask

    // Apply one vector, allow combinational settling, then check every defined output.
    // ALUResult is checked only for defined encodings; Sum is always checked.
    task automatic apply_and_check(
        input [8*32-1:0] label,
        input logic [31:0] a,
        input logic [31:0] b,
        input logic [2:0]  sel,
        input logic        subarith
    );
        logic [31:0] expected_sum;
        logic [31:0] expected_res;
        logic        valid_res;
        begin
            A         = a;
            B         = b;
            ALUSelect = sel;
            SubArith  = subarith;

            // Combinational settling
            #1;

            expected_sum = exp_sum(a, b, subarith);
            exp_alu(a, b, sel, subarith, expected_res, valid_res);

            if (valid_res)
                check_eq({label, "_ALUResult"}, ALUResult, expected_res);

            check_eq({label, "_Sum"}, Sum, expected_sum);
        end
    endtask

    // Deterministic local PRNG for additional coverage
    function automatic logic [31:0] next_prng(input logic [31:0] state);
        begin
            next_prng = state ^ (state << 13);
            next_prng = next_prng ^ (next_prng >> 17);
            next_prng = next_prng ^ (next_prng << 5);
        end
    endfunction

    // Watchdog required by prompt
    initial begin
        #10000;
        $display("FAIL");
        $finish;
    end

    integer i;
    integer j;
    logic [31:0] seed;
    logic [31:0] shamt_word;
    logic [31:0] base_a [0:11];
    logic [31:0] base_b [0:11];

    initial begin
        passed      = 0;
        failed      = 0;
        total       = 0;
        fail_prints = 0;

        A         = 32'h00000000;
        B         = 32'h00000000;
        ALUSelect = 3'b000;
        SubArith  = 1'b0;

        // Coverage notes:
        // - Sample vectors from specification are checked explicitly.
        // - Every defined operation/class is exercised.
        // - Sum is checked on every vector, independent of ALUResult.
        // - Corner cases include zero, all ones, signed boundaries, wraparound.
        // - Shift masking uses B values where upper bits differ but B[4:0] matches.
        // - Illegal encodings are exercised only for Sum, because ALUResult is unspecified there.

        // Sample usage cases from the spec
        apply_and_check("sample_add", 32'h0000000A, 32'h00000003, 3'b000, 1'b0);
        apply_and_check("sample_sub", 32'h0000000A, 32'h00000003, 3'b000, 1'b1);
        apply_and_check("sample_slt", 32'hFFFFFFFF, 32'h00000001, 3'b010, 1'b1);
        apply_and_check("sample_sltu", 32'hFFFFFFFF, 32'h00000001, 3'b011, 1'b1);
        apply_and_check("sample_sra", 32'h80000000, 32'h00000001, 3'b101, 1'b1);
        apply_and_check("sample_sll31", 32'h0000000F, 32'h0000001F, 3'b001, 1'b0);

        // Arithmetic corner cases and wraparound
        apply_and_check("add_zero_zero",        32'h00000000, 32'h00000000, 3'b000, 1'b0);
        apply_and_check("add_wrap",             32'hFFFFFFFF, 32'h00000001, 3'b000, 1'b0);
        apply_and_check("add_signed_boundary",  32'h7FFFFFFF, 32'h00000001, 3'b000, 1'b0);
        apply_and_check("sub_self",             32'h12345678, 32'h12345678, 3'b000, 1'b1);
        apply_and_check("sub_underflow",        32'h00000000, 32'h00000001, 3'b000, 1'b1);
        apply_and_check("sum_indep_xor_sub0",   32'h13579BDF, 32'h2468ACE0, 3'b100, 1'b0);
        apply_and_check("sum_indep_xor_sub1",   32'h13579BDF, 32'h2468ACE0, 3'b100, 1'b1);
        apply_and_check("sum_indep_and_sub1",   32'hAAAAAAAA, 32'h55555555, 3'b111, 1'b1);

        // Logical operations
        apply_and_check("xor_basic",    32'h55AA55AA, 32'h0F0FF0F0, 3'b100, 1'b0);
        apply_and_check("or_basic",     32'h12340000, 32'h00005678, 3'b110, 1'b0);
        apply_and_check("and_basic",    32'hFFFF0000, 32'h0F0FF0F0, 3'b111, 1'b0);
        apply_and_check("xor_allones",  32'hFFFFFFFF, 32'hFFFFFFFF, 3'b100, 1'b0);
        apply_and_check("or_zero",      32'h00000000, 32'h89ABCDEF, 3'b110, 1'b0);
        apply_and_check("and_zero",     32'h89ABCDEF, 32'h00000000, 3'b111, 1'b0);

        // Comparison operations including signed boundaries
        apply_and_check("slt_neg_pos",      32'h80000000, 32'h00000000, 3'b010, 1'b1);
        apply_and_check("slt_pos_neg",      32'h00000000, 32'h80000000, 3'b010, 1'b1);
        apply_and_check("slt_equal",        32'h80000000, 32'h80000000, 3'b010, 1'b1);
        apply_and_check("sltu_low_high",    32'h00000000, 32'hFFFFFFFF, 3'b011, 1'b1);
        apply_and_check("sltu_high_low",    32'hFFFFFFFF, 32'h00000000, 3'b011, 1'b1);
        apply_and_check("sltu_equal",       32'h12345678, 32'h12345678, 3'b011, 1'b1);
        apply_and_check("slt_minus1_min",   32'hFFFFFFFF, 32'h80000000, 3'b010, 1'b1);
        apply_and_check("sltu_minus1_min",  32'hFFFFFFFF, 32'h80000000, 3'b011, 1'b1);

        // Shift operations and masking with B[4:0]
        apply_and_check("sll_sh0",      32'h00000001, 32'h00000000, 3'b001, 1'b0);
        apply_and_check("sll_sh1",      32'h00000001, 32'h00000001, 3'b001, 1'b0);
        apply_and_check("sll_sh31",     32'h00000001, 32'h0000001F, 3'b001, 1'b0);
        apply_and_check("srl_sh0",      32'h80000000, 32'h00000000, 3'b101, 1'b0);
        apply_and_check("srl_sh31",     32'h80000000, 32'h0000001F, 3'b101, 1'b0);
        apply_and_check("sra_sh0",      32'h80000001, 32'h00000000, 3'b101, 1'b1);
        apply_and_check("sra_sh31",     32'h80000001, 32'h0000001F, 3'b101, 1'b1);
        apply_and_check("sra_pos",      32'h7FFFFFFF, 32'h00000004, 3'b101, 1'b1);

        // Explicit shift-mask checks: upper bits of B must be ignored
        apply_and_check("sll_mask32",   32'h00000001, 32'h00000020, 3'b001, 1'b0); // same as shamt 0
        apply_and_check("sll_mask33",   32'h00000001, 32'h00000021, 3'b001, 1'b0); // same as shamt 1
        apply_and_check("sll_mask255",  32'h00000003, 32'h000000FF, 3'b001, 1'b0); // same as shamt 31
        apply_and_check("srl_mask63",   32'hF0000000, 32'h0000003F, 3'b101, 1'b0); // same as shamt 31
        apply_and_check("sra_mask63",   32'hF0000000, 32'h0000003F, 3'b101, 1'b1); // same as shamt 31
        apply_and_check("sra_mask40",   32'h80000000, 32'h00000028, 3'b101, 1'b1); // same as shamt 8

        // Illegal encodings: only defined behavior is Sum, so check only Sum
        apply_and_check("ill_001_1", 32'h12345678, 32'h9ABCDEF0, 3'b001, 1'b1);
        apply_and_check("ill_010_0", 32'h12345678, 32'h9ABCDEF0, 3'b010, 1'b0);
        apply_and_check("ill_011_0", 32'h12345678, 32'h9ABCDEF0, 3'b011, 1'b0);
        apply_and_check("ill_100_1", 32'h12345678, 32'h9ABCDEF0, 3'b100, 1'b1);
        apply_and_check("ill_110_1", 32'h12345678, 32'h9ABCDEF0, 3'b110, 1'b1);
        apply_and_check("ill_111_1", 32'h12345678, 32'h9ABCDEF0, 3'b111, 1'b1);

        // Small systematic sweep over shift amounts 0..31 without slicing parenthesized expressions
        for (i = 0; i < 32; i = i + 1) begin
            shamt_word = i;
            apply_and_check("sll_sweep", 32'hA5A5A5A5, shamt_word, 3'b001, 1'b0);
            apply_and_check("srl_sweep", 32'hA5A5A5A5, shamt_word, 3'b101, 1'b0);
            apply_and_check("sra_sweep", 32'hA5A5A5A5, shamt_word, 3'b101, 1'b1);
        end

        // Base corner-value sets for broad deterministic coverage
        base_a[0]  = 32'h00000000;
        base_a[1]  = 32'h00000001;
        base_a[2]  = 32'hFFFFFFFF;
        base_a[3]  = 32'h7FFFFFFF;
        base_a[4]  = 32'h80000000;
        base_a[5]  = 32'h80000001;
        base_a[6]  = 32'h55555555;
        base_a[7]  = 32'hAAAAAAAA;
        base_a[8]  = 32'h12345678;
        base_a[9]  = 32'h89ABCDEF;
        base_a[10] = 32'h0000FFFF;
        base_a[11] = 32'hFFFF0000;

        base_b[0]  = 32'h00000000;
        base_b[1]  = 32'h00000001;
        base_b[2]  = 32'h0000001F;
        base_b[3]  = 32'h00000020;
        base_b[4]  = 32'hFFFFFFFF;
        base_b[5]  = 32'h7FFFFFFF;
        base_b[6]  = 32'h80000000;
        base_b[7]  = 32'h55555555;
        base_b[8]  = 32'hAAAAAAAA;
        base_b[9]  = 32'h12345678;
        base_b[10] = 32'h89ABCDEF;
        base_b[11] = 32'h00000004;

        // Cross-product coverage for all defined operation classes on corner values
        for (i = 0; i < 12; i = i + 1) begin
            for (j = 0; j < 12; j = j + 1) begin
                apply_and_check("cp_add",  base_a[i], base_b[j], 3'b000, 1'b0);
                apply_and_check("cp_sub",  base_a[i], base_b[j], 3'b000, 1'b1);
                apply_and_check("cp_sll",  base_a[i], base_b[j], 3'b001, 1'b0);
                apply_and_check("cp_slt",  base_a[i], base_b[j], 3'b010, 1'b1);
                apply_and_check("cp_sltu", base_a[i], base_b[j], 3'b011, 1'b1);
                apply_and_check("cp_xor",  base_a[i], base_b[j], 3'b100, 1'b0);
                apply_and_check("cp_srl",  base_a[i], base_b[j], 3'b101, 1'b0);
                apply_and_check("cp_sra",  base_a[i], base_b[j], 3'b101, 1'b1);
                apply_and_check("cp_or",   base_a[i], base_b[j], 3'b110, 1'b0);
                apply_and_check("cp_and",  base_a[i], base_b[j], 3'b111, 1'b0);
            end
        end

        // Deterministic pseudo-random regression for additional breadth
        seed = 32'h1BADB002;
        for (i = 0; i < 64; i = i + 1) begin
            seed = next_prng(seed); A = seed;
            seed = next_prng(seed); B = seed; #0;
            apply_and_check("rnd_add",  A, B, 3'b000, 1'b0);
            apply_and_check("rnd_sub",  A, B, 3'b000, 1'b1);
            apply_and_check("rnd_sll",  A, B, 3'b001, 1'b0);
            apply_and_check("rnd_slt",  A, B, 3'b010, 1'b1);
            apply_and_check("rnd_sltu", A, B, 3'b011, 1'b1);
            apply_and_check("rnd_xor",  A, B, 3'b100, 1'b0);
            apply_and_check("rnd_srl",  A, B, 3'b101, 1'b0);
            apply_and_check("rnd_sra",  A, B, 3'b101, 1'b1);
            apply_and_check("rnd_or",   A, B, 3'b110, 1'b0);
            apply_and_check("rnd_and",  A, B, 3'b111, 1'b0);

            // Also hit illegal encodings but only for specified Sum behavior
            apply_and_check("rnd_ill1", A, B, 3'b001, 1'b1);
            apply_and_check("rnd_ill2", A, B, 3'b010, 1'b0);
            apply_and_check("rnd_ill3", A, B, 3'b011, 1'b0);
            apply_and_check("rnd_ill4", A, B, 3'b100, 1'b1);
            apply_and_check("rnd_ill5", A, B, 3'b110, 1'b1);
            apply_and_check("rnd_ill6", A, B, 3'b111, 1'b1);
        end

        $display("A1_CHECKS passed=%0d failed=%0d total=%0d", passed, failed, total);
        if ((failed == 0) && (total > 0))
            $display("PASS");
        else
            $display("FAIL");
        $finish;
    end

endmodule
