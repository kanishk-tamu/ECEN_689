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

    // Watchdog
    initial begin
        #100000;
        $display("FAIL");
        $finish;
    end

    // Instantiate DUT using named ports
    alu dut (
        .A(A),
        .B(B),
        .ALUSelect(ALUSelect),
        .SubArith(SubArith),
        .ALUResult(ALUResult),
        .Sum(Sum)
    );

    // Reference model for Sum output, defined for all inputs
    function automatic logic [31:0] exp_sum(
        input logic [31:0] a,
        input logic [31:0] b,
        input logic        sub
    );
        begin
            if (sub)
                exp_sum = a - b;
            else
                exp_sum = a + b;
        end
    endfunction

    // Reference model for ALUResult only on defined encodings from specification.
    // For undefined encodings the caller must not compare ALUResult.
    function automatic logic [31:0] exp_result(
        input logic [31:0] a,
        input logic [31:0] b,
        input logic [2:0]  sel,
        input logic        sub
    );
        logic signed [31:0] sa;
        logic signed [31:0] sb;
        logic [4:0] shamt;
        begin
            sa = a;
            sb = b;
            shamt = b[4:0];
            exp_result = 32'hxxxxxxxx;
            case (sel)
                3'b000: begin
                    if (sub) exp_result = a - b;
                    else     exp_result = a + b;
                end
                3'b001: begin
                    if (!sub) exp_result = a << shamt;
                end
                3'b010: begin
                    if (sub) exp_result = (sa < sb) ? 32'h00000001 : 32'h00000000;
                end
                3'b011: begin
                    if (sub) exp_result = (a < b) ? 32'h00000001 : 32'h00000000;
                end
                3'b100: begin
                    if (!sub) exp_result = a ^ b;
                end
                3'b101: begin
                    if (sub) exp_result = sa >>> shamt;
                    else     exp_result = a >> shamt;
                end
                3'b110: begin
                    if (!sub) exp_result = a | b;
                end
                3'b111: begin
                    if (!sub) exp_result = a & b;
                end
            endcase
        end
    endfunction

    function automatic bit is_defined_result(
        input logic [2:0] sel,
        input logic       sub
    );
        begin
            is_defined_result = 1'b0;
            case (sel)
                3'b000: is_defined_result = 1'b1;          // ADD/SUB both defined
                3'b001: is_defined_result = (sub == 1'b0); // SLL
                3'b010: is_defined_result = (sub == 1'b1); // SLT
                3'b011: is_defined_result = (sub == 1'b1); // SLTU
                3'b100: is_defined_result = (sub == 1'b0); // XOR
                3'b101: is_defined_result = 1'b1;          // SRL/SRA both defined
                3'b110: is_defined_result = (sub == 1'b0); // OR
                3'b111: is_defined_result = (sub == 1'b0); // AND
                default: is_defined_result = 1'b0;
            endcase
        end
    endfunction

    task automatic record_check(
        input string       label,
        input logic [31:0] actual,
        input logic [31:0] expected,
        input logic [31:0] a,
        input logic [31:0] b,
        input logic [2:0]  sel,
        input logic        sub
    );
        begin
            total = total + 1;
            if (actual === expected) begin
                passed = passed + 1;
            end
            else begin
                failed = failed + 1;
                if (fail_prints < 8) begin
                    $display("FAIL %s A=%h B=%h ALUSelect=%b SubArith=%b actual=%h expected=%h",
                             label, a, b, sel, sub, actual, expected);
                    fail_prints = fail_prints + 1;
                end
            end
        end
    endtask

    task automatic apply_and_check(
        input string       label,
        input logic [31:0] a,
        input logic [31:0] b,
        input logic [2:0]  sel,
        input logic        sub,
        input bit          check_result
    );
        logic [31:0] expected_sum;
        logic [31:0] expected_result;
        begin
            A = a;
            B = b;
            ALUSelect = sel;
            SubArith = sub;

            // Allow combinational settling
            #1;

            expected_sum = exp_sum(a, b, sub);
            record_check({label, ".Sum"}, Sum, expected_sum, a, b, sel, sub);

            if (check_result) begin
                expected_result = exp_result(a, b, sel, sub);
                record_check({label, ".ALUResult"}, ALUResult, expected_result, a, b, sel, sub);
            end
        end
    endtask

    task automatic check_defined(
        input string       label,
        input logic [31:0] a,
        input logic [31:0] b,
        input logic [2:0]  sel,
        input logic        sub
    );
        begin
            apply_and_check(label, a, b, sel, sub, 1'b1);
        end
    endtask

    task automatic check_illegal_encoding(
        input string       label,
        input logic [31:0] a,
        input logic [31:0] b,
        input logic [2:0]  sel,
        input logic        sub
    );
        begin
            // Only Sum is defined for all inputs; ALUResult is unspecified on illegal encodings.
            apply_and_check(label, a, b, sel, sub, 1'b0);
        end
    endtask

    integer i;
    integer j;
    integer seed;
    logic [31:0] ra;
    logic [31:0] rb;
    logic [31:0] temp_b;

    initial begin
        passed = 0;
        failed = 0;
        total = 0;
        fail_prints = 0;

        A = 32'h0;
        B = 32'h0;
        ALUSelect = 3'b000;
        SubArith = 1'b0;

        #1;

        // Sample cases from specification
        check_defined("sample_add", 32'h0000000A, 32'h00000003, 3'b000, 1'b0);
        check_defined("sample_sub", 32'h0000000A, 32'h00000003, 3'b000, 1'b1);
        check_defined("sample_slt", 32'hFFFFFFFF, 32'h00000001, 3'b010, 1'b1);
        check_defined("sample_sltu", 32'hFFFFFFFF, 32'h00000001, 3'b011, 1'b1);
        check_defined("sample_sra", 32'h80000000, 32'h00000001, 3'b101, 1'b1);
        check_defined("sample_sll31", 32'h0000000F, 32'h0000001F, 3'b001, 1'b0);

        // Arithmetic coverage: zero, all ones, modular wraparound, signed boundaries
        check_defined("add_zero_zero",     32'h00000000, 32'h00000000, 3'b000, 1'b0);
        check_defined("add_wrap",          32'hFFFFFFFF, 32'h00000001, 3'b000, 1'b0);
        check_defined("add_signed_edge",   32'h7FFFFFFF, 32'h00000001, 3'b000, 1'b0);
        check_defined("add_neg_boundary",  32'h80000000, 32'h80000000, 3'b000, 1'b0);
        check_defined("sub_zero_zero",     32'h00000000, 32'h00000000, 3'b000, 1'b1);
        check_defined("sub_borrow",        32'h00000000, 32'h00000001, 3'b000, 1'b1);
        check_defined("sub_self",          32'hDEADBEEF, 32'hDEADBEEF, 3'b000, 1'b1);
        check_defined("sub_wrap",          32'h80000000, 32'h00000001, 3'b000, 1'b1);

        // Shift coverage: all relevant classes, masking by B[4:0], zero and 31 shifts
        check_defined("sll_0",             32'h12345678, 32'h00000000, 3'b001, 1'b0);
        check_defined("sll_4",             32'h00000001, 32'h00000004, 3'b001, 1'b0);
        check_defined("sll_31",            32'h00000001, 32'h0000001F, 3'b001, 1'b0);
        check_defined("sll_mask_32",       32'h00000001, 32'h00000020, 3'b001, 1'b0);
        check_defined("sll_mask_63",       32'h00000001, 32'h0000003F, 3'b001, 1'b0);
        check_defined("sll_mask_frag",     32'h0000F00F, 32'hFFFF_FFE1, 3'b001, 1'b0); // shamt=1 from fragmented/all-ones upper bits

        check_defined("srl_0",             32'h80000000, 32'h00000000, 3'b101, 1'b0);
        check_defined("srl_1",             32'h80000000, 32'h00000001, 3'b101, 1'b0);
        check_defined("srl_31",            32'h80000000, 32'h0000001F, 3'b101, 1'b0);
        check_defined("srl_mask_32",       32'h80000000, 32'h00000020, 3'b101, 1'b0);
        check_defined("srl_mask_randhi",   32'hF0000001, 32'hABCDEFFF, 3'b101, 1'b0); // shamt=31

        check_defined("sra_0",             32'h80000000, 32'h00000000, 3'b101, 1'b1);
        check_defined("sra_1_neg",         32'h80000000, 32'h00000001, 3'b101, 1'b1);
        check_defined("sra_4_neg",         32'hF0000000, 32'h00000004, 3'b101, 1'b1);
        check_defined("sra_31_neg",        32'h80000001, 32'h0000001F, 3'b101, 1'b1);
        check_defined("sra_pos",           32'h70000000, 32'h00000004, 3'b101, 1'b1);
        check_defined("sra_mask_63",       32'h80000000, 32'h0000003F, 3'b101, 1'b1);

        // Comparison coverage: signed and unsigned boundaries, equality, zero/all ones
        check_defined("slt_eq",            32'h00000005, 32'h00000005, 3'b010, 1'b1);
        check_defined("slt_neg_lt_pos",    32'h80000000, 32'h00000000, 3'b010, 1'b1);
        check_defined("slt_pos_gt_neg",    32'h00000000, 32'hFFFFFFFF, 3'b010, 1'b1);
        check_defined("slt_min_lt_max",    32'h80000000, 32'h7FFFFFFF, 3'b010, 1'b1);
        check_defined("slt_max_not_lt_min",32'h7FFFFFFF, 32'h80000000, 3'b010, 1'b1);

        check_defined("sltu_eq",           32'h00000005, 32'h00000005, 3'b011, 1'b1);
        check_defined("sltu_zero_lt_ones", 32'h00000000, 32'hFFFFFFFF, 3'b011, 1'b1);
        check_defined("sltu_ones_not_lt_0",32'hFFFFFFFF, 32'h00000000, 3'b011, 1'b1);
        check_defined("sltu_boundary",     32'h7FFFFFFF, 32'h80000000, 3'b011, 1'b1);

        // Logical coverage
        check_defined("xor_basic",         32'hAAAAAAAA, 32'h55555555, 3'b100, 1'b0);
        check_defined("xor_zero",          32'h12345678, 32'h00000000, 3'b100, 1'b0);
        check_defined("xor_self",          32'h89ABCDEF, 32'h89ABCDEF, 3'b100, 1'b0);

        check_defined("or_basic",          32'h0F0F0F0F, 32'hF0F0F0F0, 3'b110, 1'b0);
        check_defined("or_zero",           32'h12345678, 32'h00000000, 3'b110, 1'b0);
        check_defined("or_ones",           32'h12345678, 32'hFFFFFFFF, 3'b110, 1'b0);

        check_defined("and_basic",         32'h0F0F0F0F, 32'hF0F0F0F0, 3'b111, 1'b0);
        check_defined("and_zero",          32'h12345678, 32'h00000000, 3'b111, 1'b0);
        check_defined("and_ones",          32'h12345678, 32'hFFFFFFFF, 3'b111, 1'b0);

        // Sum independence coverage: same A/B, compare different SubArith while operation is not add/sub
        check_defined("sum_indep_xor_addsum", 32'h11111111, 32'h01020304, 3'b100, 1'b0);
        check_defined("sum_indep_sra_subsum", 32'h80000010, 32'h00000004, 3'b101, 1'b1);
        check_defined("sum_indep_and_addsum", 32'hFFFF0000, 32'h00FF00FF, 3'b111, 1'b0);

        // Illegal encoding coverage: only defined behavior is Sum; do not check ALUResult.
        check_illegal_encoding("illegal_001_1", 32'h12345678, 32'h9ABCDEF0, 3'b001, 1'b1);
        check_illegal_encoding("illegal_010_0", 32'hFFFFFFFF, 32'h00000001, 3'b010, 1'b0);
        check_illegal_encoding("illegal_011_0", 32'hFFFFFFFF, 32'h00000001, 3'b011, 1'b0);
        check_illegal_encoding("illegal_100_1", 32'hAAAAAAAA, 32'h55555555, 3'b100, 1'b1);
        check_illegal_encoding("illegal_110_1", 32'h12345678, 32'h87654321, 3'b110, 1'b1);
        check_illegal_encoding("illegal_111_1", 32'h12345678, 32'h87654321, 3'b111, 1'b1);

        // Deterministic pseudo-random sweep over all defined operation classes.
        // Fixed seed to keep stimulus deterministic and reproducible.
        seed = 32'h1A2B3C4D;
        for (i = 0; i < 40; i = i + 1) begin
            ra = $random(seed);
            rb = $random(seed);

            check_defined("rand_add",  ra, rb, 3'b000, 1'b0);
            check_defined("rand_sub",  ra, rb, 3'b000, 1'b1);
            check_defined("rand_sll",  ra, rb, 3'b001, 1'b0);
            check_defined("rand_slt",  ra, rb, 3'b010, 1'b1);
            check_defined("rand_sltu", ra, rb, 3'b011, 1'b1);
            check_defined("rand_xor",  ra, rb, 3'b100, 1'b0);
            check_defined("rand_srl",  ra, rb, 3'b101, 1'b0);
            check_defined("rand_sra",  ra, rb, 3'b101, 1'b1);
            check_defined("rand_or",   ra, rb, 3'b110, 1'b0);
            check_defined("rand_and",  ra, rb, 3'b111, 1'b0);
        end

        // Structured shift-mask sweep: verify only B[4:0] matters for all shift operations.
        for (j = 0; j < 32; j = j + 1) begin
            temp_b = j;
            check_defined("mask_sll_low",  32'h13579BDF, temp_b,               3'b001, 1'b0);
            check_defined("mask_srl_low",  32'hFEDCBA98, temp_b,               3'b101, 1'b0);
            check_defined("mask_sra_low",  32'h8EDCBA98, temp_b,               3'b101, 1'b1);

            temp_b = 32'hFFFF_FFE0 | j[31:0];
            check_defined("mask_sll_high", 32'h13579BDF, temp_b,               3'b001, 1'b0);
            check_defined("mask_srl_high", 32'hFEDCBA98, temp_b,               3'b101, 1'b0);
            check_defined("mask_sra_high", 32'h8EDCBA98, temp_b,               3'b101, 1'b1);
        end

        $display("A1_CHECKS passed=%0d failed=%0d total=%0d", passed, failed, total);
        if ((failed == 0) && (total > 0))
            $display("PASS");
        else
            $display("FAIL");
        $finish;
    end

endmodule
