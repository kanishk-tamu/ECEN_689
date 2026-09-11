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

    localparam integer MAX_FAIL_PRINTS = 8;

    task automatic record_check(
        input string label,
        input logic [31:0] actual,
        input logic [31:0] expected,
        input logic [4:0]  ta1,
        input logic [4:0]  ta2,
        input logic [4:0]  ta3,
        input logic [31:0] twd3,
        input logic        twe3,
        input logic        treset,
        input logic        tclk
    );
    begin
        total = total + 1;
        if (actual === expected) begin
            passed = passed + 1;
        end else begin
            failed = failed + 1;
            if (fail_prints < MAX_FAIL_PRINTS) begin
                $display("FAIL label=%s clk=%0b reset=%0b we3=%0b a1=%0d a2=%0d a3=%0d wd3=0x%08h actual=0x%08h expected=0x%08h",
                         label, tclk, treset, twe3, ta1, ta2, ta3, twd3, actual, expected);
                fail_prints = fail_prints + 1;
            end
        end
    end
    endtask

    task automatic check_reads(input string label);
        logic [31:0] exp1;
        logic [31:0] exp2;
    begin
        #0.1;
        exp1 = (a1 == 5'd0) ? 32'h00000000 : model_regs[a1];
        exp2 = (a2 == 5'd0) ? 32'h00000000 : model_regs[a2];
        record_check({label, ".rd1"}, rd1, exp1, a1, a2, a3, wd3, we3, reset, clk);
        record_check({label, ".rd2"}, rd2, exp2, a1, a2, a3, wd3, we3, reset, clk);
    end
    endtask

    task automatic drive_reads(input logic [4:0] na1, input logic [4:0] na2, input string label);
    begin
        a1 = na1;
        a2 = na2;
        check_reads(label);
    end
    endtask

    task automatic posedge_only(input string label);
    begin
        #0.2;
        clk = 1'b1;
        #0.1;
        check_reads(label);
    end
    endtask

    task automatic negedge_sample_and_update(input string label);
        integer idx;
    begin
        #0.2;
        clk = 1'b0;
        if (reset === 1'b1) begin
            for (idx = 1; idx < 32; idx = idx + 1) begin
                model_regs[idx] = 32'h00000000;
            end
            model_regs[0] = 32'h00000000;
        end else if ((we3 === 1'b1) && (a3 != 5'd0)) begin
            model_regs[a3] = wd3;
            model_regs[0] = 32'h00000000;
        end else begin
            model_regs[0] = 32'h00000000;
        end
        #0.1;
        check_reads(label);
    end
    endtask

    initial begin : watchdog
        #1000;
        $display("FAIL");
        $finish;
    end

    initial begin : test_sequence
        integer regidx;
        logic [4:0] regidx5;
        logic [4:0] regidx_rev5;
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

        for (i = 0; i < 32; i = i + 1) begin
            model_regs[i] = 32'h00000000;
        end

        // Coverage notes:
        // - x0 tested before reset, after ignored writes, and during/after reset.
        // - Explicit synchronous reset at negedge before checking x1..x31 contents.
        // - Both read ports checked on every read check.
        // - Positive edges are exercised to prove no write/reset occurs there.
        // - Reset changes between edges are exercised to prove no asynchronous reset.
        // - All registers x1..x31 are written and read back.
        // - we3=0, a3=0, reset priority over write, same-address dual reads, and
        //   combinational read response after state changes are all checked.

        #0.1;
        check_reads("initial_x0_only");

        a1 = 5'd0;
        a2 = 5'd0;
        a3 = 5'd0;
        wd3 = 32'hFFFFFFFF;
        we3 = 1'b1;
        #0.1;
        check_reads("x0_write_attempt_before_negedge");
        posedge_only("x0_write_attempt_posedge_no_effect");
        negedge_sample_and_update("x0_write_attempt_negedge_ignored");
        drive_reads(5'd0, 5'd0, "x0_stays_zero_after_ignored_write");

        // No asynchronous reset: assert/deassert reset while no negedge occurs.
        reset = 1'b1;
        #0.1;
        check_reads("reset_asserted_between_edges_no_async_effect_on_x0");
        reset = 1'b0;
        #0.1;
        check_reads("reset_deasserted_between_edges_no_async_effect_on_x0");

        // Required synchronous reset before checking initialized x1..x31 contents.
        a1 = 5'd1;
        a2 = 5'd31;
        a3 = 5'd7;
        wd3 = 32'h12345678;
        we3 = 1'b1;
        reset = 1'b1;
        #0.1;
        posedge_only("reset_high_at_posedge_no_effect");
        negedge_sample_and_update("synchronous_reset_applied");

        // After reset, all registers should read zero.
        for (regidx = 0; regidx < 32; regidx = regidx + 1) begin
            regidx5 = regidx[4:0];
            drive_reads(regidx5, regidx5, "post_reset_each_register_zero");
        end

        // Sample usage 1: write x5 = DEADBEEF, then read x5.
        reset = 1'b0;
        we3   = 1'b1;
        a3    = 5'd5;
        wd3   = 32'hDEADBEEF;
        a1    = 5'd0;
        a2    = 5'd0;
        #0.1;
        negedge_sample_and_update("sample_write_x5_deadbeef");
        drive_reads(5'd5, 5'd0, "sample_read_x5_deadbeef");

        // Sample usage 2: write x0 ignored.
        we3   = 1'b1;
        a3    = 5'd0;
        wd3   = 32'hFFFFFFFF;
        #0.1;
        negedge_sample_and_update("sample_write_x0_ignored");
        drive_reads(5'd0, 5'd5, "sample_read_x0_zero_x5_unchanged");

        // Sample usage 3: we3=0 no change to x5.
        we3   = 1'b0;
        a3    = 5'd5;
        wd3   = 32'h0000002A;
        #0.1;
        negedge_sample_and_update("sample_we0_no_change");
        drive_reads(5'd5, 5'd5, "sample_x5_still_deadbeef");

        // Sample usage 4: reset clears x1..x31.
        reset = 1'b1;
        we3   = 1'b1;
        a3    = 5'd5;
        wd3   = 32'hAAAAAAAA;
        #0.1;
        negedge_sample_and_update("sample_reset_clears");
        drive_reads(5'd5, 5'd0, "sample_after_reset_x5_zero");

        reset = 1'b0;
        we3   = 1'b0;
        a3    = 5'd0;
        wd3   = 32'h00000000;

        // Write every register x1..x31 with deterministic patterns including
        // zero, all ones, signed boundaries, and mixed values.
        for (regidx = 1; regidx < 32; regidx = regidx + 1) begin
            regidx5 = regidx[4:0];
            case (regidx)
                1:  pattern = 32'h00000000;
                2:  pattern = 32'hFFFFFFFF;
                3:  pattern = 32'h7FFFFFFF;
                4:  pattern = 32'h80000000;
                5:  pattern = 32'hDEADBEEF;
                6:  pattern = 32'h00000001;
                7:  pattern = 32'hFFFFFFFE;
                8:  pattern = 32'hAAAAAAAA;
                9:  pattern = 32'h55555555;
                default: pattern = 32'h13579BDF ^ {27'd0, regidx5};
            endcase

            we3 = 1'b1;
            a3  = regidx5;
            wd3 = pattern;
            a1  = regidx5;
            a2  = 5'd0;
            #0.1;
            posedge_only("all_regs_write_posedge_no_effect");
            negedge_sample_and_update("all_regs_write_negedge");
            drive_reads(regidx5, 5'd0, "all_regs_readback_after_write");
        end

        // Read all registers on both ports using different pairings.
        for (regidx = 0; regidx < 32; regidx = regidx + 1) begin
            regidx5 = regidx[4:0];
            regidx_rev5 = (31 - regidx)[4:0];
            drive_reads(regidx5, regidx_rev5, "all_regs_dual_port_sweep");
        end

        // Same-address reads on both ports.
        for (regidx = 0; regidx < 32; regidx = regidx + 1) begin
            regidx5 = regidx[4:0];
            drive_reads(regidx5, regidx5, "same_address_both_ports");
        end

        // Explicit no asynchronous reset after known contents exist.
        drive_reads(5'd3, 5'd4, "known_contents_before_async_reset_test");
        reset = 1'b1;
        #0.1;
        check_reads("reset_high_between_edges_contents_unchanged");
        posedge_only("reset_high_posedge_still_no_effect");
        drive_reads(5'd3, 5'd4, "still_unchanged_before_reset_negedge");
        negedge_sample_and_update("reset_takes_effect_at_negedge");
        drive_reads(5'd3, 5'd4, "after_reset_regs_zero");

        // Reset priority over write: attempted write to x9 while reset=1 must be ignored.
        we3   = 1'b1;
        a3    = 5'd9;
        wd3   = 32'hCAFEBABE;
        reset = 1'b1;
        a1    = 5'd9;
        a2    = 5'd0;
        #0.1;
        negedge_sample_and_update("reset_priority_over_write");
        drive_reads(5'd9, 5'd0, "x9_zero_after_reset_priority_case");

        // Deassert reset between edges, then write should work on following negedge.
        reset = 1'b0;
        #0.1;
        check_reads("deassert_reset_between_edges_no_change");
        we3   = 1'b1;
        a3    = 5'd9;
        wd3   = 32'hCAFEBABE;
        #0.1;
        negedge_sample_and_update("write_after_reset_deassert");
        drive_reads(5'd9, 5'd9, "x9_written_after_reset_deassert");

        // Disabled write check with known register.
        we3   = 1'b0;
        a3    = 5'd9;
        wd3   = 32'h11111111;
        #0.1;
        negedge_sample_and_update("disabled_write_known_reg");
        drive_reads(5'd9, 5'd0, "disabled_write_left_reg_unchanged");

        // x0 hardwired to zero even when other regs hold data.
        we3   = 1'b1;
        a3    = 5'd0;
        wd3   = 32'h12345678;
        #0.1;
        negedge_sample_and_update("x0_write_ignored_late");
        drive_reads(5'd0, 5'd9, "x0_zero_and_x9_preserved");

        $display("A1_CHECKS passed=%0d failed=%0d total=%0d", passed, failed, total);
        if ((failed == 0) && (total > 0))
            $display("PASS");
        else
            $display("FAIL");
        $finish;
    end

endmodule
