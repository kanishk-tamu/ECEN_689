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

  // Instantiate DUT using named ports
  extend dut (
    .InstrD (InstrD),
    .ImmSrcD(ImmSrcD),
    .ImmExtD(ImmExtD)
  );

  // Reference model derived only from the specification.
  function automatic logic [31:0] expected_imm(
    input logic [31:7] instr,
    input logic [2:0]  src
  );
    begin
      case (src)
        3'b000: expected_imm = {{20{instr[31]}}, instr[31:20]};                          // I-type
        3'b001: expected_imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};            // S-type
        3'b010: expected_imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; // B-type
        3'b011: expected_imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; // J-type
        3'b100: expected_imm = {instr[31:12], 12'b0};                                    // U-type
        default: expected_imm = 32'hxxxxxxxx; // unspecified / not graded
      endcase
    end
  endfunction

  task automatic check_case(
    input string        label,
    input logic [31:7]  instr,
    input logic [2:0]   src
  );
    logic [31:0] exp;
    begin
      InstrD  = instr;
      ImmSrcD = src;
      #1; // allow combinational settling

      exp = expected_imm(instr, src);

      total = total + 1;
      if (ImmExtD === exp) begin
        passed = passed + 1;
      end
      else begin
        failed = failed + 1;
        if (fail_prints < 8) begin
          $display("FAIL label=%s InstrD=0x%h ImmSrcD=0x%0h actual=0x%h expected=0x%h",
                   label, instr, src, ImmExtD, exp);
          fail_prints = fail_prints + 1;
        end
      end
    end
  endtask

  // Helpers to build fragmented immediates into InstrD[31:7].
  function automatic logic [31:7] make_i(input logic [11:0] imm12);
    logic [31:7] instr;
    begin
      instr = '0;
      instr[31:20] = imm12;
      make_i = instr;
    end
  endfunction

  function automatic logic [31:7] make_s(input logic [11:0] imm12);
    logic [31:7] instr;
    begin
      instr = '0;
      instr[31:25] = imm12[11:5];
      instr[11:7]  = imm12[4:0];
      make_s = instr;
    end
  endfunction

  function automatic logic [31:7] make_b(input logic [12:0] imm13);
    logic [31:7] instr;
    begin
      instr = '0;
      instr[31]    = imm13[12];
      instr[7]     = imm13[11];
      instr[30:25] = imm13[10:5];
      instr[11:8]  = imm13[4:1];
      make_b = instr;
    end
  endfunction

  function automatic logic [31:7] make_j(input logic [20:0] imm21);
    logic [31:7] instr;
    begin
      instr = '0;
      instr[31]    = imm21[20];
      instr[19:12] = imm21[19:12];
      instr[20]    = imm21[11];
      instr[30:21] = imm21[10:1];
      make_j = instr;
    end
  endfunction

  function automatic logic [31:7] make_u(input logic [19:0] imm20);
    logic [31:7] instr;
    begin
      instr = '0;
      instr[31:12] = imm20;
      make_u = instr;
    end
  endfunction

  // Simple deterministic PRNG with explicit seed.
  function automatic logic [31:0] prng_next(input logic [31:0] cur);
    begin
      prng_next = cur * 32'h0019660D + 32'h3C6EF35F;
    end
  endfunction

  initial begin : test_main
    integer i;
    logic [31:0] seed;
    logic [11:0] imm12;
    logic [12:0] imm13;
    logic [20:0] imm21;
    logic [19:0] imm20;
    logic [31:7] instr_tmp;

    passed = 0;
    failed = 0;
    total = 0;
    fail_prints = 0;

    InstrD  = '0;
    ImmSrcD = 3'b000;

    // Coverage intent:
    // - Exercise every defined ImmSrcD format: I/S/B/J/U.
    // - Include spec sample examples.
    // - Include zero, positive, negative, all-ones, and signed boundary values.
    // - Explicitly test fragmented field placement for S/B/J.
    // - Ensure B/J implicit bit0 = 0 through odd/even source patterns.
    // - Avoid checking undefined ImmSrcD encodings 101/110/111.

    // Sample examples from spec
    check_case("sample_I_neg1", make_i(12'hFFF), 3'b000);
    check_case("sample_U_ABCDE", make_u(20'hABCDE), 3'b100);
    check_case("sample_B_plus8", make_b(13'd8), 3'b010);
    check_case("sample_B_minus4", make_b(13'h1FFC), 3'b010);

    // I-type: zero, +1, max positive, min negative, -1, mixed patterns
    check_case("I_zero",      make_i(12'h000), 3'b000);
    check_case("I_plus1",     make_i(12'h001), 3'b000);
    check_case("I_maxpos",    make_i(12'h7FF), 3'b000);
    check_case("I_minneg",    make_i(12'h800), 3'b000);
    check_case("I_neg1",      make_i(12'hFFF), 3'b000);
    check_case("I_patternA",  make_i(12'hA55), 3'b000);
    check_case("I_pattern5",  make_i(12'h5AA), 3'b000);

    // S-type: same signed boundaries plus split-field coverage
    check_case("S_zero",      make_s(12'h000), 3'b001);
    check_case("S_plus1",     make_s(12'h001), 3'b001);
    check_case("S_maxpos",    make_s(12'h7FF), 3'b001);
    check_case("S_minneg",    make_s(12'h800), 3'b001);
    check_case("S_neg1",      make_s(12'hFFF), 3'b001);
    check_case("S_patternA",  make_s(12'hA55), 3'b001);
    check_case("S_pattern5",  make_s(12'h5AA), 3'b001);

    // B-type: implicit low bit zero, fragmented bit11 from InstrD[7], sign extension, boundaries
    check_case("B_zero",          make_b(13'd0),      3'b010);
    check_case("B_plus2",         make_b(13'd2),      3'b010);
    check_case("B_plus8",         make_b(13'd8),      3'b010);
    check_case("B_maxpos",        make_b(13'd4094),   3'b010);
    check_case("B_minneg",        make_b(13'h1000),   3'b010); // -4096
    check_case("B_neg2",          make_b(13'h1FFE),   3'b010); // -2
    check_case("B_neg4",          make_b(13'h1FFC),   3'b010); // -4
    check_case("B_neg_allones",   make_b(13'h1FFF),   3'b010); // encoded all ones => -1<<with bit0 included in encoded value model
    check_case("B_bit11_only",    make_b(13'h0800),   3'b010); // tests InstrD[7] contribution
    check_case("B_fragment_mix",  make_b(13'h0554),   3'b010);

    // J-type: implicit low bit zero, fragmented bit11 from InstrD[20], sign extension, boundaries
    check_case("J_zero",          make_j(21'd0),        3'b011);
    check_case("J_plus2",         make_j(21'd2),        3'b011);
    check_case("J_plus2048",      make_j(21'd2048),     3'b011); // bit11 contribution
    check_case("J_maxpos",        make_j(21'd1048574),  3'b011);
    check_case("J_minneg",        make_j(21'h100000),   3'b011); // -1048576
    check_case("J_neg2",          make_j(21'h1FFFFE),   3'b011);
    check_case("J_neg_allones",   make_j(21'h1FFFFF),   3'b011);
    check_case("J_fragment_mix",  make_j(21'h155554),   3'b011);

    // U-type: direct upper 20 bits, lower 12 cleared
    check_case("U_zero",      make_u(20'h00000), 3'b100);
    check_case("U_onebit",    make_u(20'h00001), 3'b100);
    check_case("U_allones",   make_u(20'hFFFFF), 3'b100);
    check_case("U_signbit",   make_u(20'h80000), 3'b100);
    check_case("U_ABCDE",     make_u(20'hABCDE), 3'b100);
    check_case("U_55555",     make_u(20'h55555), 3'b100);
    check_case("U_AAAAA",     make_u(20'hAAAAA), 3'b100);

    // Deterministic pseudo-random regression across all defined formats.
    seed = 32'h1234ABCD;
    for (i = 0; i < 20; i = i + 1) begin
      seed = prng_next(seed);
      imm12 = seed[11:0];
      check_case("I_rand", make_i(imm12), 3'b000);

      seed = prng_next(seed);
      imm12 = seed[11:0];
      check_case("S_rand", make_s(imm12), 3'b001);

      seed = prng_next(seed);
      imm13 = {seed[12:1], 1'b0}; // keep aligned so representable branch immediate is emphasized
      check_case("B_rand", make_b(imm13), 3'b010);

      seed = prng_next(seed);
      imm21 = {seed[20:1], 1'b0}; // keep aligned for J immediate
      check_case("J_rand", make_j(imm21), 3'b011);

      seed = prng_next(seed);
      imm20 = seed[19:0];
      check_case("U_rand", make_u(imm20), 3'b100);
    end

    // Additional direct mixed-instruction stress with arbitrary unused bits in non-selected fields.
    instr_tmp = 25'h1ABCDE1;
    check_case("direct_I_arbitrary", instr_tmp, 3'b000);
    check_case("direct_S_arbitrary", instr_tmp, 3'b001);
    check_case("direct_B_arbitrary", instr_tmp, 3'b010);
    check_case("direct_J_arbitrary", instr_tmp, 3'b011);
    check_case("direct_U_arbitrary", instr_tmp, 3'b100);

    $display("A1_CHECKS passed=%0d failed=%0d total=%0d", passed, failed, total);
    if ((failed == 0) && (total > 0))
      $display("PASS");
    else
      $display("FAIL");
    $finish;
  end

  initial begin : watchdog
    #10000;
    $display("FAIL");
    $finish;
  end

endmodule
