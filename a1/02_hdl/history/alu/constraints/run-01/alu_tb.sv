`timescale 1ns/1ps

module alu_tb;

    logic [31:0] A;
    logic [31:0] B;
    logic [2:0]  ALUSelect;
    logic        SubArith;
    logic [31:0] ALUResult;
    logic [31:0] Sum;

    integer passed;
    integer failed;
    integer total;
    integer fail_prints;

    alu dut (
        .A(A),
        .B(B),
        .ALUSelect(ALUSelect),
        .SubArith(SubArith),
        .ALUResult(ALUResult),
        .Sum(Sum)
    );

    function automatic logic [31:0] exp_sum(
        input logic [31:0] a,
        input logic [31:0] b,
        input logic        sub
    );
        begin
            if (sub) exp_sum = a - b;
            else     exp_sum = a + b;
        end
    endfunction

    function automatic logic [31:0] exp_result(
        input logic [31:0] a,
        input logic [31:0] b,
        input logic [2:0]  sel,
        input logic        sub
    );
        begin
            case (sel)
                3'b000: begin
                    if (sub) exp_result = a - b;
                    else     exp_result = a + b;
                end
                3'b001: begin
                    if (!sub) exp_result = a << b[4:0];
                    else      exp_result = 32'hxxxxxxxx; // undefined by spec
                end
                3'b010: begin
                    if (sub) exp_result = ($signed(a) < $signed(b)) ? 32'h00000001 : 32'h00000000;
                    else     exp_result = 32'hxxxxxxxx; // undefined by spec
                end
                3'b011: begin
                    if (sub) exp_result = (a < b) ? 32'h00000001 : 32'h00000000;
                    else     exp_result = 32'hxxxxxxxx; // undefined by spec
                end
                3'b100: begin
                    if (!sub) exp_result = a ^ b;
                    else      exp_result = 32'hxxxxxxxx; // undefined by spec
                end
                3'b101: begin
                    if (sub) exp_result = $signed(a) >>> b[4:0];
                    else     exp_result = a >> b[4:0];
                end
                3'b110: begin
                    if (!sub) exp_result = a | b;
                    else      exp_result = 32'hxxxxxxxx; // undefined by spec
                end
                3'b111: begin
                    if (!sub) exp_result = a & b;
                    else      exp_result = 32'hxxxxxxxx; // undefined by spec
                end
                default: exp_result = 32'hxxxxxxxx;
            endcase
        end
    endfunction

    task automatic report_fail(
        input [255:0] label,
        input [31:0]  actual,
        input [31:0]  expected
    );
        begin
            if (fail_prints < 8) begin
                $display("FAIL %0s A=%08h B=%08h ALUSelect=%03b SubArith=%0b actual=%08h expected=%08h",
                         label, A, B, ALUSelect, SubArith, actual, expected);
            end
            fail_prints = fail_prints + 1;
        end
    endtask

    task automatic check_eq32(
        input [255:0] label,
        input [31:0]  actual,
        input [31:0]  expected
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

    task automatic apply_and_check_defined(
        input [255:0] label,
        input logic [31:0] a,
        input logic [31:0] b,
        input logic [2:0]  sel,
        input logic        sub
    );
        logic [31:0] er;
        logic [31:0] es;
        begin
            A = a;
            B = b;
            ALUSelect = sel;
            SubArith = sub;
            #1; // combinational settling
            er = exp_result(a, b, sel, sub);
            es = exp_sum(a, b, sub);
            check_eq32({label, "_ALUResult"}, ALUResult, er);
            check_eq32({label, "_Sum"},       Sum,       es);
        end
    endtask

    initial begin : watchdog
        #100000;
        $display("FAIL");
        $finish;
    end

    integer i;
    integer seed;
    logic [31:0] ra;
    logic [31:0] rb;
    logic [31:0] sa;

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

        // Sample examples from the specification.
        apply_and_check_defined("sample_add", 32'h0000000A, 32'h00000003, 3'b000, 1'b0);
        apply_and_check_defined("sample_sub", 32'h0000000A, 32'h00000003, 3'b000, 1'b1);
        apply_and_check_defined("sample_slt", 32'hFFFFFFFF, 32'h00000001, 3'b010, 1'b1);
        apply_and_check_defined("sample_sltu",32'hFFFFFFFF, 32'h00000001, 3'b011, 1'b1);
        apply_and_check_defined("sample_sra", 32'h80000000, 32'h00000001, 3'b101, 1'b1);
        apply_and_check_defined("sample_sll", 32'h0000000F, 32'h0000001F, 3'b001, 1'b0);

        // ADD/SUB including modular wraparound and signed boundaries.
        apply_and_check_defined("add_zero",        32'h00000000, 32'h00000000, 3'b000, 1'b0);
        apply_and_check_defined("add_wrap",        32'hFFFFFFFF, 32'h00000001, 3'b000, 1'b0);
        apply_and_check_defined("add_signededge",  32'h7FFFFFFF, 32'h00000001, 3'b000, 1'b0);
        apply_and_check_defined("add_neg_boundary",32'h80000000, 32'h80000000, 3'b000, 1'b0);
        apply_and_check_defined("sub_zero",        32'h00000000, 32'h00000000, 3'b000, 1'b1);
        apply_and_check_defined("sub_borrow",      32'h00000000, 32'h00000001, 3'b000, 1'b1);
        apply_and_check_defined("sub_wrap",        32'h80000000, 32'h00000001, 3'b000, 1'b1);
        apply_and_check_defined("sub_allones",     32'hFFFFFFFF, 32'hFFFFFFFF, 3'b000, 1'b1);

        // SLL: verify only B[4:0] is used; include fragmented-immediate-like values in B.
        apply_and_check_defined("sll_shift0",      32'h12345678, 32'h00000000, 3'b001, 1'b0);
        apply_and_check_defined("sll_shift1",      32'h00000001, 32'h00000001, 3'b001, 1'b0);
        apply_and_check_defined("sll_shift31",     32'h00000001, 32'h0000001F, 3'b001, 1'b0);
        apply_and_check_defined("sll_mask32",      32'h00000001, 32'h00000020, 3'b001, 1'b0);
        apply_and_check_defined("sll_mask63",      32'h00000001, 32'h0000003F, 3'b001, 1'b0);
        apply_and_check_defined("sll_frag_b",      32'h89ABCDEF, 32'hABCDEFE5, 3'b001, 1'b0);

        // SLT signed boundaries.
        apply_and_check_defined("slt_eq",          32'h00000000, 32'h00000000, 3'b010, 1'b1);
        apply_and_check_defined("slt_neg_lt_pos",  32'h80000000, 32'h00000000, 3'b010, 1'b1);
        apply_and_check_defined("slt_pos_gt_neg",  32'h7FFFFFFF, 32'hFFFFFFFF, 3'b010, 1'b1);
        apply_and_check_defined("slt_min_lt_max",  32'h80000000, 32'h7FFFFFFF, 3'b010, 1'b1);
        apply_and_check_defined("slt_max_not_lt_min",32'h7FFFFFFF,32'h80000000,3'b010,1'b1);

        // SLTU unsigned boundaries.
        apply_and_check_defined("sltu_eq",         32'h00000000, 32'h00000000, 3'b011, 1'b1);
        apply_and_check_defined("sltu_zero_lt_one",32'h00000000, 32'h00000001, 3'b011, 1'b1);
        apply_and_check_defined("sltu_ones_not_lt_zero",32'hFFFFFFFF,32'h00000000,3'b011,1'b1);
        apply_and_check_defined("sltu_small_lt_big",32'h7FFFFFFF, 32'h80000000, 3'b011, 1'b1);

        // XOR/OR/AND.
        apply_and_check_defined("xor_zero",        32'h00000000, 32'h00000000, 3'b100, 1'b0);
        apply_and_check_defined("xor_allones",     32'hFFFFFFFF, 32'h0F0F0F0F, 3'b100, 1'b0);
        apply_and_check_defined("or_mix",          32'h12340000, 32'h00005678, 3'b110, 1'b0);
        apply_and_check_defined("or_allones",      32'hFFFFFFFF, 32'h00000000, 3'b110, 1'b0);
        apply_and_check_defined("and_mix",         32'h12345678, 32'h00FF00FF, 3'b111, 1'b0);
        apply_and_check_defined("and_zero",        32'hFFFFFFFF, 32'h00000000, 3'b111, 1'b0);

        // SRL/SRA with mask behavior and sign replication.
        apply_and_check_defined("srl_shift0",      32'h80000001, 32'h00000000, 3'b101, 1'b0);
        apply_and_check_defined("srl_shift1",      32'h80000000, 32'h00000001, 3'b101, 1'b0);
        apply_and_check_defined("srl_shift31",     32'h80000000, 32'h0000001F, 3'b101, 1'b0);
        apply_and_check_defined("srl_mask32",      32'h12345678, 32'h00000020, 3'b101, 1'b0);
        apply_and_check_defined("srl_mask63",      32'h80000001, 32'h0000003F, 3'b101, 1'b0);
        apply_and_check_defined("sra_shift0",      32'h80000001, 32'h00000000, 3'b101, 1'b1);
        apply_and_check_defined("sra_shift1",      32'h80000000, 32'h00000001, 3'b101, 1'b1);
        apply_and_check_defined("sra_shift31_neg", 32'h80000000, 32'h0000001F, 3'b101, 1'b1);
        apply_and_check_defined("sra_shift31_pos", 32'h7FFFFFFF, 32'h0000001F, 3'b101, 1'b1);
        apply_and_check_defined("sra_mask32",      32'hF2345678, 32'h00000020, 3'b101, 1'b1);
        apply_and_check_defined("sra_frag_b",      32'h92345678, 32'h13579BFF, 3'b101, 1'b1);

        // Sweep shift amounts 0..31 to thoroughly cover masking and edge amounts.
        for (i = 0; i < 32; i = i + 1) begin
            sa = i;
            apply_and_check_defined("sll_sweep", 32'hA5A5A5A5, sa, 3'b001, 1'b0);
            apply_and_check_defined("srl_sweep", 32'hA5A5A5A5, sa, 3'b101, 1'b0);
            apply_and_check_defined("sra_sweep", 32'hA5A5A5A5, sa, 3'b101, 1'b1);
        end

        // Deterministic pseudo-random defined-operation coverage across all operation classes.
        seed = 32'h6890A1;
        for (i = 0; i < 40; i = i + 1) begin
            seed = seed * 32'd1664525 + 32'd1013904223;
            ra = seed;
            seed = seed * 32'd1664525 + 32'd1013904223;
            rb = seed;
            apply_and_check_defined("rand_add",  ra, rb, 3'b000, 1'b0);
            apply_and_check_defined("rand_sub",  ra, rb, 3'b000, 1'b1);
            apply_and_check_defined("rand_sll",  ra, rb, 3'b001, 1'b0);
            apply_and_check_defined("rand_slt",  ra, rb, 3'b010, 1'b1);
            apply_and_check_defined("rand_sltu", ra, rb, 3'b011, 1'b1);
            apply_and_check_defined("rand_xor",  ra, rb, 3'b100, 1'b0);
            apply_and_check_defined("rand_srl",  ra, rb, 3'b101, 1'b0);
            apply_and_check_defined("rand_sra",  ra, rb, 3'b101, 1'b1);
            apply_and_check_defined("rand_or",   ra, rb, 3'b110, 1'b0);
            apply_and_check_defined("rand_and",  ra, rb, 3'b111, 1'b0);
        end

        $display("A1_CHECKS passed=%0d failed=%0d total=%0d", passed, failed, total);
        if (failed == 0 && total > 0) $display("PASS");
        else                           $display("FAIL");
        $finish;
    end

endmodule
