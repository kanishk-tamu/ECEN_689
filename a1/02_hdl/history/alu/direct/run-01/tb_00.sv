`timescale 1ns/1ps

module alu_tb;

    // DUT interface
    logic [31:0] A;
    logic [31:0] B;
    logic [2:0]  ALUSelect;
    logic        SubArith;
    logic [31:0] ALUResult;
    logic [31:0] Sum;

    alu dut (
        .A(A),
        .B(B),
        .ALUSelect(ALUSelect),
        .SubArith(SubArith),
        .ALUResult(ALUResult),
        .Sum(Sum)
    );

    integer passed;
    integer failed;
    integer total;
    integer fail_prints;

    // Watchdog to prevent hanging simulations.
    initial begin
        #10000;
        $display("FAIL");
        $finish;
    end

    function automatic [31:0] expected_sum(
        input logic [31:0] a,
        input logic [31:0] b,
        input logic        sub
    );
        begin
            if (sub)
                expected_sum = a - b;
            else
                expected_sum = a + b;
        end
    endfunction

    function automatic [31:0] expected_result(
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

            case (sel)
                3'b000: expected_result = sub ? (a - b) : (a + b);
                3'b001: expected_result = (!sub) ? (a << shamt) : 32'hxxxxxxxx; // undefined when SubArith=1
                3'b010: expected_result = (sub) ? ((sa < sb) ? 32'h00000001 : 32'h00000000) : 32'hxxxxxxxx; // undefined when SubArith=0
                3'b011: expected_result = (sub) ? ((a  < b ) ? 32'h00000001 : 32'h00000000) : 32'hxxxxxxxx; // undefined when SubArith=0
                3'b100: expected_result = (!sub) ? (a ^ b) : 32'hxxxxxxxx; // undefined when SubArith=1
                3'b101: expected_result = sub ? (sa >>> shamt) : (a >> shamt);
                3'b110: expected_result = (!sub) ? (a | b) : 32'hxxxxxxxx; // undefined when SubArith=1
                3'b111: expected_result = (!sub) ? (a & b) : 32'hxxxxxxxx; // undefined when SubArith=1
                default: expected_result = 32'hxxxxxxxx;
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

    task automatic check_one(
        input [255:0] label,
        input logic [31:0] a,
        input logic [31:0] b,
        input logic [2:0]  sel,
        input logic        sub,
        input logic        check_result
    );
        logic [31:0] exp_sum;
        logic [31:0] exp_result;
        begin
            A = a;
            B = b;
            ALUSelect = sel;
            SubArith = sub;

            // Allow combinational settling.
            #1;

            exp_sum    = expected_sum(a, b, sub);
            exp_result = expected_result(a, b, sel, sub);

            // Sum is defined for all inputs and must always be checked.
            total = total + 1;
            if (Sum === exp_sum) begin
                passed = passed + 1;
            end else begin
                failed = failed + 1;
                report_fail({label, "_SUM"}, Sum, exp_sum);
            end

            // ALUResult is only checked for defined operation encodings.
            if (check_result) begin
                total = total + 1;
                if (ALUResult === exp_result) begin
                    passed = passed + 1;
                end else begin
                    failed = failed + 1;
                    report_fail({label, "_RES"}, ALUResult, exp_result);
                end
            end
        end
    endtask

    integer i;
    integer j;
    logic [31:0] vecA [0:11];
    logic [31:0] vecB [0:11];
    logic [31:0] shamt_temp;

    initial begin
        passed = 0;
        failed = 0;
        total = 0;
        fail_prints = 0;

        A = 32'h0;
        B = 32'h0;
        ALUSelect = 3'b000;
        SubArith = 1'b0;

        // Representative operands including zero, all ones, signed boundaries,
        // alternating patterns, and values that exercise wraparound.
        vecA[0]  = 32'h00000000;
        vecA[1]  = 32'h00000001;
        vecA[2]  = 32'hFFFFFFFF;
        vecA[3]  = 32'h7FFFFFFF;
        vecA[4]  = 32'h80000000;
        vecA[5]  = 32'hAAAAAAAA;
        vecA[6]  = 32'h55555555;
        vecA[7]  = 32'h0000000A;
        vecA[8]  = 32'h0000000F;
        vecA[9]  = 32'h12345678;
        vecA[10] = 32'h80000001;
        vecA[11] = 32'h0000FFFF;

        vecB[0]  = 32'h00000000;
        vecB[1]  = 32'h00000001;
        vecB[2]  = 32'hFFFFFFFF;
        vecB[3]  = 32'h7FFFFFFF;
        vecB[4]  = 32'h80000000;
        vecB[5]  = 32'h0000001F;
        vecB[6]  = 32'h00000020; // shift-mask case: same effective shamt as 0
        vecB[7]  = 32'h00000003;
        vecB[8]  = 32'h87654321;
        vecB[9]  = 32'h00000004;
        vecB[10] = 32'h0000001E;
        vecB[11] = 32'hFFFF_FFE1; // low 5 bits = 1, fragmented/high bits irrelevant to shamt

        // Sample usage cases from specification.
        check_one("SAMPLE_ADD", 32'h0000000A, 32'h00000003, 3'b000, 1'b0, 1'b1);
        check_one("SAMPLE_SUB", 32'h0000000A, 32'h00000003, 3'b000, 1'b1, 1'b1);
        check_one("SAMPLE_SLT", 32'hFFFFFFFF, 32'h00000001, 3'b010, 1'b1, 1'b1);
        check_one("SAMPLE_SLTU", 32'hFFFFFFFF, 32'h00000001, 3'b011, 1'b1, 1'b1);
        check_one("SAMPLE_SRA", 32'h80000000, 32'h00000001, 3'b101, 1'b1, 1'b1);
        check_one("SAMPLE_SLL31", 32'h0000000F, 32'h0000001F, 3'b001, 1'b0, 1'b1);

        // ADD/SUB corner cases and wraparound. Also verifies ALUResult==Sum for sel=000.
        check_one("ADD_ZERO",      32'h00000000, 32'h00000000, 3'b000, 1'b0, 1'b1);
        check_one("ADD_WRAP",      32'hFFFFFFFF, 32'h00000001, 3'b000, 1'b0, 1'b1);
        check_one("ADD_SIGNBOUND", 32'h7FFFFFFF, 32'h00000001, 3'b000, 1'b0, 1'b1);
        check_one("SUB_ZERO",      32'h00000000, 32'h00000000, 3'b000, 1'b1, 1'b1);
        check_one("SUB_UNDER",     32'h00000000, 32'h00000001, 3'b000, 1'b1, 1'b1);
        check_one("SUB_MININT",    32'h80000000, 32'h00000001, 3'b000, 1'b1, 1'b1);

        // Systematic checks for all defined operation classes across diverse operand pairs.
        for (i = 0; i < 12; i = i + 1) begin
            check_one("ADD_SWEEP",  vecA[i], vecB[i], 3'b000, 1'b0, 1'b1);
            check_one("SUB_SWEEP",  vecA[i], vecB[i], 3'b000, 1'b1, 1'b1);
            check_one("SLL_SWEEP",  vecA[i], vecB[i], 3'b001, 1'b0, 1'b1);
            check_one("SLT_SWEEP",  vecA[i], vecB[i], 3'b010, 1'b1, 1'b1);
            check_one("SLTU_SWEEP", vecA[i], vecB[i], 3'b011, 1'b1, 1'b1);
            check_one("XOR_SWEEP",  vecA[i], vecB[i], 3'b100, 1'b0, 1'b1);
            check_one("SRL_SWEEP",  vecA[i], vecB[i], 3'b101, 1'b0, 1'b1);
            check_one("SRA_SWEEP",  vecA[i], vecB[i], 3'b101, 1'b1, 1'b1);
            check_one("OR_SWEEP",   vecA[i], vecB[i], 3'b110, 1'b0, 1'b1);
            check_one("AND_SWEEP",  vecA[i], vecB[i], 3'b111, 1'b0, 1'b1);
        end

        // Explicit signed/unsigned comparison boundaries.
        check_one("SLT_NEG_LT_POS",   32'h80000000, 32'h00000000, 3'b010, 1'b1, 1'b1);
        check_one("SLT_POS_GT_NEG",   32'h00000000, 32'h80000000, 3'b010, 1'b1, 1'b1);
        check_one("SLT_EQUAL",        32'h80000000, 32'h80000000, 3'b010, 1'b1, 1'b1);
        check_one("SLTU_LOW_LT_HIGH", 32'h00000000, 32'hFFFFFFFF, 3'b011, 1'b1, 1'b1);
        check_one("SLTU_HIGH_GT_LOW", 32'hFFFFFFFF, 32'h00000000, 3'b011, 1'b1, 1'b1);
        check_one("SLTU_EQUAL",       32'hFFFFFFFF, 32'hFFFFFFFF, 3'b011, 1'b1, 1'b1);

        // Shift masking: only B[4:0] matters. Values above 31 must wrap modulo 32.
        check_one("SLL_MASK_32", 32'h00000001, 32'h00000020, 3'b001, 1'b0, 1'b1);
        check_one("SLL_MASK_33", 32'h00000001, 32'h00000021, 3'b001, 1'b0, 1'b1);
        check_one("SRL_MASK_32", 32'h80000000, 32'h00000020, 3'b101, 1'b0, 1'b1);
        check_one("SRA_MASK_32", 32'h80000000, 32'h00000020, 3'b101, 1'b1, 1'b1);
        check_one("SRA_NEG_31",  32'h80000001, 32'h0000001F, 3'b101, 1'b1, 1'b1);
        check_one("SRL_31",      32'h80000000, 32'h0000001F, 3'b101, 1'b0, 1'b1);

        // Fragmented/immediate-like shift sources: high bits set but low 5 select amount.
        check_one("SLL_FRAG1", 32'h00000001, 32'hFFFF_FFE1, 3'b001, 1'b0, 1'b1); // shamt=1
        check_one("SRL_FRAG4", 32'hF0000000, 32'h12345664, 3'b101, 1'b0, 1'b1); // shamt=4
        check_one("SRA_FRAG4", 32'hF0000000, 32'h12345664, 3'b101, 1'b1, 1'b1); // shamt=4

        // Exhaustive shift amount coverage for representative operands.
        for (j = 0; j < 32; j = j + 1) begin
            shamt_temp = j;
            check_one("SLL_SHAMT_ALL", 32'h00000001, shamt_temp, 3'b001, 1'b0, 1'b1);
            check_one("SRL_SHAMT_ALL", 32'h80000000, shamt_temp, 3'b101, 1'b0, 1'b1);
            check_one("SRA_SHAMT_ALL", 32'h80000001, shamt_temp, 3'b101, 1'b1, 1'b1);
        end

        // Illegal/undefined ALUResult encodings per spec:
        // still check Sum because Sum is always defined, but do not check ALUResult.
        check_one("ILL_SLL_SUB1", 32'h12345678, 32'h00000004, 3'b001, 1'b1, 1'b0);
        check_one("ILL_SLT_SUB0", 32'h12345678, 32'h87654321, 3'b010, 1'b0, 1'b0);
        check_one("ILL_SLTU_SUB0",32'h12345678, 32'h87654321, 3'b011, 1'b0, 1'b0);
        check_one("ILL_XOR_SUB1", 32'hAAAAAAAA, 32'h55555555, 3'b100, 1'b1, 1'b0);
        check_one("ILL_OR_SUB1",  32'hAAAAAAAA, 32'h55555555, 3'b110, 1'b1, 1'b0);
        check_one("ILL_AND_SUB1", 32'hAAAAAAAA, 32'h55555555, 3'b111, 1'b1, 1'b0);

        $display("A1_CHECKS passed=%0d failed=%0d total=%0d", passed, failed, total);
        if ((failed == 0) && (total > 0))
            $display("PASS");
        else
            $display("FAIL");
        $finish;
    end

endmodule
