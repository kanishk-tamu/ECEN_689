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
    integer seed;
    integer idx;
    integer tmp_int;
    logic [4:0] tmp_addr;

    initial begin
        passed = 0;
        failed = 0;
        total = 0;
        fail_prints = 0;
        seed = 32'h1A2B3C4D;
    end

    task automatic model_init_unknown_safe;
        integer k;
        begin
            for (k = 0; k < 32; k = k + 1) begin
                model_regs[k] = 32'h00000000;
            end
            model_regs[0] = 32'h00000000;
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
                model_regs[0] = 32'h00000000;
                if ((we3 === 1'b1) && (a3 !== 5'd0)) begin
                    model_regs[a3] = wd3;
                end
                model_regs[0] = 32'h00000000;
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

    task automatic check_outputs;
        input [255:0] label;
        reg [255:0] l1;
        reg [255:0] l2;
        reg [31:0] e1;
        reg [31:0] e2;
        begin
            #0.01;
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

    task automatic posedge_only;
        input [255:0] label;
        begin
            clk = 1'b0;
            #0.2;
            clk = 1'b1;
            #0.2;
            check_outputs(label);
        end
    endtask

    task automatic apply_negedge_and_check;
        input [255:0] label_after;
        begin
            #0.2;
            clk = 1'b0;
            model_apply_negedge();
            #0.2;
            check_outputs(label_after);
            clk = 1'b1;
            #0.2;
        end
    endtask

    task automatic reset_at_negedge;
        input [255:0] label_after;
        begin
            apply_negedge_and_check(label_after);
        end
    endtask

    task automatic write_and_readback;
        input logic [4:0]  regnum;
        input logic [31:0] value;
        input [255:0]      label;
        begin
            drive_inputs(1'b0, 1'b1, regnum, regnum, regnum, value);
            check_outputs({label, "_before_edge"});
            apply_negedge_and_check({label, "_after_edge"});
        end
    endtask

    task automatic no_write_and_check_hold;
        input logic [4:0]  rdaddr;
        input logic [31:0] ignored_value;
        input [255:0]      label;
        begin
            drive_inputs(1'b0, 1'b0, rdaddr, rdaddr, rdaddr, ignored_value);
            check_outputs({label, "_before_edge"});
            apply_negedge_and_check({label, "_after_edge"});
        end
    endtask

    /* Coverage notes:
       - Tests x0 before and after reset, including attempted writes to x0.
       - Performs explicit synchronous reset at a falling edge before checking x1..x31.
       - Uses both read ports independently and together, including same-address reads.
       - Exercises writes to all x1..x31, disabled writes, reset priority over write.
       - Checks reads are combinational by changing addresses between edges.
       - Verifies no asynchronous reset by toggling reset without a falling edge.
       - Verifies no positive-edge writes by placing activity around posedge only.
       - Uses deterministic fixed vectors plus a locally seeded PRNG-derived pattern.
       - Includes corner values: zero, all ones, signed boundaries, alternating bits. */

    initial begin
        model_init_unknown_safe();

        clk   = 1'b1;
        reset = 1'b0;
        we3   = 1'b0;
        a1    = 5'd0;
        a2    = 5'd0;
        a3    = 5'd0;
        wd3   = 32'h00000000;

        #0.05;

        // x0 is defined even before reset; x1..x31 are not checked before reset.
        drive_inputs(1'b0, 1'b0, 5'd0, 5'd0, 5'd0, 32'h12345678);
        check_outputs("pre_reset_x0_only");

        // Attempted write to x0 before reset must have no effect on x0.
        drive_inputs(1'b0, 1'b1, 5'd0, 5'd0, 5'd0, 32'hFFFFFFFF);
        check_outputs("pre_reset_x0_write_attempt_before_edge");
        apply_negedge_and_check("pre_reset_x0_write_attempt_after_edge");

        // No asynchronous reset: changing reset between edges must not clear state immediately.
        drive_inputs(1'b0, 1'b0, 5'd0, 5'd0, 5'd0, 32'h00000000);
        check_outputs("before_sync_reset");
        reset = 1'b1;
        #0.2;
        check_outputs("reset_high_between_edges_no_async_effect");
        reset = 1'b0;
        #0.2;
        check_outputs("reset_low_between_edges_still_no_effect");

        // Proper synchronous reset on negedge before checking initialized contents.
        drive_inputs(1'b1, 1'b1, 5'd5, 5'd7, 5'd5, 32'hDEADBEEF);
        reset_at_negedge("sync_reset_clears_regs");

        // After reset all registers x1..x31 must read zero; check all registers on both ports.
        for (i = 0; i < 32; i = i + 1) begin
            tmp_addr = i[4:0];
            drive_inputs(1'b0, 1'b0, tmp_addr, tmp_addr, 5'd0, 32'h00000000);
            check_outputs("post_reset_all_regs_same_both_ports");
        end

        // Sample usage case: write x5 = DEADBEEF then read x5.
        write_and_readback(5'd5, 32'hDEADBEEF, "sample_write_x5_deadbeef");

        // Sample usage case: write x0 ignored, x0 remains zero.
        drive_inputs(1'b0, 1'b1, 5'd0, 5'd0, 5'd0, 32'hFFFFFFFF);
        check_outputs("sample_write_x0_ignored_before_edge");
        apply_negedge_and_check("sample_write_x0_ignored_after_edge");

        // Sample usage case: we3=0 means no change to x5.
        drive_inputs(1'b0, 1'b0, 5'd5, 5'd5, 5'd5, 32'h0000002A);
        check_outputs("sample_we0_no_change_before_edge");
        apply_negedge_and_check("sample_we0_no_change_after_edge");

        // Sample usage case: reset clears x5.
        drive_inputs(1'b1, 1'b0, 5'd5, 5'd5, 5'd0, 32'h00000000);
        apply_negedge_and_check("sample_reset_clears_x5");

        // Reinitialize after reset for broader testing.
        drive_inputs(1'b1, 1'b0, 5'd1, 5'd31, 5'd0, 32'h00000000);
        apply_negedge_and_check("second_reset_baseline");

        // Positive-edge should not write.
        drive_inputs(1'b0, 1'b1, 5'd9, 5'd9, 5'd9, 32'hCAFEBABE);
        check_outputs("posedge_write_test_before_posedge");
        posedge_only("posedge_write_test_after_posedge_only");
        drive_inputs(1'b0, 1'b0, 5'd9, 5'd9, 5'd9, 32'h00000000);
        check_outputs("posedge_write_still_not_written");
        drive_inputs(1'b0, 1'b1, 5'd9, 5'd9, 5'd9, 32'hCAFEBABE);
        apply_negedge_and_check("posedge_write_then_real_negedge_writes");

        // Reset priority over write at negedge.
        drive_inputs(1'b0, 1'b1, 5'd10, 5'd10, 5'd10, 32'h13579BDF);
        apply_negedge_and_check("setup_x10_nonzero");
        drive_inputs(1'b1, 1'b1, 5'd10, 5'd10, 5'd10, 32'hFFFFFFFF);
        apply_negedge_and_check("reset_priority_over_write_x10");

        // Write corner values to selected registers and read on both ports.
        write_and_readback(5'd1,  32'h00000000, "corner_zero_x1");
        write_and_readback(5'd2,  32'hFFFFFFFF, "corner_allones_x2");
        write_and_readback(5'd3,  32'h7FFFFFFF, "corner_maxpos_x3");
        write_and_readback(5'd4,  32'h80000000, "corner_minneg_x4");
        write_and_readback(5'd6,  32'hAAAAAAAA, "corner_alt_a_x6");
        write_and_readback(5'd7,  32'h55555555, "corner_alt_5_x7");

        // Both ports same and different addresses, combinational reads without edges.
        drive_inputs(1'b0, 1'b0, 5'd3, 5'd4, 5'd0, 32'h00000000);
        check_outputs("comb_read_diff_addrs");
        drive_inputs(1'b0, 1'b0, 5'd2, 5'd2, 5'd0, 32'h00000000);
        check_outputs("comb_read_same_addr_both_ports");
        drive_inputs(1'b0, 1'b0, 5'd0, 5'd7, 5'd0, 32'h00000000);
        check_outputs("comb_read_x0_and_x7");
        drive_inputs(1'b0, 1'b0, 5'd7, 5'd0, 5'd0, 32'h00000000);
        check_outputs("comb_read_x7_and_x0");

        // Write every nonzero register with deterministic distinct values, then verify through both ports.
        for (i = 1; i < 32; i = i + 1) begin
            tmp_int = seed ^ (i * 32'h1020304) ^ (i << 16) ^ (i << 1);
            write_and_readback(i[4:0], tmp_int[31:0], "all_regs_write_pass");
        end

        // Verify every register value via both ports with complementary addressing.
        for (i = 0; i < 32; i = i + 1) begin
            tmp_addr = i[4:0];
            tmp_int = 31 - i;
            tmp_addr = i[4:0];
            drive_inputs(1'b0, 1'b0, i[4:0], tmp_int[4:0], 5'd0, 32'h00000000);
            check_outputs("all_regs_dual_read_verify");
        end

        // Disabled write for all registers should hold prior contents.
        for (i = 1; i < 32; i = i + 1) begin
            drive_inputs(1'b0, 1'b0, i[4:0], i[4:0], i[4:0], ~model_regs[i]);
            check_outputs("disabled_write_hold_before_edge");
            apply_negedge_and_check("disabled_write_hold_after_edge");
        end

        // Another explicit x0 write ignore after many operations.
        drive_inputs(1'b0, 1'b1, 5'd0, 5'd1, 5'd0, 32'h1234ABCD);
        check_outputs("late_x0_write_ignore_before_edge");
        apply_negedge_and_check("late_x0_write_ignore_after_edge");

        // Final reset and verify all registers clear.
        drive_inputs(1'b1, 1'b1, 5'd31, 5'd30, 5'd31, 32'h89ABCDEF);
        apply_negedge_and_check("final_reset");
        for (i = 0; i < 32; i = i + 1) begin
            idx = 31 - i;
            drive_inputs(1'b0, 1'b0, i[4:0], idx[4:0], 5'd0, 32'h00000000);
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
