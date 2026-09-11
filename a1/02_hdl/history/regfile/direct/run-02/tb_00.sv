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

    task automatic posedge_only;
        begin
            clk = 1'b0;
            #0.2;
            clk = 1'b1;
            #0.2;
        end
    endtask

    task automatic negedge_sample_and_update;
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

    initial begin : watchdog
        #1000;
        $display("FAIL");
        $finish;
    end

    initial begin : test_main
        integer idx;
        integer rev;
        reg [4:0] idx5;
        reg [4:0] rev5;
        reg [31:0] pattern;

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

        // Pre-reset: only x0 is defined, so test only x0 behavior before any reset.
        a1 = 5'd0;
        a2 = 5'd0;
        #0.1;
        check32("pre_reset_x0 rd1", rd1, 32'h00000000);
        check32("pre_reset_x0 rd2", rd2, 32'h00000000);

        // Attempt write to x0 before reset; x0 must remain zero.
        we3 = 1'b1;
        a3  = 5'd0;
        wd3 = 32'hFFFFFFFF;
        a1  = 5'd0;
        a2  = 5'd0;
        negedge_sample_and_update();
        check_reads("pre_reset_write_x0_ignored");

        // No asynchronous reset: changing reset while no negedge occurs must not clear regs.
        // Use a positive edge only, with x0 checks only since other regs are unspecified.
        reset = 1'b1;
        posedge_only();
        a1 = 5'd0;
        a2 = 5'd0;
        check_reads("no_async_reset_x0_only");
        reset = 1'b0;

        // Synchronous reset to establish known state for x1..x31.
        we3 = 1'b0;
        a3  = 5'd0;
        wd3 = 32'h12345678;
        a1  = 5'd0;
        a2  = 5'd1;
        reset = 1'b1;
        negedge_sample_and_update();
        check_reads("post_sync_reset_sample");

        // After reset, all registers should read zero on both ports.
        for (idx = 0; idx < 32; idx = idx + 1) begin
            idx5 = idx[4:0];
            a1 = idx5;
            a2 = idx5;
            check_reads("all_regs_zero_after_reset_same_addr_both_ports");
        end

        // Read same/different registers combinationally after reset.
        a1 = 5'd3;
        a2 = 5'd7;
        check_reads("independent_combinational_reads_after_reset");

        // Sample usage case 1: write x5 = DEADBEEF, then read x5.
        reset = 1'b0;
        we3   = 1'b1;
        a3    = 5'd5;
        wd3   = 32'hDEADBEEF;
        a1    = 5'd5;
        a2    = 5'd0;
        negedge_sample_and_update();
        check_reads("sample_write_x5_deadbeef");

        // Sample usage case 2: write x0 ignored.
        we3   = 1'b1;
        a3    = 5'd0;
        wd3   = 32'hFFFFFFFF;
        a1    = 5'd0;
        a2    = 5'd5;
        negedge_sample_and_update();
        check_reads("sample_write_x0_ignored");

        // Sample usage case 3: we3=0 means no change to x5.
        we3   = 1'b0;
        a3    = 5'd5;
        wd3   = 32'h0000002A;
        a1    = 5'd5;
        a2    = 5'd0;
        negedge_sample_and_update();
        check_reads("sample_we3_zero_no_change");

        // Sample usage case 4: reset clears x1..x31.
        reset = 1'b1;
        we3   = 1'b1;
        a3    = 5'd5;
        wd3   = 32'hAAAAAAAA;
        a1    = 5'd5;
        a2    = 5'd0;
        negedge_sample_and_update();
        check_reads("sample_reset_clears_x5");

        reset = 1'b0;

        // Verify positive edge does not write.
        we3   = 1'b1;
        a3    = 5'd6;
        wd3   = 32'hCAFEBABE;
        a1    = 5'd6;
        a2    = 5'd0;
        posedge_only();
        check_reads("no_posedge_write");

        // Now falling edge writes.
        negedge_sample_and_update();
        check_reads("write_occurs_on_negedge");

        // Reset change between edges without negedge should not affect state.
        a1    = 5'd6;
        a2    = 5'd5;
        reset = 1'b1;
        #0.1;
        check_reads("reset_change_between_edges_no_effect_before_negedge");
        reset = 1'b0;
        #0.1;
        check_reads("reset_deassert_between_edges_no_effect_before_negedge");

        // Write all x1..x31 with deterministic patterns; also read previous/current via both ports.
        for (idx = 1; idx < 32; idx = idx + 1) begin
            idx5 = idx[4:0];
            pattern = 32'h01010101 * idx;
            if (idx == 1) pattern = 32'h00000000;
            if (idx == 2) pattern = 32'hFFFFFFFF;
            if (idx == 3) pattern = 32'h7FFFFFFF;
            if (idx == 4) pattern = 32'h80000000;

            we3 = 1'b1;
            a3  = idx5;
            wd3 = pattern;
            a1  = idx5;
            if (idx == 31) begin
                a2 = 5'd0;
            end else begin
                a2 = (idx + 1)[4:0];
            end

            // Before negedge, rd1/rd2 should still reflect old state (no bypass/forwarding needed).
            check_reads("before_negedge_old_contents_visible");

            negedge_sample_and_update();
            check_reads("after_negedge_new_contents_visible");
        end

        // Verify every register content using both ports with mirrored addressing.
        for (idx = 0; idx < 32; idx = idx + 1) begin
            for (rev = 0; rev < 32; rev = rev + 1) begin
                if (rev == (31 - idx)) begin
                    idx5 = idx[4:0];
                    rev5 = rev[4:0];
                    a1 = idx5;
                    a2 = rev5;
                    check_reads("full_space_readback_both_ports");
                end
            end
        end

        // Explicit x0 checks among other populated registers.
        a1 = 5'd0;
        a2 = 5'd6;
        check_reads("x0_always_zero_with_other_reg_nonzero");

        we3 = 1'b1;
        a3  = 5'd0;
        wd3 = 32'h12345678;
        a1  = 5'd0;
        a2  = 5'd0;
        negedge_sample_and_update();
        check_reads("x0_write_attempt_after_population_ignored");

        // Disabled write check on a nonzero register.
        a1 = 5'd10;
        a2 = 5'd10;
        check_reads("capture_x10_before_disabled_write");
        we3 = 1'b0;
        a3  = 5'd10;
        wd3 = 32'hA5A5A5A5;
        negedge_sample_and_update();
        check_reads("disabled_write_x10_no_change");

        // Reset priority over write.
        we3   = 1'b1;
        reset = 1'b1;
        a3    = 5'd11;
        wd3   = 32'hFFFFFFFF;
        a1    = 5'd11;
        a2    = 5'd6;
        negedge_sample_and_update();
        check_reads("reset_priority_over_write_at_negedge");

        // After reset priority event, all regs x1..x31 should be zero.
        reset = 1'b0;
        we3   = 1'b0;
        for (idx = 0; idx < 32; idx = idx + 1) begin
            idx5 = idx[4:0];
            a1 = idx5;
            a2 = idx5;
            check_reads("all_regs_zero_after_reset_priority_case");
        end

        // Boundary and representative values after known reset state.
        we3 = 1'b1; a3 = 5'd1;  wd3 = 32'h00000000; a1 = 5'd1;  a2 = 5'd0; negedge_sample_and_update(); check_reads("boundary_zero");
        we3 = 1'b1; a3 = 5'd2;  wd3 = 32'hFFFFFFFF; a1 = 5'd2;  a2 = 5'd0; negedge_sample_and_update(); check_reads("boundary_all_ones");
        we3 = 1'b1; a3 = 5'd3;  wd3 = 32'h7FFFFFFF; a1 = 5'd3;  a2 = 5'd0; negedge_sample_and_update(); check_reads("boundary_max_positive");
        we3 = 1'b1; a3 = 5'd4;  wd3 = 32'h80000000; a1 = 5'd4;  a2 = 5'd0; negedge_sample_and_update(); check_reads("boundary_min_negative");
        we3 = 1'b1; a3 = 5'd31; wd3 = 32'h80000001; a1 = 5'd31; a2 = 5'd4; negedge_sample_and_update(); check_reads("boundary_highest_reg_index");

        // Combinational read address changes with no clock edge.
        we3 = 1'b0;
        a1 = 5'd2; a2 = 5'd3; check_reads("comb_read_change_1");
        a1 = 5'd4; a2 = 5'd31; check_reads("comb_read_change_2");
        a1 = 5'd0; a2 = 5'd1; check_reads("comb_read_change_3");

        $display("A1_CHECKS passed=%0d failed=%0d total=%0d", passed, failed, total);
        if ((failed == 0) && (total > 0)) begin
            $display("PASS");
        end else begin
            $display("FAIL");
        end
        $finish;
    end

endmodule
