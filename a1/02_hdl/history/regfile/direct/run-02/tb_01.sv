`timescale 1ns/1ps

module regfile_tb;

    logic        clk;
    logic        reset;
    logic        we3;
    logic [4:0]  a1;
    logic [4:0]  a2;
    logic [4:0]  a3;
    logic [31:0] wd3;
    logic [31:0] rd1;
    logic [31:0] rd2;

    regfile dut (
        .clk   (clk),
        .reset (reset),
        .we3   (we3),
        .a1    (a1),
        .a2    (a2),
        .a3    (a3),
        .wd3   (wd3),
        .rd1   (rd1),
        .rd2   (rd2)
    );

    logic [31:0] model_regs [0:31];

    integer passed;
    integer failed;
    integer total;
    integer fail_prints;
    integer i;
    integer j;

    task automatic model_init_unknown_except_x0;
        integer k;
        begin
            for (k = 0; k < 32; k = k + 1) begin
                model_regs[k] = 32'hxxxxxxxx;
            end
            model_regs[0] = 32'h00000000;
        end
    endtask

    task automatic show_fail32(
        input [255:0] label,
        input [4:0]   ta1,
        input [4:0]   ta2,
        input [4:0]   ta3,
        input         twe3,
        input         treset,
        input [31:0]  twd3,
        input [31:0]  actual,
        input [31:0]  expected
    );
        begin
            if (fail_prints < 8) begin
                $display("FAIL %0s stim: reset=%0b we3=%0b a1=%0d a2=%0d a3=%0d wd3=%h actual=%h expected=%h",
                         label, treset, twe3, ta1, ta2, ta3, twd3, actual, expected);
            end
            fail_prints = fail_prints + 1;
        end
    endtask

    task automatic check32(
        input [255:0] label,
        input [31:0]  actual,
        input [31:0]  expected
    );
        begin
            total = total + 1;
            if (actual === expected) begin
                passed = passed + 1;
            end else begin
                failed = failed + 1;
                show_fail32(label, a1, a2, a3, we3, reset, wd3, actual, expected);
            end
        end
    endtask

    task automatic check_reads(input [255:0] label);
        logic [31:0] exp1;
        logic [31:0] exp2;
        begin
            #0.1;
            exp1 = (a1 == 5'd0) ? 32'h00000000 : model_regs[a1];
            exp2 = (a2 == 5'd0) ? 32'h00000000 : model_regs[a2];
            check32({label, " rd1"}, rd1, exp1);
            check32({label, " rd2"}, rd2, exp2);
        end
    endtask

    task automatic drive_posedge_only;
        begin
            clk = 1'b0;
            #0.2;
            clk = 1'b1;
            #0.2;
        end
    endtask

    task automatic drive_negedge_and_update_model;
        integer k;
        begin
            clk = 1'b1;
            #0.2;
            clk = 1'b0;
            if (reset === 1'b1) begin
                for (k = 1; k < 32; k = k + 1) begin
                    model_regs[k] = 32'h00000000;
                end
                model_regs[0] = 32'h00000000;
            end else if ((we3 === 1'b1) && (a3 != 5'd0)) begin
                model_regs[a3] = wd3;
                model_regs[0]  = 32'h00000000;
            end else begin
                model_regs[0]  = 32'h00000000;
            end
            #0.2;
        end
    endtask

    function automatic [31:0] pattern_for_reg(input integer idx);
        begin
            case (idx)
                1:  pattern_for_reg = 32'h00000000;
                2:  pattern_for_reg = 32'hFFFFFFFF;
                3:  pattern_for_reg = 32'h7FFFFFFF;
                4:  pattern_for_reg = 32'h80000000;
                5:  pattern_for_reg = 32'hDEADBEEF;
                6:  pattern_for_reg = 32'hCAFEBABE;
                7:  pattern_for_reg = 32'h00000001;
                8:  pattern_for_reg = 32'h80000001;
                9:  pattern_for_reg = 32'h55555555;
                10: pattern_for_reg = 32'hAAAAAAAA;
                11: pattern_for_reg = 32'h13579BDF;
                12: pattern_for_reg = 32'h2468ACE0;
                13: pattern_for_reg = 32'h0000FFFF;
                14: pattern_for_reg = 32'hFFFF0000;
                15: pattern_for_reg = 32'h12345678;
                16: pattern_for_reg = 32'h87654321;
                17: pattern_for_reg = 32'h01010101;
                18: pattern_for_reg = 32'h10101010;
                19: pattern_for_reg = 32'h0F0F0F0F;
                20: pattern_for_reg = 32'hF0F0F0F0;
                21: pattern_for_reg = 32'h00FF00FF;
                22: pattern_for_reg = 32'hFF00FF00;
                23: pattern_for_reg = 32'h33333333;
                24: pattern_for_reg = 32'hCCCCCCCC;
                25: pattern_for_reg = 32'hAAAAAAAA ^ 32'h12345678;
                26: pattern_for_reg = 32'h55555555 ^ 32'h87654321;
                27: pattern_for_reg = 32'h0000002A;
                28: pattern_for_reg = 32'hFFFFFFD6;
                29: pattern_for_reg = 32'h7F800001;
                30: pattern_for_reg = 32'h00800000;
                31: pattern_for_reg = 32'h80000001;
                default: pattern_for_reg = 32'h00000000;
            endcase
        end
    endfunction

    initial begin : watchdog
        #1000;
        $display("FAIL");
        $finish;
    end

    initial begin : test_main
        integer idx;
        integer rev;
        logic [4:0] idx5;
        logic [4:0] rev5;
        logic [4:0] next5;
        logic [31:0] pattern;

        passed = 0;
        failed = 0;
        total = 0;
        fail_prints = 0;

        clk   = 1'b1;
        reset = 1'b0;
        we3   = 1'b0;
        a1    = 5'd0;
        a2    = 5'd0;
        a3    = 5'd0;
        wd3   = 32'h00000000;

        model_init_unknown_except_x0();

        // Pre-reset only x0 is defined by spec. x1..x31 power-up contents are unspecified.
        a1 = 5'd0;
        a2 = 5'd0;
        check_reads("pre_reset_x0_reads");

        // Attempted write to x0 before reset must still leave x0 at zero.
        we3 = 1'b1;
        a3  = 5'd0;
        wd3 = 32'hFFFFFFFF;
        a1  = 5'd0;
        a2  = 5'd0;
        drive_negedge_and_update_model();
        check_reads("pre_reset_x0_write_ignored");

        // No asynchronous reset: toggling reset without a falling edge must not change state.
        // Only x0 is checked here because other registers are still unspecified.
        reset = 1'b1;
        drive_posedge_only();
        a1 = 5'd0;
        a2 = 5'd0;
        check_reads("no_async_reset_x0_only");
        reset = 1'b0;
        #0.1;
        check_reads("reset_deassert_between_edges_x0_only");

        // Establish known contents with synchronous reset sampled on falling edge.
        we3   = 1'b0;
        a3    = 5'd0;
        wd3   = 32'h12345678;
        a1    = 5'd0;
        a2    = 5'd1;
        reset = 1'b1;
        drive_negedge_and_update_model();
        check_reads("sync_reset_event");

        // After reset, every register is defined to read zero; check both ports.
        for (idx = 0; idx < 32; idx = idx + 1) begin
            idx5 = idx[4:0];
            a1 = idx5;
            a2 = idx5;
            check_reads("all_regs_zero_same_addr_both_ports");
        end

        for (idx = 0; idx < 32; idx = idx + 1) begin
            idx5 = idx[4:0];
            rev = 31 - idx;
            rev5 = rev[4:0];
            a1 = idx5;
            a2 = rev5;
            check_reads("all_regs_zero_crosscheck_ports");
        end

        // Combinational reads on different addresses after reset.
        reset = 1'b0;
        we3   = 1'b0;
        a1    = 5'd3;
        a2    = 5'd7;
        check_reads("independent_comb_reads_after_reset");

        // Sample sequence case 1.
        we3   = 1'b1;
        a3    = 5'd5;
        wd3   = 32'hDEADBEEF;
        a1    = 5'd5;
        a2    = 5'd0;
        check_reads("before_sample_write_x5_no_bypass");
        drive_negedge_and_update_model();
        check_reads("sample_write_x5_deadbeef");

        // Sample sequence case 2.
        we3   = 1'b1;
        a3    = 5'd0;
        wd3   = 32'hFFFFFFFF;
        a1    = 5'd0;
        a2    = 5'd5;
        drive_negedge_and_update_model();
        check_reads("sample_write_x0_ignored");

        // Sample sequence case 3.
        we3   = 1'b0;
        a3    = 5'd5;
        wd3   = 32'h0000002A;
        a1    = 5'd5;
        a2    = 5'd0;
        drive_negedge_and_update_model();
        check_reads("sample_we3_zero_no_change");

        // Sample sequence case 4, also proving reset priority over write.
        reset = 1'b1;
        we3   = 1'b1;
        a3    = 5'd5;
        wd3   = 32'hAAAAAAAA;
        a1    = 5'd5;
        a2    = 5'd0;
        drive_negedge_and_update_model();
        check_reads("sample_reset_clears_x5");
        reset = 1'b0;
        we3   = 1'b0;

        // Positive edge must not write.
        we3   = 1'b1;
        a3    = 5'd6;
        wd3   = 32'hCAFEBABE;
        a1    = 5'd6;
        a2    = 5'd0;
        drive_posedge_only();
        check_reads("no_posedge_write");

        // The subsequent falling edge performs the write.
        drive_negedge_and_update_model();
        check_reads("write_happens_on_negedge");

        // Reset changes between edges must not affect state until a falling edge arrives.
        a1    = 5'd6;
        a2    = 5'd5;
        reset = 1'b1;
        #0.1;
        check_reads("reset_asserted_between_edges_no_effect");
        reset = 1'b0;
        #0.1;
        check_reads("reset_deasserted_between_edges_no_effect");

        // Populate all x1..x31 with deterministic patterns.
        // Before each falling edge, reads observe old state because there is no bypass.
        for (idx = 1; idx < 32; idx = idx + 1) begin
            idx5 = idx[4:0];
            if (idx == 31) begin
                next5 = 5'd0;
            end else begin
                next5 = (idx + 1)[4:0];
            end
            pattern = pattern_for_reg(idx);

            we3 = 1'b1;
            a3  = idx5;
            wd3 = pattern;
            a1  = idx5;
            a2  = next5;
            check_reads("before_negedge_old_contents_visible");
            drive_negedge_and_update_model();
            check_reads("after_negedge_new_contents_visible");
        end

        // Read back all registers using both ports across the full address space coverage.
        for (idx = 0; idx < 32; idx = idx + 1) begin
            for (j = 0; j < 32; j = j + 1) begin
                idx5 = idx[4:0];
                rev5 = j[4:0];
                a1 = idx5;
                a2 = rev5;
                check_reads("full_space_readback");
            end
        end

        // Explicit x0 checks among populated nonzero registers.
        a1 = 5'd0;
        a2 = 5'd6;
        check_reads("x0_zero_while_other_reg_nonzero");

        we3 = 1'b1;
        a3  = 5'd0;
        wd3 = 32'h12345678;
        a1  = 5'd0;
        a2  = 5'd0;
        drive_negedge_and_update_model();
        check_reads("x0_write_attempt_after_population_ignored");

        // Disabled write to nonzero register must not change state.
        a1  = 5'd10;
        a2  = 5'd10;
        check_reads("x10_before_disabled_write");
        we3 = 1'b0;
        a3  = 5'd10;
        wd3 = 32'hA5A5A5A5;
        drive_negedge_and_update_model();
        check_reads("disabled_write_x10_no_change");

        // Reset priority over simultaneous write.
        we3   = 1'b1;
        reset = 1'b1;
        a3    = 5'd11;
        wd3   = 32'hFFFFFFFF;
        a1    = 5'd11;
        a2    = 5'd6;
        drive_negedge_and_update_model();
        check_reads("reset_priority_over_write");
        reset = 1'b0;
        we3   = 1'b0;

        // After reset-priority event, all registers must be zero.
        for (idx = 0; idx < 32; idx = idx + 1) begin
            idx5 = idx[4:0];
            a1 = idx5;
            a2 = idx5;
            check_reads("all_regs_zero_after_reset_priority");
        end

        // Boundary values explicitly required by spec guidance.
        we3 = 1'b1; a3 = 5'd1;  wd3 = 32'h00000000; a1 = 5'd1;  a2 = 5'd0; drive_negedge_and_update_model(); check_reads("boundary_zero");
        we3 = 1'b1; a3 = 5'd2;  wd3 = 32'hFFFFFFFF; a1 = 5'd2;  a2 = 5'd0; drive_negedge_and_update_model(); check_reads("boundary_all_ones");
        we3 = 1'b1; a3 = 5'd3;  wd3 = 32'h7FFFFFFF; a1 = 5'd3;  a2 = 5'd0; drive_negedge_and_update_model(); check_reads("boundary_max_positive");
        we3 = 1'b1; a3 = 5'd4;  wd3 = 32'h80000000; a1 = 5'd4;  a2 = 5'd0; drive_negedge_and_update_model(); check_reads("boundary_min_negative");
        we3 = 1'b1; a3 = 5'd31; wd3 = 32'h80000001; a1 = 5'd31; a2 = 5'd4; drive_negedge_and_update_model(); check_reads("boundary_highest_reg");

        // Combinational read behavior: changing addresses without any edge updates outputs.
        we3 = 1'b0;
        a1 = 5'd2;  a2 = 5'd3;  check_reads("comb_read_change_1");
        a1 = 5'd4;  a2 = 5'd31; check_reads("comb_read_change_2");
        a1 = 5'd0;  a2 = 5'd1;  check_reads("comb_read_change_3");
        a1 = 5'd31; a2 = 5'd0;  check_reads("comb_read_change_4");

        $display("A1_CHECKS passed=%0d failed=%0d total=%0d", passed, failed, total);
        if ((failed == 0) && (total > 0)) begin
            $display("PASS");
        end else begin
            $display("FAIL");
        end
        $finish;
    end

endmodule
