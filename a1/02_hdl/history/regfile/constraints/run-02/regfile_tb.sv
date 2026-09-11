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
    integer seed;

    logic [31:0] exp_rd1;
    logic [31:0] exp_rd2;
    logic [4:0]  tmp_addr;

    initial begin
        passed = 0;
        failed = 0;
        total  = 0;
        fail_prints = 0;
        seed = 32'h689A1001;
    end

    // Watchdog to ensure simulation terminates cleanly.
    initial begin
        #1000;
        $display("FAIL");
        $finish;
    end

    function automatic [31:0] model_read(input logic [4:0] addr);
        begin
            if (addr == 5'd0) model_read = 32'h00000000;
            else              model_read = model_regs[addr];
        end
    endfunction

    function automatic [31:0] next_rand(input integer cur);
        integer x;
        begin
            x = cur;
            x = x * 1103515245 + 12345;
            next_rand = x[31:0];
        end
    endfunction

    task automatic check_one32(
        input [8*40-1:0] label,
        input [31:0] actual,
        input [31:0] expected
    );
        begin
            total = total + 1;
            if (actual === expected) begin
                passed = passed + 1;
            end else begin
                failed = failed + 1;
                if (fail_prints < 8) begin
                    $display("FAILCHK label=%0s a1=%0d a2=%0d a3=%0d we3=%0b reset=%0b wd3=0x%08h actual=0x%08h expected=0x%08h",
                             label, a1, a2, a3, we3, reset, wd3, actual, expected);
                    fail_prints = fail_prints + 1;
                end
            end
        end
    endtask

    task automatic check_reads(input [8*40-1:0] label);
        begin
            #0.1; // combinational settling
            exp_rd1 = model_read(a1);
            exp_rd2 = model_read(a2);
            check_one32({label, "_rd1"}, rd1, exp_rd1);
            check_one32({label, "_rd2"}, rd2, exp_rd2);
        end
    endtask

    task automatic drive_and_check_comb(
        input [8*40-1:0] label,
        input logic [4:0] ta1,
        input logic [4:0] ta2,
        input logic [4:0] ta3,
        input logic       twe3,
        input logic       treset,
        input logic [31:0] twd3
    );
        begin
            a1    = ta1;
            a2    = ta2;
            a3    = ta3;
            we3   = twe3;
            reset = treset;
            wd3   = twd3;
            check_reads(label);
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

    task automatic negedge_apply_and_model(
        input [8*40-1:0] label,
        input logic [4:0] ta1,
        input logic [4:0] ta2,
        input logic [4:0] ta3,
        input logic       twe3,
        input logic       treset,
        input logic [31:0] twd3
    );
        integer j;
        begin
            // Per spec/review: set inputs while clk is high, then create the falling edge.
            clk   = 1'b1;
            a1    = ta1;
            a2    = ta2;
            a3    = ta3;
            we3   = twe3;
            reset = treset;
            wd3   = twd3;
            #0.2;

            clk = 1'b0; // sampled edge
            if (treset) begin
                for (j = 1; j < 32; j = j + 1)
                    model_regs[j] = 32'h00000000;
                model_regs[0] = 32'h00000000;
            end else if (twe3 && (ta3 != 5'd0)) begin
                model_regs[ta3] = twd3;
                model_regs[0]   = 32'h00000000;
            end else begin
                model_regs[0]   = 32'h00000000;
            end

            #0.2; // allow nonblocking updates and combinational settle
            check_reads(label);
        end
    endtask

    initial begin
        // Initialize TB-driven signals. x1..x31 are unspecified before reset, so do not check them yet.
        clk   = 1'b1;
        reset = 1'b0;
        we3   = 1'b0;
        a1    = 5'd0;
        a2    = 5'd0;
        a3    = 5'd0;
        wd3   = 32'h00000000;
        for (i = 0; i < 32; i = i + 1)
            model_regs[i] = 32'h00000000;

        // Before reset, only x0 is defined. Check both read ports reading x0.
        drive_and_check_comb("pre_reset_x0_both", 5'd0, 5'd0, 5'd0, 1'b0, 1'b0, 32'h12345678);

        // No asynchronous reset: changing reset between edges must not alter stored state.
        reset = 1'b1;
        #0.2;
        check_reads("async_reset_noeffect_x0only");
        reset = 1'b0;
        #0.2;
        check_reads("async_reset_deassert_noeffect_x0only");

        // Positive edge should not write or reset.
        // Use x0-only reads here before synchronous reset, since others are unspecified.
        a1 = 5'd0; a2 = 5'd0; a3 = 5'd7; we3 = 1'b1; wd3 = 32'hAAAAAAAA; reset = 1'b0;
        posedge_only();
        check_reads("posedge_no_write_before_reset");

        // First required synchronous reset to establish known model state for x1..x31.
        negedge_apply_and_model("sync_reset_init", 5'd1, 5'd31, 5'd0, 1'b0, 1'b1, 32'h00000000);

        // After reset, all registers known zero. Check all registers on both ports.
        for (i = 0; i < 32; i = i + 1) begin
            tmp_addr = i[4:0];
            drive_and_check_comb("post_reset_all_zero_same", tmp_addr, tmp_addr, 5'd0, 1'b0, 1'b0, 32'h0);
        end
        for (i = 0; i < 32; i = i + 1) begin
            tmp_addr = i[4:0];
            drive_and_check_comb("post_reset_all_zero_mirror", tmp_addr, (5'd31 - tmp_addr), 5'd0, 1'b0, 1'b0, 32'h0);
        end

        // Sample usage examples from spec.
        negedge_apply_and_model("sample_write_x5_deadbeef", 5'd5, 5'd0, 5'd5, 1'b1, 1'b0, 32'hDEADBEEF);
        negedge_apply_and_model("sample_write_x0_ignored",   5'd0, 5'd5, 5'd0, 1'b1, 1'b0, 32'hFFFFFFFF);
        negedge_apply_and_model("sample_we0_nochange",       5'd5, 5'd0, 5'd5, 1'b0, 1'b0, 32'h0000002A);
        negedge_apply_and_model("sample_reset",              5'd5, 5'd0, 5'd0, 1'b0, 1'b1, 32'h00000000);

        // Explicit x0 behavior: reads always zero, writes ignored, remains zero.
        negedge_apply_and_model("x0_write_zero_data",  5'd0, 5'd0, 5'd0, 1'b1, 1'b0, 32'h00000000);
        negedge_apply_and_model("x0_write_allones",    5'd0, 5'd0, 5'd0, 1'b1, 1'b0, 32'hFFFFFFFF);
        negedge_apply_and_model("x0_write_random",     5'd0, 5'd0, 5'd0, 1'b1, 1'b0, 32'h13579BDF);

        // Positive-edge write/reset must not take effect.
        a1 = 5'd3; a2 = 5'd4; a3 = 5'd3; we3 = 1'b1; wd3 = 32'hCAFEBABE; reset = 1'b0;
        posedge_only();
        check_reads("posedge_no_write_after_reset");

        a1 = 5'd3; a2 = 5'd4; a3 = 5'd4; we3 = 1'b1; wd3 = 32'h11111111; reset = 1'b1;
        posedge_only();
        check_reads("posedge_no_reset");

        // Reset priority over write on negedge.
        negedge_apply_and_model("write_x3_before_priority", 5'd3, 5'd0, 5'd3, 1'b1, 1'b0, 32'hAAAA5555);
        negedge_apply_and_model("reset_priority_over_write", 5'd3, 5'd9, 5'd9, 1'b1, 1'b1, 32'h12345678);

        // No asynchronous reset between edges after known writes.
        negedge_apply_and_model("write_x8_known", 5'd8, 5'd0, 5'd8, 1'b1, 1'b0, 32'h80000000);
        drive_and_check_comb("before_async_reset_toggle", 5'd8, 5'd0, 5'd0, 1'b0, 1'b0, 32'h0);
        reset = 1'b1;
        #0.2;
        check_reads("async_reset_hold_noeffect");
        reset = 1'b0;
        #0.2;
        check_reads("async_reset_release_noeffect");

        // Test all registers x1..x31 with deterministic patterns and both read ports.
        // Includes zero, signed boundaries, all ones, and varied values.
        for (i = 1; i < 32; i = i + 1) begin
            case (i)
                1:  wd3 = 32'h00000000;
                2:  wd3 = 32'hFFFFFFFF;
                3:  wd3 = 32'h7FFFFFFF;
                4:  wd3 = 32'h80000000;
                5:  wd3 = 32'hDEADBEEF;
                6:  wd3 = 32'h00000001;
                7:  wd3 = 32'hFFFFFFFE;
                8:  wd3 = 32'hAAAAAAAA;
                9:  wd3 = 32'h55555555;
                default: begin
                    seed = next_rand(seed);
                    wd3 = seed ^ (32'h01010101 * i);
                end
            endcase
            tmp_addr = i[4:0];
            negedge_apply_and_model("write_each_reg", tmp_addr, 5'd0, tmp_addr, 1'b1, 1'b0, wd3);
            drive_and_check_comb("comb_read_after_write_same", tmp_addr, tmp_addr, 5'd0, 1'b0, 1'b0, 32'h0);
        end

        // Verify all registers readable on both ports, same and different addresses.
        for (i = 0; i < 32; i = i + 1) begin
            tmp_addr = i[4:0];
            drive_and_check_comb("readback_same_addr_both_ports", tmp_addr, tmp_addr, 5'd0, 1'b0, 1'b0, 32'h0);
        end
        for (i = 0; i < 32; i = i + 1) begin
            tmp_addr = i[4:0];
            drive_and_check_comb("readback_diff_addr_ports", tmp_addr, (5'd31 - tmp_addr), 5'd0, 1'b0, 1'b0, 32'h0);
        end

        // Disabled writes must not change state.
        negedge_apply_and_model("disabled_write_x10", 5'd10, 5'd11, 5'd10, 1'b0, 1'b0, 32'h12341234);
        negedge_apply_and_model("disabled_write_x31", 5'd31, 5'd30, 5'd31, 1'b0, 1'b0, 32'h87654321);

        // Overwrite selected registers and immediately observe updated combinational outputs.
        negedge_apply_and_model("overwrite_x1",  5'd1,  5'd2,  5'd1,  1'b1, 1'b0, 32'h11111111);
        negedge_apply_and_model("overwrite_x31", 5'd31, 5'd1,  5'd31, 1'b1, 1'b0, 32'hFEEDC0DE);
        negedge_apply_and_model("overwrite_x16", 5'd16, 5'd31, 5'd16, 1'b1, 1'b0, 32'h02468ACE);

        // Read ports are combinational and independent; changing addresses alone changes outputs with no clock.
        drive_and_check_comb("comb_addr_change_1", 5'd1, 5'd31, 5'd0, 1'b0, 1'b0, 32'h0);
        drive_and_check_comb("comb_addr_change_2", 5'd16, 5'd0,  5'd0, 1'b0, 1'b0, 32'h0);
        drive_and_check_comb("comb_addr_change_3", 5'd2,  5'd3,  5'd0, 1'b0, 1'b0, 32'h0);
        drive_and_check_comb("comb_addr_change_4", 5'd0,  5'd16, 5'd0, 1'b0, 1'b0, 32'h0);

        // Final synchronous reset clears x1..x31 again.
        negedge_apply_and_model("final_reset", 5'd1, 5'd31, 5'd7, 1'b1, 1'b1, 32'hABCDEF01);
        for (i = 0; i < 32; i = i + 1) begin
            tmp_addr = i[4:0];
            drive_and_check_comb("final_zero_check", tmp_addr, (5'd31 - tmp_addr), 5'd0, 1'b0, 1'b0, 32'h0);
        end

        $display("A1_CHECKS passed=%0d failed=%0d total=%0d", passed, failed, total);
        if ((failed == 0) && (total > 0))
            $display("PASS");
        else
            $display("FAIL");
        $finish;
    end

endmodule
