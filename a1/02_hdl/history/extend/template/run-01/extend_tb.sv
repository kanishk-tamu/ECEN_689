`timescale 1ns/1ps

module extend_tb;

  // DUT interface
  logic [31:7] InstrD;
  logic [2:0]  ImmSrcD;
  logic [31:0] ImmExtD;

  // Scoreboard counters
  integer passed;
  integer failed;
  integer total;
  integer fail_prints;

  // DUT instantiation using named ports
  extend dut (
    .InstrD (InstrD),
    .ImmSrcD(ImmSrcD),
    .ImmExtD(ImmExtD)
  );

  // Watchdog to prevent hangs
  initial begin
    #10000;
    $display("FAIL");
    $finish;
  end

  // Expected-value function derived only from the specification.
  function automatic logic [31:0] exp_imm(
    input logic [31:7] instr,
    input logic [2:0]  src
  );
    begin
      case (src)
        3'b000: exp_imm = {{20{instr[31]}}, instr[31:20]};                            // I-type
        3'b001: exp_imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};              // S-type
        3'b010: exp_imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; // B-type
        3'b011: exp_imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; // J-type
        3'b100: exp_imm = {instr[31:12], 12'b0};                                      // U-type
        default: exp_imm = 32'hxxxxxxxx; // unused encodings unspecified; not checked
      endcase
    end
  endfunction

  // Helpers to build fragmented instruction fields for directed cases.
  function automatic logic [31:7] make_i(input logic [11:0] imm);
    logic [31:7] t;
    begin
      t = '0;
      t[31:20] = imm;
      make_i = t;
    end
  endfunction

  function automatic logic [31:7] make_s(input logic [11:0] imm);
    logic [31:7] t;
    begin
      t = '0;
      t[31:25] = imm[11:5];
      t[11:7]  = imm[4:0];
      make_s = t;
    end
  endfunction

  function automatic logic [31:7] make_b(input logic signed [12:0] imm);
    logic [31:7] t;
    begin
      t = '0;
      t[31]    = imm[12];
      t[7]     = imm[11];
      t[30:25] = imm[10:5];
      t[11:8]  = imm[4:1];
      make_b = t;
    end
  endfunction

  function automatic logic [31:7] make_j(input logic signed [20:0] imm);
    logic [31:7] t;
    begin
      t = '0;
      t[31]    = imm[20];
      t[19:12] = imm[19:12];
      t[20]    = imm[11];
      t[30:21] = imm[10:1];
      make_j = t;
    end
  endfunction

  function automatic logic [31:7] make_u(input logic [19:0] imm);
    logic [31:7] t;
    begin
      t = '0;
      t[31:12] = imm;
      make_u = t;
    end
  endfunction

  task automatic check_case(
    input string       label,
    input logic [31:7] instr,
    input logic [2:0]  src
  );
    logic [31:0] expected;
    begin
      InstrD  = instr;
      ImmSrcD = src;
      #1; // allow combinational settling

      expected = exp_imm(instr, src);

      // Only defined behavior is checked; illegal ImmSrcD values are intentionally skipped.
      if (src <= 3'b100) begin
        total = total + 1;
        if (ImmExtD === expected) begin
          passed = passed + 1;
        end else begin
          failed = failed + 1;
          if (fail_prints < 8) begin
            $display("FAIL label=%s InstrD=0x%07h ImmSrcD=0x%0h actual=0x%08h expected=0x%08h",
                     label, instr, src, ImmExtD, expected);
            fail_prints = fail_prints + 1;
          end
        end
      end
    end
  endtask

  integer i;
  integer seed;
  logic [31:0] rnd;

  initial begin
    passed = 0;
    failed = 0;
    total = 0;
    fail_prints = 0;
    seed = 32'h6890A1E1;

    InstrD = '0;
    ImmSrcD = '0;
    #1;

    // Coverage intent:
    // - Every defined ImmSrcD format: I/S/B/J/U
    // - Specification sample examples
    // - Zero, positive, negative, all ones, sign boundaries
    // - Fragmented immediate reconstruction for S/B/J
    // - Alignment bit insertion for B/J (bit 0 forced zero)
    // - Random deterministic vectors for broader field coverage
    // - Illegal encodings 101/110/111 are out of scope and not checked

    // I-type sample and corners
    check_case("I_sample_minus1", make_i(12'hFFF), 3'b000);   // sample -1
    check_case("I_zero",          make_i(12'h000), 3'b000);
    check_case("I_plus1",         make_i(12'h001), 3'b000);
    check_case("I_maxpos",        make_i(12'h7FF), 3'b000);
    check_case("I_minneg",        make_i(12'h800), 3'b000);
    check_case("I_allones",       make_i(12'hFFF), 3'b000);
    check_case("I_pattern",       make_i(12'hA5A), 3'b000);

    // S-type corners
    check_case("S_zero",          make_s(12'h000), 3'b001);
    check_case("S_plus1",         make_s(12'h001), 3'b001);
    check_case("S_maxpos",        make_s(12'h7FF), 3'b001);
    check_case("S_minneg",        make_s(12'h800), 3'b001);
    check_case("S_allones",       make_s(12'hFFF), 3'b001);
    check_case("S_fragmented",    make_s(12'h35A), 3'b001);

    // B-type sample examples and boundaries; all legal values have imm[0]=0
    check_case("B_sample_plus8",  make_b(13'sd8),   3'b010);  // sample +8
    check_case("B_sample_minus4", make_b(-13'sd4),  3'b010);  // sample -4
    check_case("B_zero",          make_b(13'sd0),   3'b010);
    check_case("B_plus2",         make_b(13'sd2),   3'b010);
    check_case("B_maxpos",        make_b(13'sd4094),3'b010);
    check_case("B_minneg",        make_b(-13'sd4096),3'b010);
    check_case("B_minus2",        make_b(-13'sd2),  3'b010);
    check_case("B_fragmented",    make_b(13'sd2730),3'b010);  // even, exercises split fields

    // J-type corners and fragmented reconstruction; legal values have imm[0]=0
    check_case("J_zero",          make_j(21'sd0),        3'b011);
    check_case("J_plus2",         make_j(21'sd2),        3'b011);
    check_case("J_maxpos",        make_j(21'sd1048574),  3'b011);
    check_case("J_minneg",        make_j(-21'sd1048576), 3'b011);
    check_case("J_minus2",        make_j(-21'sd2),       3'b011);
    check_case("J_fragmented",    make_j(21'sd349526),   3'b011);

    // U-type sample and corners
    check_case("U_sample",        make_u(20'hABCDE), 3'b100); // sample
    check_case("U_zero",          make_u(20'h00000), 3'b100);
    check_case("U_onehot",        make_u(20'h00001), 3'b100);
    check_case("U_maxposish",     make_u(20'h7FFFF), 3'b100);
    check_case("U_signbit",       make_u(20'h80000), 3'b100);
    check_case("U_allones",       make_u(20'hFFFFF), 3'b100);
    check_case("U_pattern",       make_u(20'h54321), 3'b100);

    // Deterministic pseudo-random directed coverage across all defined classes.
    for (i = 0; i < 20; i = i + 1) begin
      rnd = $random(seed);
      check_case("I_rand", make_i(rnd[11:0]), 3'b000);

      rnd = $random(seed);
      check_case("S_rand", make_s(rnd[11:0]), 3'b001);

      rnd = $random(seed);
      rnd[0] = 1'b0; // enforce legal alignment for branch immediate values
      check_case("B_rand", make_b(rnd[12:0]), 3'b010);

      rnd = $random(seed);
      rnd[0] = 1'b0; // enforce legal alignment for jump immediate values
      check_case("J_rand", make_j(rnd[20:0]), 3'b011);

      rnd = $random(seed);
      check_case("U_rand", make_u(rnd[19:0]), 3'b100);
    end

    $display("A1_CHECKS passed=%0d failed=%0d total=%0d", passed, failed, total);
    if ((failed == 0) && (total > 0))
      $display("PASS");
    else
      $display("FAIL");
    $finish;
  end

endmodule
