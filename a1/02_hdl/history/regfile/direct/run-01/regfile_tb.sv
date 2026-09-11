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
        .clk  (clk),
        .reset(reset),
        .we3  (we3),
        .a1   (a1),
        .a2   (a2),
        .a3   (a3),
        .wd3  (wd3),
        .rd1  (rd1),
        .rd2  (rd2)
    );

    logic [31:0] model_regs [0:31];

    integer passed;
    integer failed;
    integer total;
    integer fail_prints;
    integer i;
    integer idx;
    integer tmp_int;
    integer seed;
    logic [4:0] tmp_a1;
    logic [4:0] tmp_a2;
    logic [4:0] tmp_a3;
    logic [31:0] tmp_data;

    task automatic report_compare;
        input [255:0] label;
        input [31:0] actual;
        input [31:0] expected;
        begin
            total = total + 1;
            if (actual === expected) begin
                passed = passed + 1;
            end
            else begin
                failed = failed + 1;
                if (fail_prints < 8) begin
                    $display("FAIL label=%0s a1=%0d a2=%0d a3=%0d we3=%0b reset=%0b wd3=0x%08h actual=0x%08h expected=0x%08h",
                             label, a1, a2, a3, we3, reset, wd3, actual, expected);
                    fail_prints = fail_prints + 1;
                end
            end
        end
    endtask

    function automatic [31:0] exp_rd1_fn;
        begin
            if (a1 == 5'd0) exp_rd1_fn = 32'h00000000;
            else            exp_rd1_fn = model_regs[a1];
        end
    endfunction

    function automatic [31:0] exp_rd2_fn;
        begin
            if (a2 == 5'd0) exp_rd2_fn = 32'h00000000;
            else            exp_rd2_fn = model_regs[a2];
        end
    endfunction

    task automatic check_outputs;
        input [255:0] label;
        reg [255:0] l1;
        reg [255:0] l2;
        reg [31:0] e1;
        reg [31:0] e2;
        begin
            #0.05;
            e1 = exp_rd1_fn();
            e2 = exp_rd2_fn();
            l1 = {label, "_rd1"};
            l2 = {label, "_rd2"};
            report_compare(l1, rd1, e1);
            report_compare(l2, rd2, e2);
        end
    endtask

    task automatic drive_inputs;
        input logic        t_reset;
        input logic        t_we3;
        input logic [4:0]  t_a1;
        input logic [4:0]  t_a2;
        input logic [4:0]  t_a3;
        input logic [31:0] t_wd3;
        begin
            reset = t_reset;
            we3   = t_we3;
            a1    = t_a1;
            a2    = t_a2;
            a3    = t_a3;
            wd3   = t_wd3;
        end
    endtask

    task automatic model_reset_after_sync_reset;
        integer k;
        begin
            model_regs[0] = 32'h00000000;
            for (k = 1; k < 32; k = k + 1) begin
                model_regs[k] = 32'h00000000;
            end
        end
    endtask

    task automatic model_apply_negedge;
        integer k;
        begin
            if (reset === 1'b1) begin
                for (k = 1; k < 32; k = k + 1) begin
                    model_regs[k] = 32'h00000000;
                end
                model_regs[0] = 32'h00000000;
            end
            else begin
                if ((we3 === 1'b1) && (a3 != 5'd0)) begin
                    model_regs[a3] = wd3;
                end
                model_regs[0] = 32'h00000000;
            end
        end
    endtask

    task automatic drive_fall_and_update;
        begin
            #0.20;
            clk = 1'b0;
            model_apply_negedge();
            #0.20;
        end
    endtask

    task automatic rise_only_no_model_update;
        begin
            #0.20;
            clk = 1'b1;
            #0.20;
        end
    endtask

    task automatic write_and_readback;
        input logic [4:0]  regnum;
        input logic [31:0] value;
        input [255:0]      label;
        begin
            drive_inputs(1'b0, 1'b1, regnum, regnum, regnum, value);
            check_outputs({label, "_before_edge"});
            drive_fall_and_update();
            check_outputs({label, "_after_edge"});
            rise_only_no_model_update();
        end
    endtask

    initial begin
        passed = 0;
        failed = 0;
        total = 0;
        fail_prints = 0;
        seed = 32'h1A2B3C4D;

        clk   = 1'b1;
        reset = 1'b0;
        we3   = 1'b0;
        a1    = 5'd0;
        a2    = 5'd0;
        a3    = 5'd0;
        wd3   = 32'h00000000;

        model_regs[0] = 32'h00000000;
        for (i = 1; i < 32; i = i + 1) begin
            model_regs[i] = 32'hxxxxxxxx;
        end

        #0.05;

        /* Coverage summary:
           - Tests x0 before reset, since only x0 has defined pre-reset behavior.
           - Performs a synchronous reset at a falling edge before checking x1..x31.
           - Checks both combinational read ports on same and different addresses.
           - Exercises writes to all x1..x31, ignored writes to x0, and we3=0 hold.
           - Verifies reset sampled only on negedge and that reset has priority over write.
           - Uses a manually driven clock in a single stimulus flow; every negedge is paired
             with a reference-model update and every posedge is tested without model update.
           - Checks that positive edges and reset changes between edges do not alter state.
           - Includes sample usage cases and corner data values: zero, all ones,
             signed boundaries, alternating-bit patterns, and deterministic per-register data.
           - Only checks defined behavior; does not assume non-x0 power-up contents. */

        // x0 is always zero even before any reset.
        drive_inputs(1'b0, 1'b0, 5'd0, 5'd0, 5'd0, 32'h12345678);
        check_outputs("pre_reset_x0_only");

        // Attempted write to x0 before reset must not change x0.
        drive_inputs(1'b0, 1'b1, 5'd0, 5'd0, 5'd0, 32'hFFFFFFFF);
        check_outputs("pre_reset_x0_write_attempt_before_edge");
        drive_fall_and_update();
        check_outputs("pre_reset_x0_write_attempt_after_edge");
        rise_only_no_model_update();

        // No asynchronous reset: changing reset between edges must not immediately affect outputs.
        drive_inputs(1'b0, 1'b0, 5'd0, 5'd0, 5'd0, 32'h00000000);
        check_outputs("before_sync_reset_x0");
        reset = 1'b1;
        #0.20;
        check_outputs("reset_high_between_edges_no_async_effect");
        reset = 1'b0;
        #0.20;
        check_outputs("reset_low_between_edges_no_async_effect");

        // Apply the required synchronous reset before checking initialized register contents.
        drive_inputs(1'b1, 1'b1, 5'd5, 5'd7, 5'd5, 32'hDEADBEEF);
        drive_fall_and_update();
        check_outputs("sync_reset_clears_regs");
        rise_only_no_model_update();

        // After synchronous reset all registers must read zero.
        for (i = 0; i < 32; i = i + 1) begin
            tmp_a1 = i[4:0];
            drive_inputs(1'b0, 1'b0, tmp_a1, tmp_a1, 5'd0, 32'h00000000);
            check_outputs("post_reset_all_regs_same_both_ports");
        end

        // Sample usage: write x5 = DEADBEEF.
        write_and_readback(5'd5, 32'hDEADBEEF, "sample_write_x5_deadbeef");

        // Sample usage: write x0 ignored.
        drive_inputs(1'b0, 1'b1, 5'd0, 5'd0, 5'd0, 32'hFFFFFFFF);
        check_outputs("sample_write_x0_ignored_before_edge");
        drive_fall_and_update();
        check_outputs("sample_write_x0_ignored_after_edge");
        rise_only_no_model_update();

        // Sample usage: we3=0 means x5 holds previous value.
        drive_inputs(1'b0, 1'b0, 5'd5, 5'd5, 5'd5, 32'h0000002A);
        check_outputs("sample_we0_no_change_before_edge");
        drive_fall_and_update();
        check_outputs("sample_we0_no_change_after_edge");
        rise_only_no_model_update();

        // Sample usage: reset clears x5.
        drive_inputs(1'b1, 1'b0, 5'd5, 5'd5, 5'd0, 32'h00000000);
        drive_fall_and_update();
        check_outputs("sample_reset_clears_x5");
        rise_only_no_model_update();

        // Second reset baseline.
        drive_inputs(1'b1, 1'b0, 5'd1, 5'd31, 5'd0, 32'h00000000);
        drive_fall_and_update();
        check_outputs("second_reset_baseline");
        rise_only_no_model_update();

        // Positive-edge writes are NOT defined; only negedge writes are.
        // Check around a posedge only, without any accidental falling edge.
        drive_inputs(1'b0, 1'b1, 5'd9, 5'd9, 5'd9, 32'hCAFEBABE);
        check_outputs("posedge_write_test_before_posedge");
        rise_only_no_model_update();
        check_outputs("posedge_write_test_after_posedge_only");
        drive_inputs(1'b0, 1'b0, 5'd9, 5'd9, 5'd9, 32'h00000000);
        check_outputs("posedge_write_still_not_written");
        drive_inputs(1'b0, 1'b1, 5'd9, 5'd9, 5'd9, 32'hCAFEBABE);
        drive_fall_and_update();
        check_outputs("posedge_write_then_real_negedge_writes");
        rise_only_no_model_update();

        // Reset priority over write at negedge.
        drive_inputs(1'b0, 1'b1, 5'd10, 5'd10, 5'd10, 32'h13579BDF);
        drive_fall_and_update();
        check_outputs("setup_x10_nonzero");
        rise_only_no_model_update();

        drive_inputs(1'b1, 1'b1, 5'd10, 5'd10, 5'd10, 32'hFFFFFFFF);
        drive_fall_and_update();
        check_outputs("reset_priority_over_write_x10");
        rise_only_no_model_update();

        // Corner values.
        write_and_readback(5'd1, 32'h00000000, "corner_zero_x1");
        write_and_readback(5'd2, 32'hFFFFFFFF, "corner_allones_x2");
        write_and_readback(5'd3, 32'h7FFFFFFF, "corner_maxpos_x3");
        write_and_readback(5'd4, 32'h80000000, "corner_minneg_x4");
        write_and_readback(5'd6, 32'hAAAAAAAA, "corner_alt_a_x6");
        write_and_readback(5'd7, 32'h55555555, "corner_alt_5_x7");

        // Combinational read coverage on same and different ports/addresses.
        drive_inputs(1'b0, 1'b0, 5'd3, 5'd4, 5'd0, 32'h00000000);
        check_outputs("comb_read_diff_addrs");
        drive_inputs(1'b0, 1'b0, 5'd2, 5'd2, 5'd0, 32'h00000000);
        check_outputs("comb_read_same_addr_both_ports");
        drive_inputs(1'b0, 1'b0, 5'd0, 5'd7, 5'd0, 32'h00000000);
        check_outputs("comb_read_x0_and_x7");
        drive_inputs(1'b0, 1'b0, 5'd7, 5'd0, 5'd0, 32'h00000000);
        check_outputs("comb_read_x7_and_x0");

        // Write all x1..x31 with deterministic distinct values.
        for (i = 1; i < 32; i = i + 1) begin
            tmp_int = seed ^ (i * 32'h01020304) ^ (i << 16) ^ (i << 1);
            tmp_a3 = i[4:0];
            tmp_data = tmp_int[31:0];
            write_and_readback(tmp_a3, tmp_data, "all_regs_write_pass");
        end

        // Verify every register via both read ports using complementary addresses.
        for (i = 0; i < 32; i = i + 1) begin
            idx = 31 - i;
            tmp_a1 = i[4:0];
            tmp_a2 = idx[4:0];
            drive_inputs(1'b0, 1'b0, tmp_a1, tmp_a2, 5'd0, 32'h00000000);
            check_outputs("all_regs_dual_read_verify");
        end

        // Disabled write must hold contents for every x1..x31.
        for (i = 1; i < 32; i = i + 1) begin
            tmp_a3 = i[4:0];
            drive_inputs(1'b0, 1'b0, tmp_a3, tmp_a3, tmp_a3, ~model_regs[i]);
            check_outputs("disabled_write_hold_before_edge");
            drive_fall_and_update();
            check_outputs("disabled_write_hold_after_edge");
            rise_only_no_model_update();
        end

        // Late x0 write ignore check.
        drive_inputs(1'b0, 1'b1, 5'd0, 5'd1, 5'd0, 32'h1234ABCD);
        check_outputs("late_x0_write_ignore_before_edge");
        drive_fall_and_update();
        check_outputs("late_x0_write_ignore_after_edge");
        rise_only_no_model_update();

        // Reset changes on high clock level should not be asynchronous.
        drive_inputs(1'b0, 1'b0, 5'd1, 5'd9, 5'd0, 32'h00000000);
        check_outputs("pre_async_reset_probe");
        reset = 1'b1;
        #0.20;
        check_outputs("async_reset_probe_high_no_effect");
        reset = 1'b0;
        #0.20;
        check_outputs("async_reset_probe_low_no_effect");

        // Final synchronous reset and verify all registers clear.
        drive_inputs(1'b1, 1'b1, 5'd31, 5'd30, 5'd31, 32'h89ABCDEF);
        drive_fall_and_update();
        check_outputs("final_reset");
        rise_only_no_model_update();

        for (i = 0; i < 32; i = i + 1) begin
            idx = 31 - i;
            tmp_a1 = i[4:0];
            tmp_a2 = idx[4:0];
            drive_inputs(1'b0, 1'b0, tmp_a1, tmp_a2, 5'd0, 32'h00000000);
            check_outputs("final_post_reset_verify_all");
        end

        $display("A1_CHECKS passed=%0d failed=%0d total=%0d", passed, failed, total);
        if ((failed == 0) && (total > 0)) $display("PASS");
        else                               $display("FAIL");
        $finish;
    end

    initial begin
        #1000;
        $display("FAIL");
        $finish;
    end

endmodule
